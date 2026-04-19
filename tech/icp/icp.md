# ICP - Internet Computer

> Dfinity.org

<!-- toc -->

- [General](#general)
  - [Create a new project](#create-a-new-project)
  - [Local ICP](#local-icp)
- [Cycles](#cycles)
- [Testing](#testing)
- [Resources](#resources)
  - [Rust resources](#rust-resources)

<!-- tocstop -->

## General

- Initial setup: https://internetcomputer.org/docs/current/tutorials/developer-journey/level-0/dev-env

### Create a new project

> [Step 2: Create a new project with the name 'hello_world' with the command:](https://internetcomputer.org/docs/current/tutorials/developer-journey/level-0/intro-dfx#step-2-create-a-new-project-with-the-name-hello_world-with-the-command)

```sh
dfx new hello_world
dfx new --type=rust --frontend=sveltekit hello_world
```

### Local ICP

Start the local icp replica

```sh
dfx start --clean --background
```

Register, build, and deploy the canisters specified in the dfx.json

```sh
# deploy all canisters in the dfx.json
dfx deploy
# specify to deploy the canister by name
dfx deploy hello_world_backend
```

Creating the canister

```sh
dfx canister create hello_world_backend
```

Building the canister

```sh
dfx build hello_world_backend
```

Installing the canister

```sh
dfx canister install hello_world_backend
```

## Cycles

deposit cycles from the wallet into the canister

```sh
dfx canister deposit-cycles [cycles amount] [canister-name]
```


## Testing

> [Building with Rust > 5: Writing and deploying canisters > Testing the canister](https://internetcomputer.org/docs/current/developer-docs/backend/rust/deploying#testing-the-canister)
> [PocketIC](https://internetcomputer.org/docs/current/developer-docs/smart-contracts/test/pocket-ic)

## Resources

- [ICP Developer Journey Tutorial Series - DFINITY](https://www.youtube.com/playlist?list=PLuhDt1vhGcrdR2h6nPNylXKS4u8L-efvD)
- [ICP Zero to Dapp - Powered by Encode Club - DFINITY](https://www.youtube.com/playlist?list=PLuhDt1vhGcrcRcHvSKmxIgJAh1b3rcR7N)
- list of dApps: https://internetcomputer.org/sns/
- projects and code samples: https://internetcomputer.org/samples

### Rust resources

- [Introduction to developing canisters in Rust](https://internetcomputer.org/docs/current/developer-docs/backend/rust/)
- rust cdk https://github.com/dfinity/cdk-rs
  - examples: https://github.com/dfinity/cdk-rs/tree/main/examples
