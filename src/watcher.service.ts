import { Injectable, Logger } from '@nestjs/common';
import { Cron, SchedulerRegistry } from '@nestjs/schedule';
import { Metric } from './config';
import { ConfigService } from '@nestjs/config';
import { DataService } from './data.service';
import { CronJob } from 'cron';

@Injectable()
export class WatcherService {
  private readonly logger = new Logger(WatcherService.name);

  constructor(
    private schedulerRegistry: SchedulerRegistry,
    private dataService: DataService,
    private configService: ConfigService,
  ) {
    const metrics = this.configService.get<Metric[]>('metrics');
    metrics.forEach((metric) => {
      const job = new CronJob(metric.schedule, () =>
        this.dataService.refresh(metric.name),
      );
      this.logger.debug(`Adding cron job: ${metric.name}: ${metric.schedule}`);
      this.schedulerRegistry.addCronJob(metric.name, job);
      job.start();
    });
  }
}
