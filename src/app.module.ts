import { Module } from '@nestjs/common';
import { WatcherService } from './watcher.service';
import { ScheduleModule } from '@nestjs/schedule';
import { ConfigModule } from '@nestjs/config';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';

import configuration from './config';
import { QueryService } from './query.service';
import { MetricsService } from './metrics.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule.forRoot({
      load: [configuration],
    }),
    PrometheusModule.register(),
  ],
  providers: [WatcherService, MetricsService, QueryService],
})
export class AppModule { }
