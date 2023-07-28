import z from 'zod';
import { AbiFunction } from 'abitype';

export const MetricSource = z
  .string()
  .transform((signature, ctx) => {
    // Regexp to split: Contract.method(inputs)(outputs)
    const match = /^(\w+)\.(\w+)\((.*)\)\((.*)\)$/.exec(signature);
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
      inputs: inputs.split(',').map((input, index) => {
        const [type, name] = input.split(' ');
        return {
          type,
          name: name ? name : `in${index}`,
        };
      }),
      outputs: outputs.split(',').map((output, index) => {
        const [type, name] = output.split(' ');
        return {
          type,
          name: name ? name : `out${index}`,
        };
      }),
    };
    return { contract, functionAbi, raw: signature };
  })
  .refine(
    (v) =>
      v.functionAbi.outputs.length == 1 || v.functionAbi.outputs.length == 2,
    {
      message:
        'Only functions with one or two return values currently supported',
    },
  );

export type MetricSource = z.infer<typeof MetricSource>;
