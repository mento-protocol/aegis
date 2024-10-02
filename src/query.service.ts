import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Histogram } from 'prom-client';
import { createPublicClient, http } from 'viem';
import * as chains from 'viem/chains';
import { ChainConfig } from './config';
import { Metric } from './metric';

const makeChain = (chain: ChainConfig): chains.Chain => ({
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
  globalVars: Record<string, string>;
  clients: Record<string, any> = {};
  queryTime: Histogram;

  constructor(configService: ConfigService) {
    const chains = configService.get<ChainConfig[]>('chains');
    chains.forEach((chain) => {
      this.chains[chain.id] = chain;
      this.clients[chain.id] = createPublicClient({
        chain: chains[chain.id] || makeChain(chain),
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

    const vars = this.chains[metric.chain].vars;
    const client = this.clients[metric.chain];
    const address = this.chains[metric.chain].contracts[metric.source.contract];
    const contractName = metric.source.contract;
    const functionName = metric.source.functionAbi.name;
    const abi = metric.source.functionAbi;
    const args = metric.args.map((arg) => {
      if (vars[arg] === undefined) {
        return arg;
      }
      return vars[arg];
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
      return metric.parse(data, contractName, functionName);
    } catch (e) {
      // TODO: Add error handling
      this.logger.error(e);
      timer({ status: 'error' });
      return undefined;
    }
  }
}
