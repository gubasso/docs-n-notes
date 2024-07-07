# Solana: Tokens

```sh
cargo install spl-token-cli
spl-token --version
solana config set --url devnet
```

Creates a mint account

```sh
# defaults to 9 decimals
spl-token create-token
spl-token create-token --decimals 12
```

create a token account for handling the balances for this token

```sh
spl-token create-account <token-address>
```


mint some tokens

```sh
# to my account
spl-token mint <token-address> <amount-to-mint>
# to some other account
spl-token mint <token-address> <amount-to-mint> <user-token-account>
```

```sh
spl-token supply <token-address>
```

view all the spl-token accounts under your wallet

```sh
spl-token accounts
```


transfer:

```sh
spl-token transfer <token-address> <amount> <recipient-address> --allow-unfunded-recipient --fund-recipient
```

- –allow-unfunded-recipient to complete the transfer, and we are also adding the flag –fund-recipient because this is a new token and your friend won’t have an associated token account for your token account

## Resources

- https://calyptus.co/lessons/creating-your-first-token/
