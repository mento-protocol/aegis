import { ConfigService } from '@nestjs/config';
import { UUID, randomUUID } from 'crypto';
import { Gauge, register } from 'prom-client';
import type { ChainConfig } from './config';
import { MetricSource } from './config/MetricSource';

/**
 * Solidity type bounds for validation
 */
const SOLIDITY_TYPE_BOUNDS = {
  uint8: { min: 0n, max: 255n },
  uint32: { min: 0n, max: 4294967295n },
  int48: { min: -140737488355328n, max: 140737488355327n },
} as const;

/**
 * Metric class manages Prometheus gauges for on-chain contract queries.
 *
 * Multi-Gauge Support:
 * Solidity functions can return multiple values (e.g., a struct with several fields).
 * Instead of combining these into a single metric, we create separate Prometheus gauges
 * for each return value, allowing independent tracking and querying of each field.
 *
 * For example, `Broker.tradingLimitsState()` returns 5 values: two timestamps and three
 * netflow values. Multi-gauge support creates 5 separate gauges, one for each field,
 * making it possible to query and alert on individual fields independently.
 *
 * Implementation:
 * - Single return value → one gauge with base metric name (e.g., `BreakerBox_getRateFeedTradingMode`)
 * - Multiple return values → one gauge per value with suffix based on ABI output name
 *   (e.g., `Broker_tradingLimitsState_netflow0`, `Broker_tradingLimitsState_netflow1`)
 * - The parse() method returns either a single number or array of numbers accordingly
 * - The update() method automatically distributes array values to corresponding gauges
 *
 * Example:
 *   Function: Broker.tradingLimitsState()(uint32 lastUpdated0, uint32 lastUpdated1, ...)
 *   Creates 5 separate gauges:
 *     - Broker_tradingLimitsState_lastUpdated0
 *     - Broker_tradingLimitsState_lastUpdated1
 *     - Broker_tradingLimitsState_netflow0
 *     - Broker_tradingLimitsState_netflow1
 *     - Broker_tradingLimitsState_netflowGlobal
 */
export class Metric {
  id: UUID = randomUUID();
  gauge: Gauge | Gauge[];

  private labels: Record<string, any> = {};

  /**
   * Validates that a bigint value is within the specified Solidity type range and converts to number.
   * @param val - The bigint value to validate
   * @param typeName - Name of the Solidity type (must be a key in SOLIDITY_TYPE_BOUNDS)
   * @returns The value as a JavaScript number
   */
  private validateSolidityType(
    val: bigint,
    typeName: keyof typeof SOLIDITY_TYPE_BOUNDS,
  ): number {
    const { min, max } = SOLIDITY_TYPE_BOUNDS[typeName];
    if (val < min || val > max) {
      throw new Error(
        `Value ${val} outside ${typeName} range [${min}, ${max}]`,
      );
    }
    const numVal = Number(val);
    if (numVal > Number.MAX_SAFE_INTEGER || numVal < Number.MIN_SAFE_INTEGER) {
      throw new Error(`value ${val} is outside safe integer range`);
    }
    return numVal;
  }

  constructor(
    public source: MetricSource,
    public args: string[],
    public chain: string,
    public chainLabel: string,
    public type: string,
    configService: ConfigService,
  ) {
    const chainConfig = configService
      .get('chains')
      .find((conf: ChainConfig) => conf.label === chainLabel);
    this.labels = this.source.functionAbi.inputs.reduce((acc, input, idx) => {
      acc[input.name] = args[idx];
      acc[`${input.name}Value`] = chainConfig.vars[args[idx]];
      return acc;
    }, {});
    this.labels.chain = chainLabel;

    // Support multiple return values by creating multiple gauges with suffixes
    if (source.functionAbi.outputs.length > 1) {
      this.gauge = source.functionAbi.outputs.map((output, idx) => {
        if (!output.name || output.name.trim() === '') {
          throw new Error(
            `Output at index ${idx} for function ${source.functionAbi.name} must have a name for multi-gauge metrics`,
          );
        }
        const gaugeName = `${this.name}_${output.name}`;
        const existingMetric = register.getSingleMetric(gaugeName);
        if (existingMetric) {
          return existingMetric as Gauge<string>;
        } else {
          return new Gauge({
            name: gaugeName,
            help: `Return value ${output.name} of ${source.raw}`,
            labelNames: ['chain'].concat(
              source.functionAbi.inputs.map((input) => input.name),
              source.functionAbi.inputs.map((input) => `${input.name}Value`),
            ),
          });
        }
      });
    } else {
      const metric = register.getSingleMetric(this.name);
      if (metric) {
        this.gauge = metric as Gauge<string>;
      } else {
        this.gauge = new Gauge({
          name: this.name,
          help: `Return value of ${source.raw}`,
          labelNames: ['chain'].concat(
            source.functionAbi.inputs.map((input) => input.name),
            source.functionAbi.inputs.map((input) => `${input.name}Value`),
          ),
        });
      }
    }
  }

  get name(): string {
    // NOTE: We can't use a dot in prometheus metric names so we use an underscore instead
    return `${this.source.contract}_${this.source.functionAbi.name}`;
  }

  get nameWithLabels(): string {
    return `${this.name}${JSON.stringify(this.labels)}`;
  }

  update(value: number | number[]) {
    if (Array.isArray(value)) {
      if (!Array.isArray(this.gauge)) {
        throw new Error('Cannot update single gauge with array of values');
      }
      if (value.length !== this.gauge.length) {
        throw new Error(
          `Value array length mismatch: expected ${this.gauge.length} values, got ${value.length}`,
        );
      }
      value.forEach((val, idx) => {
        (this.gauge as Gauge[])[idx].labels(this.labels).set(val);
      });
    } else {
      if (Array.isArray(this.gauge)) {
        throw new Error('Cannot update multiple gauges with single value');
      }
      this.gauge.labels(this.labels).set(value);
    }
  }

