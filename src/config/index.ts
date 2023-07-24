import { readFileSync } from 'fs';
import * as yaml from 'js-yaml';
import { join } from 'path';
import z from 'zod';
import { isValidCron } from 'cron-validator';
import { randomUUID } from 'crypto';

import { MetricSource } from './MetricSource';

const YAML_CONFIG_FILENAME =
  process.env.NODE_ENV == 'production' ? 'config.yaml' : 'config.local.yaml';

export const ChainConfig = z
  .object({
    id: z.string(),
    label: z.string(),
    httpRpcUrl: z.string(),
    addresses: z.record(z.string()),
  })
  .brand('ChainConfig');
export type ChainConfig = z.infer<typeof ChainConfig>;

const MetricTemplate = z
  .object({
    source: MetricSource,
    schedule: z.string(), //.refine((s) => isValidCron(s), {
    //  message: 'Invalid cron expression',
    // }),
    type: z.enum([
      // Todo do we need others?
      'gauge',
    ] as const),
    chains: z.literal('all').or(z.array(z.string())),
    variants: z.record(z.array(z.string())).optional(),
    args: z.array(z.string()).optional(),
  })
  .refine(
    (v) => {
      return !(
        (v['variants'] == undefined && v['args'] == undefined) ||
        (v['variants'] !== undefined && v['args'] !== undefined)
      );
    },
    {
      message: 'Metric must contain one of `variants` or `args`',
    },
  )
  .transform((v) => {
    return {
      ...v,
      id: randomUUID(),
    };
  })
  .brand<'MetricTemplate'>();
export type MetricTemplate = z.infer<typeof MetricTemplate>;

const Config = z
  .object({
    chains: z.array(ChainConfig),
    metrics: z.array(MetricTemplate),
  })
  .brand<'Config'>();
export type Config = z.infer<typeof Config>;

export default () => {
  const rawConfig = yaml.load(
    readFileSync(join(__dirname, '../../', YAML_CONFIG_FILENAME), 'utf8'),
  ) as Record<string, any>;

  const config = Config.parse(rawConfig);

  config.metrics.forEach((metric) => {
    const { contract } = metric.source;
    config.chains.forEach((chain) => {
      if (chain.addresses[contract] === undefined) {
        throw new Error(
          `Contract ${contract} doesn't have an address declaration for network ${chain.id}`,
        );
      }
    });
  });

  return config;
};
