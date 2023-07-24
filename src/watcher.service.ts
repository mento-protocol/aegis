import { Injectable, Logger } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { MetricTemplate } from './config';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from './metrics.service';
import { CronJob } from 'cron';

@Injectable()
export class WatcherService {
  private readonly logger = new Logger(WatcherService.name);

  constructor(
    private schedulerRegistry: SchedulerRegistry,
    private metricsService: MetricsService,
    private configService: ConfigService,
  ) {
    const metrics = this.configService.get<MetricTemplate[]>('metrics');
    metrics.forEach((metric) => {
      const job = new CronJob(metric.schedule, () =>
        this.metricsService.refreshTemplate(metric.id),
      );
      this.logger.debug(
        `Adding cron job: ${metric.source.raw}: ${metric.schedule}`,
      );
      this.schedulerRegistry.addCronJob(metric.source.raw, job);
      job.start();
    });
  }
}
