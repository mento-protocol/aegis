import { ConfigService } from '@nestjs/config';
import { UUID, randomUUID } from 'crypto';
import { Gauge, register } from 'prom-client';
import type { ChainConfig } from './config';
import { MetricSource } from './config/MetricSource';

export class Metric {
  id: UUID = randomUUID();
  underlying: Gauge;

  private labels: Record<string, any> = {};

  constructor(
    public source: MetricSource,
    public args: string[],
    public chain: string,
    public chainLabel: string,
    public type: string,
    configService: ConfigService,
  ) {
    /**
     * TODO: Support multiple return values
     * This can create additional gauges with suffixes from named return values.
     * i.e. say we have the function HelperContract.getMetrics()(uint256 m1, uint256 m2)
     * This could be expanded to getMetrics_m1 and getMetrics_m2 from a single call.
     */

    if (source.functionAbi.outputs.length > 2) {
      throw new Error('Only functions with 1 or 2 values are supported');
    }

    const chainConfig = configService
      .get('chains')
      .find((conf: ChainConfig) => conf.label === chainLabel);
    this.labels = this.source.functionAbi.inputs.reduce((acc, input, idx) => {
      acc[input.name] = args[idx];
      acc[`${input.name}Value`] = chainConfig.vars[args[idx]];
      return acc;
    }, {});
    this.labels.chain = chainLabel;

    const metric = register.getSingleMetric(this.name);
    if (metric) {
      this.underlying = metric as Gauge<string>;
    } else {
      this.underlying = new Gauge({
        name: this.name,
        help: `Return value of ${source.raw}`,
        labelNames: ['chain'].concat(
          source.functionAbi.inputs.map((input) => input.name),
          source.functionAbi.inputs.map((input) => `${input.name}Value`),
        ),
      });
    }
  }

  get name(): string {
    // NOTE: We can't use a dot in prometheus metric names so we use an underscore instead
    return `${this.source.contract}_${this.source.functionAbi.name}`;
  }

  get nameWithLabels(): string {
    return `${this.name}${JSON.stringify(this.labels)}`;
  }

  update(value: number) {
    this.underlying.labels(this.labels).set(value);
  }

  parse(output: any, contractName: string, functionName: string): number {
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
      case 'axlEUROC.balanceOf':
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
        const [bool] = output as [boolean, bigint];
        return bool ? 1 : 0;

      case 'OracleHelper.deviation':
        const [numerator, denominator] = output as [bigint, bigint];
        if (denominator === BigInt(0)) {
          return 0;
        }
        const precision = 1e6;
        const value = (numerator * BigInt(precision)) / denominator;
        if (value > Number.MAX_SAFE_INTEGER) {
          throw new Error(
            `Value ${value} is too large to be converted to number`,
          );
        }
        return Number(value) / precision;
      default:
        throw new Error(
          `Unknown metric '${metricName}'. Make sure to add a case for it in the Metric.parse() method.`,
        );
    }
  }
}
