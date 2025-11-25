import { AbiFunction } from 'abitype';
import z from 'zod';

export const MetricSource = z.string().transform((signature, ctx) => {
  // Normalize the signature: remove newlines and extra whitespace
  const normalized = signature.replace(/\s+/g, ' ').trim();

  // Regexp to split: Contract.method(inputs)(outputs)
  const match = /^(\w+)\.(\w+)\((.*)\)\((.*)\)$/.exec(normalized);
  if (!match) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: `Invalid contract and signature ${signature}`,
    });
    return z.NEVER;
  }

  const [contract, functionName, inputs, outputs] = match.slice(1);
  const functionAbi: AbiFunction = {
    type: 'function',
    name: functionName,
    stateMutability: 'view',
    inputs:
      inputs.trim() === ''
        ? []
        : inputs
            .split(',')
            .map((input) => input.trim())
            .filter((input) => input !== '')
            .map((input, index) => {
              const parts = input.trim().split(/\s+/);
              const type = parts[0] || '';
              const name = parts.slice(1).join(' ') || `in${index}`;
              return {
                type,
                name,
              };
            }),
    outputs:
      outputs.trim() === ''
        ? []
        : outputs
            .split(',')
            .map((output) => output.trim())
            .filter((output) => output !== '')
            .map((output, index) => {
              const parts = output.trim().split(/\s+/);
              const type = parts[0] || '';
              const name = parts.slice(1).join(' ') || `out${index}`;
              return {
                type,
                name,
              };
            }),
  };
  return { contract, functionAbi, raw: signature };
});

export type MetricSource = z.infer<typeof MetricSource>;
