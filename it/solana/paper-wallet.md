# Solana: Paper Wallet

Create:

```sh
solana-keygen new --no-outfile
solana-keygen new --no-outfile --word-count 24
```

Balance

```sh
solana balance <pubkey>
```


If you want to generate solana cli keypair file from phantom seed phrase:
```sh
solana-keygen recover prompt:// -o ~/.config/solana/id.json
```

## References

[^1]: https://docs.solanalabs.com/cli/wallets/paper "Paper Wallets using the Solana CLI"
