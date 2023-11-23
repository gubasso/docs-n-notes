# Migrations

<!-- toc -->

- [sqlx (rust)](#sqlx-rust)
  - [Simple run the migrations:](#simple-run-the-migrations)

<!-- tocstop -->

## sqlx (rust)

To handle changes in the sql files without code changes, use the `sqlx-cli`:

```sh
cargo install sqlx-cli
```

### Simple run the migrations:

- Once you have files at `migrations`
- Will execute each file in `migrations` dir, in order.

```sh
sqlx migrate run #[^2]
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


**`./migrations/<version>_<description>.sql`**

Example:

```sql
-- 0001_books_table.sql
create table book (
  isbn varchar not null primary key,
  title varchar not null,
  author varchar not null
);
```



[^1]: https://www.youtube.com/watch?v=TCERYbgvbq0 "SQLx is my favorite PostgreSQL driver to use with Rust."
[^2]: https://www.youtube.com/watch?v=TyiSn1guKhs "Introducing Rust Into Your Company: Automate Database Migrations - Ardan Labs"
