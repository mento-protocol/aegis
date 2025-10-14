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
        return [{ label: 'celo', vars: { '0x123': 'mockValue' } }];
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
    it('should parse and return both values', () => {
      const output: [boolean, bigint] = [true, BigInt(0)];
      const result = metric.parse(
        output,
        'SortedOracles',
        'isOldestReportExpired',
      );
      expect(Array.isArray(result)).toBe(true);
      expect(result).toEqual([1, 0]);
    });

    it('should handle false value', () => {
      const output: [boolean, bigint] = [false, BigInt(123)];
      const result = metric.parse(
        output,
        'SortedOracles',
        'isOldestReportExpired',
      );
      expect(result).toEqual([0, 123]);
    });
  });

  describe('Broker.tradingLimitsState()', () => {
    it('should parse and return all five values in correct order', () => {
      const output: [bigint, bigint, bigint, bigint, bigint] = [
        BigInt(1234567890), // lastUpdated0
        BigInt(1234567891), // lastUpdated1
        BigInt(100), // netflow0
        BigInt(500), // netflow1
        BigInt(1000), // netflowGlobal
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsState');
      expect(Array.isArray(result)).toBe(true);
      expect(result).toEqual([1234567890, 1234567891, 100, 500, 1000]);
    });

    it('should handle negative netflow values', () => {
      const output: [bigint, bigint, bigint, bigint, bigint] = [
        BigInt(1234567890), // lastUpdated0
        BigInt(1234567891), // lastUpdated1
        BigInt(-100), // netflow0
        BigInt(-500), // netflow1
        BigInt(-1000), // netflowGlobal
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsState');
      expect(result).toEqual([1234567890, 1234567891, -100, -500, -1000]);
    });

    it('should throw an error if value is too large', () => {
      const output: [bigint, bigint, bigint, bigint, bigint] = [
        BigInt(Number.MAX_SAFE_INTEGER) + BigInt(1),
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
      ];
      expect(() =>
        metric.parse(output, 'Broker', 'tradingLimitsState'),
      ).toThrow('uint32');
    });
  });

  describe('Broker.tradingLimitsConfig()', () => {
    it('should parse and return all six values in correct order', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(300), // timestep0 (5 min)
        BigInt(86400), // timestep1 (1 day)
        BigInt(100000), // limit0
        BigInt(500000), // limit1
        BigInt(1000000), // limitGlobal
        BigInt(3), // flags
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsConfig');
      expect(Array.isArray(result)).toBe(true);
      expect(result).toEqual([300, 86400, 100000, 500000, 1000000, 3]);
    });

    it('should handle zero flags (disabled limit)', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(300),
        BigInt(86400),
        BigInt(100000),
        BigInt(500000),
        BigInt(1000000),
        BigInt(0), // disabled
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsConfig');
      expect(result).toEqual([300, 86400, 100000, 500000, 1000000, 0]);
    });

    it('should handle negative limit values', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(300),
        BigInt(86400),
        BigInt(-100000), // negative limit0
        BigInt(-500000), // negative limit1
        BigInt(-1000000), // negative limitGlobal
        BigInt(3),
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsConfig');
      expect(result).toEqual([300, 86400, -100000, -500000, -1000000, 3]);
    });

    it('should throw an error if value is too large', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(Number.MAX_SAFE_INTEGER) + BigInt(1),
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
      ];
      expect(() =>
        metric.parse(output, 'Broker', 'tradingLimitsConfig'),
      ).toThrow('uint32');
    });

    it('should handle maximum safe integer values', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(4294967295), // max uint32
        BigInt(4294967295),
        BigInt(140737488355327), // max int48
        BigInt(140737488355327),
        BigInt(140737488355327),
        BigInt(255), // max uint8
      ];
      const result = metric.parse(output, 'Broker', 'tradingLimitsConfig');
      expect(result).toEqual([
        4294967295, 4294967295, 140737488355327, 140737488355327,
        140737488355327, 255,
      ]);
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

  describe('Multi-gauge integration tests', () => {
    it('should create multiple gauges for functions with multiple return values', () => {
      const source: MetricSource = {
        contract: 'Broker',
        functionAbi: {
          type: 'function',
          name: 'tradingLimitsState',
          stateMutability: 'view',
          inputs: [{ type: 'bytes32', name: 'limitId' }],
          outputs: [
            { type: 'uint32', name: 'lastUpdated0' },
            { type: 'uint32', name: 'lastUpdated1' },
            { type: 'int48', name: 'netflow0' },
            { type: 'int48', name: 'netflow1' },
            { type: 'int48', name: 'netflowGlobal' },
          ],
        },
        raw: 'Broker.tradingLimitsState(bytes32 limitId)(uint32 lastUpdated0, uint32 lastUpdated1, int48 netflow0, int48 netflow1, int48 netflowGlobal)',
      };

      const multiGaugeMetric = new Metric(
        source,
        ['0x123'],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      expect(Array.isArray(multiGaugeMetric.gauge)).toBe(true);
      expect((multiGaugeMetric.gauge as any[]).length).toBe(5);
    });

    it('should create single gauge for functions with single return value', () => {
      const source: MetricSource = {
        contract: 'BreakerBox',
        functionAbi: {
          type: 'function',
          name: 'getRateFeedTradingMode',
          stateMutability: 'view',
          inputs: [{ type: 'address', name: 'rateFeedID' }],
          outputs: [{ type: 'uint8', name: 'mode' }],
        },
        raw: 'BreakerBox.getRateFeedTradingMode(address rateFeedID)(uint8 mode)',
      };

      const singleGaugeMetric = new Metric(
        source,
        ['0x123'],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      expect(Array.isArray(singleGaugeMetric.gauge)).toBe(false);
    });

    it('should correctly distribute array values to multiple gauges via update()', () => {
      const source: MetricSource = {
        contract: 'Broker',
        functionAbi: {
          type: 'function',
          name: 'tradingLimitsState',
          stateMutability: 'view',
          inputs: [{ type: 'bytes32', name: 'limitId' }],
          outputs: [
            { type: 'uint32', name: 'lastUpdated0' },
            { type: 'uint32', name: 'lastUpdated1' },
            { type: 'int48', name: 'netflow0' },
            { type: 'int48', name: 'netflow1' },
            { type: 'int48', name: 'netflowGlobal' },
          ],
        },
        raw: 'Broker.tradingLimitsState(bytes32 limitId)(uint32 lastUpdated0, uint32 lastUpdated1, int48 netflow0, int48 netflow1, int48 netflowGlobal)',
      };

      const multiGaugeMetric = new Metric(
        source,
        ['0x123'],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      const values = [1234567890, 1234567891, 100, 500, 1000];

      // This should not throw
      expect(() => multiGaugeMetric.update(values)).not.toThrow();
    });

    it('should throw error when updating single gauge with array of values', () => {
      const source: MetricSource = {
        contract: 'BreakerBox',
        functionAbi: {
          type: 'function',
          name: 'getRateFeedTradingMode',
          stateMutability: 'view',
          inputs: [{ type: 'address', name: 'rateFeedID' }],
          outputs: [{ type: 'uint8', name: 'mode' }],
        },
        raw: 'BreakerBox.getRateFeedTradingMode(address rateFeedID)(uint8 mode)',
      };

      const singleGaugeMetric = new Metric(
        source,
        ['0x123'],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      expect(() => singleGaugeMetric.update([1, 2, 3])).toThrow(
        'Cannot update single gauge with array of values',
      );
    });

    it('should throw error when updating multiple gauges with single value', () => {
      const source: MetricSource = {
        contract: 'Broker',
        functionAbi: {
          type: 'function',
          name: 'tradingLimitsState',
          stateMutability: 'view',
          inputs: [{ type: 'bytes32', name: 'limitId' }],
          outputs: [
            { type: 'uint32', name: 'lastUpdated0' },
            { type: 'uint32', name: 'lastUpdated1' },
          ],
        },
        raw: 'Broker.tradingLimitsState(bytes32 limitId)(uint32 lastUpdated0, uint32 lastUpdated1)',
      };

      const multiGaugeMetric = new Metric(
        source,
        ['0x123'],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      expect(() => multiGaugeMetric.update(123)).toThrow(
        'Cannot update multiple gauges with single value',
      );
    });

    it('should handle unnamed outputs by creating fallback names', () => {
      // This tests that MetricSource.ts properly handles unnamed outputs with out0, out1, etc.
      const source: MetricSource = {
        contract: 'TestContract',
        functionAbi: {
          type: 'function',
          name: 'getValue',
          stateMutability: 'view',
          inputs: [],
          outputs: [
            { type: 'uint256', name: 'out0' }, // Fallback name
            { type: 'uint256', name: 'out1' }, // Fallback name
          ],
        },
        raw: 'TestContract.getValue()(uint256, uint256)',
      };

      const metricWithUnnamedOutputs = new Metric(
        source,
        [],
        'celo',
        'celo',
        'gauge',
        mockConfigService,
      );

      expect(Array.isArray(metricWithUnnamedOutputs.gauge)).toBe(true);
      expect((metricWithUnnamedOutputs.gauge as any[]).length).toBe(2);
    });
  });

  describe('Type validation tests', () => {
    it('should throw error when tradingLimitsState value exceeds uint32 bounds', () => {
      const output: [bigint, bigint, bigint, bigint, bigint] = [
        BigInt(4294967296), // uint32 max + 1
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
      ];
      expect(() =>
        metric.parse(output, 'Broker', 'tradingLimitsState'),
      ).toThrow('uint32');
    });

    it('should throw error when tradingLimitsState netflow exceeds int48 bounds', () => {
      const output: [bigint, bigint, bigint, bigint, bigint] = [
        BigInt(0),
        BigInt(0),
        BigInt(140737488355328), // int48 max + 1
        BigInt(0),
        BigInt(0),
      ];
      expect(() =>
        metric.parse(output, 'Broker', 'tradingLimitsState'),
      ).toThrow('int48');
    });

    it('should throw error when tradingLimitsConfig flags exceeds uint8 bounds', () => {
      const output: [bigint, bigint, bigint, bigint, bigint, bigint] = [
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(0),
        BigInt(256), // uint8 max + 1
      ];
      expect(() =>
        metric.parse(output, 'Broker', 'tradingLimitsConfig'),
      ).toThrow('uint8');
    });
  });
});
