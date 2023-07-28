import { readFileSync } from 'fs';
import * as yaml from 'js-yaml';
import { join } from 'path';
import z from 'zod';
import { randomUUID } from 'crypto';

import { MetricSource } from './MetricSource';

const YAML_CONFIG_FILENAME =
  process.env.NODE_ENV == 'production' ? 'config.yaml' : 'config.local.yaml';

export const ChainConfig = z
  .object({
    id: z.string(),
    label: z.string(),
    httpRpcUrl: z.string(),
    contracts: z.record(z.string()),
    vars: z.record(z.string()),
  })
  .brand('ChainConfig');
export type ChainConfig = z.infer<typeof ChainConfig>;

const MetricTemplate = z
  .object({
    source: MetricSource,
    schedule: z.string(),
    type: z.enum([
      // Todo do we need others?
      'gauge',
    ] as const),
    chains: z.literal('all').or(z.array(z.string())),
    variants: z.array(z.array(z.string())).refine((v) => v.length > 0, {
      message: 'Must have at least one variant',
    }),
  })
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

  const allChains = config.chains.map((chain) => chain.id);

  config.metrics.forEach((metric) => {
    const { contract } = metric.source;
    const chains = metric.chains === 'all' ? allChains : metric.chains;
    chains.forEach((chainId) => {
      const chain = config.chains.find((chain) => chain.id === chainId);
      if (chain.contracts[contract] === undefined) {
        throw new Error(
          `Contract ${contract} isn't declared in network ${chain.id}`,
        );
      }
    });
  });

  return config;
};
