import { MetricSource } from './config/MetricSource';
import { Metric } from './metric';

describe('Metric.parse', () => {
  let metric: Metric;

  beforeEach(() => {
    const source: MetricSource = {
      contract: 'TestContract',
      functionAbi: {
        type: 'function',
        name: 'testFunction',
        stateMutability: 'view',
        inputs: [],
        outputs: [{ type: 'uint256', name: 'output' }],
      },
      raw: 'TestContract.testFunction()(uint256)',
    };
    metric = new Metric(source, [], 'testChain', 'testChainLabel', 'gauge');
  });

  describe('SortedOracles.numRates()', () => {
    it('should parse function correctly', () => {
      const output = BigInt(10);
      const result = metric.parse(output, 'numRates');
      expect(result).toBe(10);
    });

    it('should throw an error if numRates value is too large', () => {
      const output = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(1);
      expect(() => metric.parse(output, 'numRates')).toThrow(
        `Value ${output} is too large to be a safe integer`,
      );
    });
  });

  describe('BreakerBox.getRateFeedTradingMode()', () => {
    it('should parse all trading modes correctly', () => {
      const tradingModes = [1, 2, 3, 4];

      tradingModes.forEach((mode) => {
        const output = BigInt(mode);
        const result = metric.parse(output, 'getRateFeedTradingMode');
        expect(result).toBe(mode);
      });
    });

    it('should throw an error if trading mode value is too large', () => {
      const output = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(1);
      expect(() => metric.parse(output, 'getRateFeedTradingMode')).toThrow(
        `Value ${output} is too large to be a safe integer`,
      );
    });
  });

  describe('SortedOracles.isOldestReportExpired()', () => {
    it('should parse function correctly', () => {
      const output: [boolean, bigint] = [true, BigInt(0)];
      const result = metric.parse(output, 'isOldestReportExpired');
      expect(result).toBe(1);
    });
  });

  describe('OracleHelper.deviation()', () => {
    it('should parse function correctly', () => {
      const numerator = BigInt(100);
      const denominator = BigInt(200);
      const output: [bigint, bigint] = [numerator, denominator];
      const result = metric.parse(output, 'deviation');
      expect(result).toBe(0.5);
    });

    it('should return 0 for deviation if denominator is zero', () => {
      const numerator = BigInt(100);
      const denominator = BigInt(0);
      const output: [bigint, bigint] = [numerator, denominator];
      const result = metric.parse(output, 'deviation');
      expect(result).toBe(0);
    });

    it('should throw an error if deviation value is too large', () => {
      const numerator = BigInt(Number.MAX_SAFE_INTEGER) * BigInt(2);
      const denominator = BigInt(1);
      const precision = BigInt(1e6);
      const value = (numerator * precision) / denominator;
      const output: [bigint, bigint] = [numerator, denominator];
      expect(() => metric.parse(output, 'deviation')).toThrow(
        `Value ${value} is too large to be converted to number`,
      );
    });
  });

  it('should throw an error for unknown function', () => {
    const funcName = 'unknownFunction';
    const output = BigInt(10);
    expect(() => metric.parse(output, funcName)).toThrow(
      `Unknown function ${funcName} for metric testFunction. Make sure to add a case for it in the Metric.parse() method.`,
    );
  });
});
