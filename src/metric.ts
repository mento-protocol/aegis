import { UUID, randomUUID } from 'crypto';
import { MetricSource } from './config/MetricSource';
import { Gauge, register } from 'prom-client';

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

    const metric = register.getSingleMetric(this.name);
    if (metric) {
      this.underlying = metric as Gauge<string>;
    } else {
      this.underlying = new Gauge({
        name: this.name,
        help: `Return value of ${source.raw}`,
        labelNames: ['chain'].concat(
          source.functionAbi.inputs.map((input) => input.name),
        ),
      });
    }
  }

  get name(): string {
    return `${this.source.functionAbi.name}`;
  }

  get nameWithLabels(): string {
    return `${this.name}${JSON.stringify(this.labels)}`;
  }

  update(value: number) {
    this.underlying.labels(this.labels).set(value);
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
