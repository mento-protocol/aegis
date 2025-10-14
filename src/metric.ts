import { ConfigService } from '@nestjs/config';
import { UUID, randomUUID } from 'crypto';
import { Gauge, register } from 'prom-client';
import type { ChainConfig } from './config';
import { MetricSource } from './config/MetricSource';

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
   * Validates that a bigint value is within the specified range and converts to number.
   * @param val - The bigint value to validate
   * @param typeName - Name of the Solidity type for error messages
   * @param min - Minimum allowed value (inclusive)
   * @param max - Maximum allowed value (inclusive)
   * @returns The value as a JavaScript number
   */
  private validateContractType(
    val: bigint,
    typeName: string,
    min: bigint,
    max: bigint,
  ): number {
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
      this.gauge = source.functionAbi.outputs.map((output) => {
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

      case 'SortedOracles.isOldestReportExpired':
        const [isExpired, oracleAddress] = output as [boolean, bigint];
        // Returns array of two values for multi-gauge support:
        // 1. isExpired converted to number (0 or 1) - used for alerting
        // 2. oracleAddress as number - tracked but not currently used in dashboards
        return [isExpired ? 1 : 0, Number(oracleAddress)];

      case 'Broker.tradingLimitsState':
        // The struct is returned as: (lastUpdated0, lastUpdated1, netflow0, netflow1, netflowGlobal)
        // All netflows are int48 values representing flow without decimals
        // Timestamps are uint32 Unix timestamps
        const [lastUpdated0, lastUpdated1, netflow0, netflow1, netflowGlobal] =
          output as [bigint, bigint, bigint, bigint, bigint];

        return [
          // uint32: 0 to 2^32 - 1
          this.validateContractType(lastUpdated0, 'uint32', 0n, 4294967295n),
          this.validateContractType(lastUpdated1, 'uint32', 0n, 4294967295n),
          // int48: -(2^47) to 2^47 - 1
          this.validateContractType(
            netflow0,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
          this.validateContractType(
            netflow1,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
          this.validateContractType(
            netflowGlobal,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
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
          this.validateContractType(timestep0, 'uint32', 0n, 4294967295n),
          this.validateContractType(timestep1, 'uint32', 0n, 4294967295n),
          // int48: -(2^47) to 2^47 - 1
          this.validateContractType(
            limit0,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
          this.validateContractType(
            limit1,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
          this.validateContractType(
            limitGlobal,
            'int48',
            -140737488355328n,
            140737488355327n,
          ),
          // uint8: 0 to 2^8 - 1
          this.validateContractType(flags, 'uint8', 0n, 255n),
        ];

      default:
        throw new Error(
          `Unknown metric '${metricName}'. Make sure to add a case for it in the Metric.parse() method.`,
        );
    }
  }
}
