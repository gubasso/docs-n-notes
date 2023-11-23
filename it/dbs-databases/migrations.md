# Migrations

<!-- toc -->

- [sqlx (rust)](#sqlx-rust)
  - [Create new migration script](#create-new-migration-script)
  - [Simple run the migrations:](#simple-run-the-migrations)

<!-- tocstop -->

## sqlx (rust)

To handle changes in the sql files without code changes, use the `sqlx-cli`:

```sh
cargo install sqlx-cli
```

`<VERSION>_<DESCRIPTION>.sql`

- `<VERSION>` is a string that can be parsed into i64
- `<DESCRIPTION>` is a string

Example:

**`./migrations/<version>_<description>.sql`**
```sql
-- 0001_books_table.sql
create table book (
  isbn varchar not null primary key,
  title varchar not null,
  author varchar not null
);
```

### Create new migration script

```sh
sqlx migrate add <DESCRIPTION>
```

- Creates a new file in `migrations/<timestamp>-<name>.sql`[^3]

For **Reverting Migrations**:[^3]

```
$ sqlx migrate add -r <name>
Creating migrations/20211001154420_<name>.up.sql
Creating migrations/20211001154420_<name>.down.sql
```

### Simple run the migrations:

- Once you have files at `migrations`
- Will execute each file in `migrations` dir, in order.

```sh
sqlx migrate run #[^2]
```

And **reverts** work as well (when creating the *first* migration):[^3]

```
$ sqlx migrate revert
Applied 20211001154420/revert <name>
```

**Note**: All the subsequent migrations will be reversible as well.

```
$ sqlx migrate add <name1>
Creating migrations/20211001154420_<name>.up.sql
Creating migrations/20211001154420_<name>.down.sql
```

Or

```rs
# main.rs
sqlx::migrate!("./migrations").run(&pool).await?;
```

```sh
# run the migration
sqlx migrate build-script
# build.sh will be generated
```





[^1]: https://www.youtube.com/watch?v=TCERYbgvbq0 "SQLx is my favorite PostgreSQL driver to use with Rust."
[^2]: https://www.youtube.com/watch?v=TyiSn1guKhs "Introducing Rust Into Your Company: Automate Database Migrations - Ardan Labs"
[^3]: https://github.com/launchbadge/sqlx/blob/main/sqlx-cli/README.md "SQLx CLI - sqlx-cli/README.md"
