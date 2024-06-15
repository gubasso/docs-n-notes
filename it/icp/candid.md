# ICP: Candid

## Generating Candid files for Rust canisters

> [Building with Rust > Generating Candid files for Rust canisters](https://internetcomputer.org/docs/current/developer-docs/backend/rust/generating-candid)

- Install candid-extractor:

```sh
cargo install candid-extractor
# or
cargo binstall candid-extractor
```

- Step 1. Call the export_candid macro at the end of your lib.rs file:

```rs
#[query]
fn hello(name: String) -> String {
    format!("Hello, {}!", name)
}

#[update]
fn world(name: String) -> String {
    format!("World, {}!", name)
}

// Enable Candid export
ic_cdk::export_candid!();
```

- Shell function to extract candid file:

```sh
function gen_candid() {
  canister_name="$1"
  cargo build --release --target wasm32-unknown-unknown --package "$canister_name" || return 1
  candid-extractor "target/wasm32-unknown-unknown/release/$canister_name.wasm" > "$canister_name.did"
}
```
