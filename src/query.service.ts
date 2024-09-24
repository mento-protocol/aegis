import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Histogram } from 'prom-client';
import { createPublicClient, http, parseAbi } from 'viem';
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

    const client = this.clients[metric.chain];
    const address = this.chains[metric.chain].contracts[metric.source.contract];
    const functionName = metric.source.functionAbi.name;
    const abi = metric.source.functionAbi;
    const args = this.mapArgs(metric.args, this.chains[metric.chain].vars);

    const timer = this.startTimer(metric);

    try {
      const data: bigint = await client.readContract({
        address,
        abi: [abi],
        functionName,
        args,
      });

      // If the function name is balanceOf then also get the decimals
      // then return this with the data so it can be parsed correctly
      if (functionName === 'balanceOf') {
        const decimals = await client.readContract({
          address,
          abi: parseAbi(['function decimals() view returns (uint8)']),
          functionName: 'decimals',
          args: [],
        });

        timer({ status: 'success' });
        return metric.parse([data, decimals], functionName);
      } else {
        timer({ status: 'success' });
        return metric.parse(data, functionName);
      }
    } catch (e) {
      this.logger.error(
        `Error querying ${functionName} on ${metric.chain}: ${e.message}`,
      );
      timer({ status: 'error' });
      return undefined;
    }
  }

  private mapArgs(args: any[], vars: Record<string, string>): any[] {
    return args.map((arg) => (vars[arg] !== undefined ? vars[arg] : arg));
  }

  private startTimer(metric: Metric) {
    return this.queryTime.startTimer({
      contract: metric.source.contract,
      functionName: metric.source.functionAbi.name,
      chain: metric.chain,
    });
  }
}
