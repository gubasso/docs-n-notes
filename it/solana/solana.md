# Solana

<!-- toc -->

- [Resources](#resources)
  - [Development:](#development)
- [General](#general)
- [Solana CLI](#solana-cli)

<!-- tocstop -->

## Resources

- [SOLdit Development Tutorial - Building a Web3 Reddit using Solana Smart Contract s - Josh's DevBox](https://www.youtube.com/watch?v=UW-KAFkeEPM&list=UULFpozECHF9QxfEu6LfWYVfKw)
- [Solana Development Tutorial - Josh's DevBox](https://www.youtube.com/watch?v=-AAtfPHEMbA&list=PL53JxaGwWUqCr3xm4qvqbgpJ4Xbs4lCs7)
- [Tutorial: Building Games on Solana - Solana](https://www.youtube.com/watch?v=KT9anz_V9ns)

### Development:

- https://solana.com/developers
- https://solanacookbook.com/
- https://www.soldev.app/
- https://www.anchor-lang.com/
- https://docs.solanalabs.com/cli/usage#deploy-program
- https://docs.rs/solana-program/latest/solana_program/
- https://github.com/solana-labs/rbpf

[Developing on-chain programs](https://solana.com/docs/programs)
  - https://solana.com/docs/programs/faq#berkeley-packet-filter-bpf
  - programId = pubkey of programs account
  - https://solana.com/docs/programs/limitations

[Developing with Rust](https://solana.com/docs/programs/lang-rust#project-layout)

[Deploy a Solana Program with the CLI](https://docs.solanalabs.com/cli/examples/deploy-a-program)

## General

wallet: https://backpack.app/

- schedule transactions:
  - https://www.clockwork.xyz/
    - automation engine
    - sequence of executions
    - triggers:
      - account data change
      - cron
      - on demand

devnet details:

- https://docs.solanalabs.com/clusters/available

Solana clusters:

- http://explorer.solana.com/
- http://solanabeach.io/

## Solana CLI

Solana cli create wallet:

```sh
solana-keygen new
```

Wallet info

```sh
solana address # Pubkey wallet address
solana balance
solana airdrop 1
```

target the Devnet cluster, run:

```sh
# https://api.mainnet-beta.solana.com
solana config set --url https://api.devnet.solana.com
```

```sh
solana config get # get config info
solana config set --url localhost
solana config set --url devnet
```

To run localhost

```sh
solana-test-validator
```
