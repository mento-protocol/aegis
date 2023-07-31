## Description

Aegis is a monitoring tool used to expose the result of on-chain view calls as prometheus metrics that get ingested into grafana.
The ethos of the system is that it should be generic and agnostic when it comes to business logic.

There are three main components to think about when spinning up the system:

1. The `aegis` service that polls view calls and exposes prometheus metrics based on a `config.yaml` file.
2. A service that ingests the metrics, this could be:
   a. A `grafana-agent` instance which pushes the metrics to grafan-cloud.
   b. A prometheus server which ingests the metrics.
3. (Optional) Helper smart contracts which do any transformations needed to on-chain data for ingestion by `aegis`.

### Configuration

The `config.yaml` has three immediate children:

```typescript
interface Config {
  global: Global; // Global settings
  chains: Chain[]; // Chain definitions
  metrics: Metric[]; // Metric definitions
}
```

`Global` contains a set of variables that can be referenced in the arguments passed to view calls. These can be overriden by chain specific variables.

```typescript
interface Global {
  vars: Record<string, string>;
}
```

`Chain` contains the chain definition:

```typescript
interface Chain {
  id: string;
  label: string;
  httpRpcUrl: string;
  contracts: Record<string, string>;
  vars: Record<string, string>;
}
```

If the chain `id` matches an import from [viem's chains](https://viem.sh/docs/clients/chains.html) that will be used, enabling multicall and other goodness.
However arbitrary values also work and a custom chain instance will be created.

The `label` will be used in the context of prometheus metrics `chain={label}` for segmenting.

The `contracts` object should list addresses for all contracts referenced in `metrics`.
The `vars` object contains chain specific variables and will override entries in the `global.vars` object.

`Metric` defines a metric with all it's possible variations.

```typescript
interface Metric {
  source: string;
  schedule: string;
  type: 'gouge';
  chains: 'all' | string[];
  variants: string[][];
}
```

The `source` for a metric is the view call used. This should be a string of the form:

```
Contract.function(inputs)(outputs)
```

For example:

```
SortedOracles.numRates(address rateFeed)(uint256)
```

The contract must be defined in the `Chain` configs that the metric targets.

The system currently supports view calls of two types:

- A single `uint256` value which must not exceed `Number.MAX_SAFE_INTEGER`.
- Two `uint256`: value and scale. The metric exposed is then `value/scale`, which must fit into a `Number` as well. 1e6 of precision is kept during the conversion.

The `schedule` is a cron schedule definition.

The `type` can currently be only `gauge`.

The `chains` field can either be `all` or an array of chain ids that this metric will apply to.

And `variants` is a list where each item is an array of arguments passed to the view call.

Full example:

```yaml
source: SortedOracles.numRates(address rateFeed)(uint256)
schedule: 0/10 * * * * *
type: gauge
chains: all
variants:
  - ['CELOUSD']
  - ['CELOEUR']
  - ['CELOBRL']
  - ['USDCUSD']
  - ['USDCEUR']
  - ['USDCBRL']
```

The `variants` is where the `vars` from the `global` and `chain` configs come into play.
Here we're calling the function 6 times and each time passing the value of the variables as the `rateFeed` argument to the view call.

All arguments of the view call will be passed as metric labels as well to prometheus.
Thus each metric will result in `number of variants * number of chains` values recorded.

This is an example of the prometheus endpoint result:

```
numRates{rateFeed="CELOUSD",chain="celo"} 10
numRates{rateFeed="CELOEUR",chain="celo"} 10
numRates{rateFeed="USDCBRL",chain="celo"} 0
numRates{rateFeed="USDCEUR",chain="celo"} 0
numRates{rateFeed="USDCUSD",chain="celo"} 10
numRates{rateFeed="CELOBRL",chain="celo"} 10
numRates{rateFeed="CELOUSD",chain="alfajores"} 5
numRates{rateFeed="CELOEUR",chain="alfajores"} 5
numRates{rateFeed="USDCEUR",chain="alfajores"} 5
numRates{rateFeed="CELOUSD",chain="baklava"} 5
numRates{rateFeed="USDCUSD",chain="alfajores"} 6
numRates{rateFeed="USDCBRL",chain="alfajores"} 5
numRates{rateFeed="USDCBRL",chain="baklava"} 6
numRates{rateFeed="CELOBRL",chain="alfajores"} 5
numRates{rateFeed="USDCUSD",chain="baklava"} 6
numRates{rateFeed="CELOEUR",chain="baklava"} 6
numRates{rateFeed="CELOBRL",chain="baklava"} 5
numRates{rateFeed="USDCEUR",chain="baklava"} 6
```

## Installation

```bash
$ pnpm install
```

## Running the app

```bash
# development
$ pnpm run start

# watch mode
$ pnpm run start:dev

# production mode
$ pnpm run start:prod
```

## Test

```bash
# unit tests
$ pnpm run test

# e2e tests
$ pnpm run test:e2e

# test coverage
$ pnpm run test:cov
```

## Deployment (Mento labs)

There are two services that make up the app:

- `aegis`: collects the metrics and exposes them.
- `grafana-agent`: pushes them to grafana cloud.

Deploying `aegis` is done simply by running `gcloud app deploy` with `gcloud` pointing to `mento-prod`.
For deploying the `grafana-agent` follow the instructions in `grafana-agent/README.md`.

## Stay in touch

- Author - [Mento Labs](https://mentolabs.xyz)
- Twitter - [@mentolabs](https://twitter.com/mentolabs)

## License

Nest is [MIT licensed](LICENSE).
