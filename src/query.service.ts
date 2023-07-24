import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ChainConfig } from './config';
import * as chains from 'viem/chains';
import { createPublicClient, http } from 'viem';
import { Metric } from './metric';
import { Histogram } from 'prom-client';

const dummyChain = (chain: ChainConfig): chains.Chain => ({
  id: 0,
  name: chain.id,
  network: chain.id,
  nativeCurrency: {
    name: chain.id,
    symbol: chain.id,
    decimals: 18,
  },
  rpcUrls: {
    default: { http: [chain.httpRpcUrl] },
    public: { http: [chain.httpRpcUrl] },
  },
});

@Injectable()
export class QueryService {
  private readonly logger = new Logger(QueryService.name);
  chains: Record<string, ChainConfig> = {};
  clients: Record<string, any> = {};
  queryTime: Histogram;

  constructor(configService: ConfigService) {
    const chains = configService.get<ChainConfig[]>('chains');
    chains.forEach((chain) => {
      this.chains[chain.id] = chain;
      this.clients[chain.id] = createPublicClient({
        chain: chains[chain.id] || dummyChain(chain),
        transport: http(chain.httpRpcUrl),
      });
    });

    this.queryTime = new Histogram({
      name: 'view_call_query_duration',
      help: 'Histogram of view calls to the blockchain node',
      labelNames: ['contract', 'functionName', 'chain', 'status'],
    });
  }

  async query(metric: Metric): Promise<any> {
    if (this.chains[metric.chain] === undefined) {
      throw new Error(
        `Unknown chain ${metric.chain} in metric: ${metric.name}`,
      );
    }

    const addresses = this.chains[metric.chain].addresses;
    const client = this.clients[metric.chain];

    const functionName = metric.source.functionAbi.name;
    const address = addresses[metric.source.contract];
    const abi = metric.source.functionAbi;
    const args = metric.args.map((arg, index) => {
      if (abi.inputs[index].type === 'address') {
        if (addresses[arg] === undefined) {
          return arg;
        }
        return addresses[arg];
      }
    });

    const timer = this.queryTime.startTimer({
      contract: metric.source.contract,
      functionName: metric.source.functionAbi.name,
      chain: metric.chain,
    });
    try {
      const data: bigint = await client.readContract({
        address,
        abi: [abi],
        functionName,
        args,
      });
      timer({ status: 'success' });
      return data;
    } catch (e) {
      // TODO: Add error handling
      this.logger.error(e);
      timer({ status: 'error' });
      return undefined;
    }
  }
}
