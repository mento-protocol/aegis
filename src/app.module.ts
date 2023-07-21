import { Module } from '@nestjs/common';
import { WatcherService } from './watcher.service';
import { ScheduleModule } from '@nestjs/schedule';
import { ConfigModule } from '@nestjs/config';

import configuration from './config';
import { ReaderService } from './reader.service';
import { DataService } from './data.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule.forRoot({
      load: [configuration],
    }),
  ],
  providers: [WatcherService, DataService, ReaderService],
})
export class AppModule { }
