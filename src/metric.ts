import { UUID, randomUUID } from 'crypto';
import { MetricSource } from './config/MetricSource';
import { Gauge, register } from 'prom-client';

export class Metric {
  id: UUID = randomUUID();
  underlying: Gauge;
  lastUpdated: Gauge;

  private labels: Record<string, any> = {};

  constructor(
    public source: MetricSource,
    public args: string[],
    public chain: string,
    public chainLabel: string,
    public type: string,
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

    this.labels = this.source.functionAbi.inputs.reduce((acc, input, idx) => {
      acc[input.name] = args[idx];
      return acc;
    }, {});
    this.labels.chain = chainLabel;

    this.underlying = this.getOrCreateGauge(
      this.name,
      `Return value of ${source.raw}`,
    );
    this.lastUpdated = this.getOrCreateGauge(
      this.lastUpdatedMetricName,
      `Last updated timestamp of ${source.raw}`,
    );
  }

  get name(): string {
    return `${this.source.functionAbi.name}`;
  }

  get nameWithLabels(): string {
    return `${this.name}${JSON.stringify(this.labels)}`;
  }

  get lastUpdatedMetricName(): string {
    return `${this.name}_lastUpdated`;
  }

  update(value: number) {
    this.underlying.labels(this.labels).set(value);
    this.lastUpdated.labels(this.labels).setToCurrentTime();
  }

  getOrCreateGauge(metricName: string, helperText: string): Gauge<string> {
    let metric = register.getSingleMetric(metricName);
    if (!metric) {
      metric = new Gauge({
        name: metricName,
        help: helperText,
        labelNames: ['chain'].concat(
          this.source.functionAbi.inputs.map((input) => input.name),
        ),
      });
    }
    return metric as Gauge<string>;
  }

  parse(output: any): number {
    if (this.source.functionAbi.outputs.length === 1) {
      const parsed = output as bigint;
      if (parsed > Number.MAX_SAFE_INTEGER) {
        throw new Error(`Value ${parsed} is too large to be a safe integer`);
      }
      return Number(parsed);
    } else {
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
    }
  }
}
