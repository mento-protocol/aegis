import { ConfigService } from '@nestjs/config';
import { MetricSource } from './config/MetricSource';
import { Metric } from './metric';

describe('Metric.parse', () => {
  let metric: Metric;
  let mockConfigService: jest.Mocked<ConfigService>;

  beforeEach(() => {
    mockConfigService = {
      get: jest.fn(),
    } as unknown as jest.Mocked<ConfigService>;
    mockConfigService.get.mockImplementation((key: string) => {
      if (key === 'chains') {
        return [{ label: 'celo' }];
      }
      // Add other config keys as needed
      return undefined;
    });
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
    metric = new Metric(
      source,
      [],
      'testChain',
      'testChainLabel',
      'gauge',
      mockConfigService,
    );
  });

  describe('BreakerBox.getRateFeedTradingMode()', () => {
    it('should parse all trading modes correctly', () => {
      const tradingModes = [1, 2, 3, 4];

      tradingModes.forEach((mode) => {
        const output = BigInt(mode);
        const result = metric.parse(
          output,
          'BreakerBox',
          'getRateFeedTradingMode',
        );
        expect(result).toBe(mode);
      });
    });

    it('should throw an error if trading mode value is too large', () => {
      const output = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(1);
      expect(() =>
        metric.parse(output, 'BreakerBox', 'getRateFeedTradingMode'),
      ).toThrow(`Value ${output} is too large to be a safe integer`);
    });
  });

  describe('SortedOracles.isOldestReportExpired()', () => {
    it('should parse function correctly', () => {
      const output: [boolean, bigint] = [true, BigInt(0)];
      const result = metric.parse(
        output,
        'SortedOracles',
        'isOldestReportExpired',
      );
      expect(result).toBe(1);
    });
  });

  it('should throw an error for unknown function', () => {
    const metricName = `TestContract.unknownFunction`;
    const funcName = 'unknownFunction';
    const output = BigInt(10);
    expect(() => metric.parse(output, 'TestContract', funcName)).toThrow(
      `Unknown metric '${metricName}'. Make sure to add a case for it in the Metric.parse() method.`,
    );
  });
});
