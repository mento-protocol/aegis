import { readFileSync } from 'fs';
import * as yaml from 'js-yaml';
import { join } from 'path';
import z from 'zod';
import { AbiFunction } from 'abitype';

const YAML_CONFIG_FILENAME =
  process.env.NODE_ENV == 'production'
    ? '../config.yaml'
    : '../config.local.yaml';

const AddressBook = z.record(z.string()).brand<'AddressBook'>();
export type AddressBook = z.infer<typeof AddressBook>;

const AbiFunction = z.object({
  type: z.literal('function'),
  stateMutability: z.literal('view'),
  name: z.string(),
  inputs: z.array(z.object({ name: z.string(), type: z.string() })),
  outputs: z.array(z.object({ name: z.string(), type: z.string() })),
});

const Contract = z
  .object({
    name: z.string(),
    methods: z.array(
      z.string().transform((signature, ctx): AbiFunction => {
        const match = /^(\w+)\((.*)\)\((.*)\)$/.exec(signature);
        if (!match) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: `Invalid signature ${signature}`,
          });
          return z.NEVER;
        }

        const [functionName, inputs, outputs] = match.slice(1);
        return {
          type: 'function',
          name: functionName,
          stateMutability: 'view',
          inputs: inputs.split(',').map((input, index) => {
            const [nameOrType, type] = input.split(':');
            if (type) {
              return { name: nameOrType, type };
            }
            return { name: `in${index}`, type: nameOrType };
          }),
          outputs: outputs.split(',').map((output, index) => {
            const [nameOrType, type] = output.split(':');
            if (type) {
              return { name: nameOrType, type };
            }
            return { name: `out${index}`, type: nameOrType };
          }),
        };
      }),
    ),
  })
  .brand('Contract');
export type Contract = z.infer<typeof Contract>;

const Contracts = z.array(Contract);

const Metric = z
  .object({
    name: z.string(),
    type: z.string(),
    source: z.string(),
    args: z.array(z.string().or(z.number())),
    schedule: z.string(),
  })
  .brand<'Metric'>();
export type Metric = z.infer<typeof Metric>;

const Chain = z
  .object({
    id: z.literal('celo').or(z.literal('celoAlfajores')),
    httpRpcUrl: z.string(),
  })
  .brand<'Chain'>();
export type Chain = z.infer<typeof Chain>;

const Config = z
  .object({
    chain: Chain,
    addresses: AddressBook,
    contracts: Contracts,
    metrics: z.array(Metric),
  })
  .brand<'Config'>();
export type Config = z.infer<typeof Config>;

export default () => {
  const rawConfig = yaml.load(
    readFileSync(join(__dirname, YAML_CONFIG_FILENAME), 'utf8'),
  ) as Record<string, any>;

  const config = Config.parse(rawConfig);

  config.contracts.forEach((contract) => {
    if (!(contract.name in config.addresses)) {
      throw new Error(
        `Contract ${contract.name} does not have an address in the address book`,
      );
    }
  });

  config.metrics.forEach((metric) => {
    const [contract, method] = metric.source.split('.');
    if (!config.contracts.find((c) => c.name === contract)) {
      throw new Error(
        `Metric ${metric.name} references contract ${contract} which is not in the contracts list`,
      );
    }
    if (
      config.contracts
        .find((c) => c.name === contract)
        .methods.find((m) => m.name === method) === undefined
    ) {
      throw new Error(
        `Metric ${metric.name} references method ${method} which is not in the methods list for contract ${contract}`,
      );
    }
  });

  return config;
};
