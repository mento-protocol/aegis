import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AddressBook, Config, Contract, Metric } from './config';
import { celo, celoAlfajores, Chain } from 'viem/chains';
import { createPublicClient, http, AbiItem } from 'viem';
import { AbiFunction } from 'abitype';

const CHAINS: Record<Config['chain']['id'], Chain> = {
  celo: celo,
  celoAlfajores: celoAlfajores,
};

@Injectable()
export class ReaderService {
  private readonly logger = new Logger(ReaderService.name);
  addresses: AddressBook;
  contracts: Record<string, Contract>;
  client: any;
  contractAbis: Record<string, Record<string, AbiItem>>;

  constructor(private configService: ConfigService) {
    this.addresses = configService.get('addresses');
    this.contracts = configService
      .get<Contract[]>('contracts')
      .reduce((acc, contract) => {
        acc[contract.name] = contract;
        return acc;
      }, {});

    this.client = createPublicClient({
      chain: CHAINS[this.configService.get('chain.id')],
      transport: http(this.configService.get('chain.httpRpcUrl')),
    });
  }

  async read(metric: Metric): Promise<any> {
    const [contract, functionName] = metric.source.split('.');
    const address = this.addresses[contract];
    const abi = this.contracts[contract].methods.find(
      (m) => m.name === functionName,
    );
    const args = metric.args.map((arg, index) => {
      if (abi.inputs[index].type === 'address') {
        if (this.addresses[arg] === undefined) {
          return arg;
        }
        return this.addresses[arg];
      }
    });

    const data = await this.client.readContract({
      address,
      abi: [abi],
      functionName,
      args,
    });

    return data;
  }
}