  parse(
    output: unknown,
    contractName: string,
    functionName: string,
  ): number | number[] {
    const metricName = `${contractName}.${functionName}`;
    switch (metricName) {
      case 'BreakerBox.getRateFeedTradingMode':
        const parsed = output as bigint;
        if (parsed > Number.MAX_SAFE_INTEGER) {
          throw new Error(`Value ${parsed} is too large to be a safe integer`);
        }
        return Number(parsed);

      case 'CELOToken.balanceOf':
        const celoDecimals = 1e18;
        const celoBalanceInWei = output as bigint;
        const celoBalanceInEther = celoBalanceInWei / BigInt(celoDecimals);
        if (celoBalanceInEther > Number.MAX_SAFE_INTEGER) {
          throw new Error(
            `Value ${celoBalanceInEther} is too large to be a safe integer`,
          );
        }
        return Number(celoBalanceInEther);

      case 'USDC.balanceOf':
      case 'USDT.balanceOf':
      case 'axlUSDC.balanceOf':
        const decimals = 1e6;
        const balance = output as bigint;
        const balanceInEther = balance / BigInt(decimals);
        if (balanceInEther > Number.MAX_SAFE_INTEGER) {
          throw new Error(
            `Value ${balanceInEther} is too large to be a safe integer`,
          );
        }
        return Number(balanceInEther);

      case 'SortedOracles.medianRate':
        // Returns (rate, denominator) from SortedOracles
        // rate is typically multiplied by denominator (usually 1e24)
        // We need to return rate / denominator to get the actual exchange rate
        const [rate, denominator] = output as [bigint, bigint];
        if (denominator === 0n) {
          throw new Error('medianRate denominator is zero');
        }
        // Calculate the actual rate as a decimal
        // For safety, we convert to number after division to maintain precision
        const actualRate = Number(rate) / Number(denominator);
        // Return rate and denominator separately for flexibility in Grafana
        return [actualRate, Number(denominator)];

      case 'SortedOracles.isOldestReportExpired':
        const [isExpired] = output as [boolean, bigint];
        // Returns array: [isExpired as number, 0 for oracle address]
        // Oracle address is not tracked (set to 0) to avoid number overflow issues
        // The second gauge exists but is not used in dashboards/alerts
        return [isExpired ? 1 : 0, 0];

      case 'Broker.tradingLimitsState':
        // The struct is returned as: (lastUpdated0, lastUpdated1, netflow0, netflow1, netflowGlobal)
        // All netflows are int48 values representing flow without decimals
        // Timestamps are uint32 Unix timestamps
        const [lastUpdated0, lastUpdated1, netflow0, netflow1, netflowGlobal] =
          output as [bigint, bigint, bigint, bigint, bigint];

        return [
          // uint32: 0 to 2^32 - 1
          this.validateSolidityType(lastUpdated0, 'uint32'),
          this.validateSolidityType(lastUpdated1, 'uint32'),
          // int48: -(2^47) to 2^47 - 1
          this.validateSolidityType(netflow0, 'int48'),
          this.validateSolidityType(netflow1, 'int48'),
          this.validateSolidityType(netflowGlobal, 'int48'),
        ];

      case 'Broker.tradingLimitsConfig':
        // The config struct is returned as: (timestep0, timestep1, limit0, limit1, limitGlobal, flags)
        // timestep0/timestep1 are uint32 time windows in seconds
        // limit0/limit1/limitGlobal are int48 threshold values
        // flags is uint8 bitfield (0 = disabled)
        const [timestep0, timestep1, limit0, limit1, limitGlobal, flags] =
          output as [bigint, bigint, bigint, bigint, bigint, bigint];

        return [
          // uint32: 0 to 2^32 - 1
          this.validateSolidityType(timestep0, 'uint32'),
          this.validateSolidityType(timestep1, 'uint32'),
          // int48: -(2^47) to 2^47 - 1
          this.validateSolidityType(limit0, 'int48'),
          this.validateSolidityType(limit1, 'int48'),
          this.validateSolidityType(limitGlobal, 'int48'),
          // uint8: 0 to 2^8 - 1
          this.validateSolidityType(flags, 'uint8'),
        ];

      case 'cUSD.totalSupply':
      case 'cEUR.totalSupply':
      case 'cREAL.totalSupply':
      case 'eXOF.totalSupply':
      case 'cKES.totalSupply':
      case 'PUSO.totalSupply':
      case 'cCOP.totalSupply':
      case 'cGHS.totalSupply':
      case 'cGBP.totalSupply':
      case 'cZAR.totalSupply':
      case 'cCAD.totalSupply':
      case 'cAUD.totalSupply':
      case 'cCHF.totalSupply':
      case 'cNGN.totalSupply':
      case 'cJPY.totalSupply':
        // All stable tokens have 18 decimals
        const decimals18 = 1e18;
        const totalSupply = output as bigint;
        const totalSupplyInEther = totalSupply / BigInt(decimals18);
        if (totalSupplyInEther > Number.MAX_SAFE_INTEGER) {
          throw new Error(
            `Value ${totalSupplyInEther} is too large to be a safe integer`,
          );
        }
        return Number(totalSupplyInEther);

      default:
        throw new Error(
          `Unknown metric '${metricName}'. Make sure to add a case for it in the Metric.parse() method.`,
        );
    }
  }
}
