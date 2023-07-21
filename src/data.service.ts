import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Metric } from './config';
import { ReaderService } from './reader.service';

@Injectable()
export class DataService {
  private readonly logger = new Logger(DataService.name);
  metrics: Record<string, Metric>;
  data: Record<string, any> = {};

  constructor(
    private configService: ConfigService,
    private readerService: ReaderService,
  ) {
    this.metrics = configService
      .get<Metric[]>('metrics')
      .reduce((acc, metric) => {
        acc[metric.name] = metric;
        return acc;
      }, {});
  }
  async onModuleInit(): Promise<void> {
    await this.refreshAll();
  }

  get(name: string): any {
    if (!!this.metrics[name]) {
      throw new Error(`Metric ${name} does not exist`);
    }

    return this.data[name];
  }

  refresh = async (name: string) => {
    this.logger.debug(`Refreshing metric ${name}`);
    this.data[name] = await this.readerService.read(this.metrics[name]);
    this.logger.debug(`Refreshed metric ${name}: ${this.data[name]}`);
  };

  async refreshAll() {
    return Promise.all(Object.keys(this.metrics).map(this.refresh));
  }
}
