import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ChainConfig, MetricTemplate } from './config';
import { QueryService } from './query.service';
import { UUID } from 'crypto';
import { Metric } from './metric';

@Injectable()
export class MetricsService {
  private readonly logger = new Logger(MetricsService.name);
  templates: Record<UUID, MetricTemplate> = {};
  metrics: Record<UUID, Metric[]> = {};
  chainIds: Array<string>;
  data: Record<string, any> = {};

  constructor(
    configService: ConfigService,
    private queryService: QueryService,
  ) {
    const chains = configService.get<ChainConfig[]>('chains');
    this.chainIds = chains.map((chain) => chain.id);
    const templates = configService.get<MetricTemplate[]>('metrics');
    templates.forEach((template) => {
      const variants = template.variants || { __default: template.args };
      this.metrics[template.id] = Object.entries(variants)
        .map(([variantName, args]) => {
          return (
            template.chains === 'all' ? this.chainIds : template.chains
          ).map((chain) => {
            return new Metric(
              template.source,
              args,
              chain,
              chains.find((c) => c.id == chain).label,
              template.type,
              variantName,
            );
          });
        })
        .flat();
      this.templates[template.id] = template;
    });
  }

  async onModuleInit(): Promise<void> {
    await this.refreshAll();
  }

  async refreshAll() {
    return Promise.all(Object.keys(this.metrics).map(this.refreshTemplate));
  }

  refreshTemplate = async (templateID: UUID) => {
    const template = this.templates[templateID];
    const metrics = this.metrics[templateID];
    this.logger.debug(
      `Refreshing ${metrics.length} metricts for ${template.source.raw}`,
    );
    const now = performance.now();
    await Promise.all(metrics.map(this.refreshMetric));
    const duration = (performance.now() - now).toFixed(2);
    this.logger.debug(
      `Refreshed ${metrics.length} metrics for ${template.source.raw} in ${duration}ms`,
    );
  };

  refreshMetric = async (metric: Metric) => {
    this.logger.debug(`Refreshing metrics ${metric.nameWithLabels}`);
    let value = await this.queryService.query(metric);
    if (value !== undefined) {
      // TODO: Add logic for scaling bignumbers
      value = Number(value);
      metric.update(value);
    }
    this.logger.debug(`${metric.nameWithLabels} = ${value}`);
  };
}
