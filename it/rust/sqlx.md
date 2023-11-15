# SQLx (Rust)

> library, crate

## Basic example[^1]

### Simple connection

```rust
let mut conn = sqlx::postgres::PgConnection::connect(url).await?;
let res = sqlx::query("SELECT 1 + 1 as sum")
  .fetch_one(&mut conn)
  .await?;
let sum: i32 = res.get("sum");
println!("1 + 1 = {}", sum);
```

### Connection pool

Better create a connection pool.

```rust
let pool = sqlx::postgres::PgPoolOptions::new()
  .max_connections(5)
  .connect(url).await?;
let res = sqlx::query("SELECT 1 + 1 as sum")
  .fetch_one(&pool)
  .await?;
let sum: i32 = res.get("sum");
println!("1 + 1 = {}", sum);
```


## Migrations[^1]

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

```rs
# main.rs

sqlx::migrate!("./migrations").run(&pool).await?;
```

To handle changes in the sql files without code changes, use the `sqlx-cli`:

```sh
cargo install sqlx-cli
# after install
# run the migration
sqlx migrate build-script
# build.sh will be generated
```

## Queries Examples

> query

### Writting Data: `INSERT` and `UPDATE`

#### Example 1[^1]

```rs
struct Book {
  pub title: String,
  pub author: String,
  pub isbn: String,
}

async fn create(book: &Book, pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let query = "INSERT INTO book (title, author, isbn) VALUES ($1, $2, $3)";

  sqlx::query(query)
    .bind(&book.title)
    .bind(&book.author)
    .bind(&book.isbn)
    .execute(pool)
    .await?;

  Ok(())
}

async fn update(book: &Book, isbn: &str, pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let query = "UPDATE book SET title = $1, author = $2 WHERE isbn = $3";

  sqlx::query(query)
    .bind(&book.title)
    .bind(&book.author)
    .bind(&book.isbn)
    .execute(pool)
    .await?;

  Ok(())
}

async fn main() -> ... {
  # (...)
  let book = Book {
    title: "Rich Dad Poor Dad".to_string(),
    author: "Robert Kyiosaki".to_string(),
    isbn: "948-4-23454-23454-1".to_string()
  }

  create(&book, &pool).await?;
  update(&book, &book.isbn, &pool).await?;
}
```

#### Example 2[^2]

```rs
let row: (i64,) = sqlx::query_as("INSERT INTO ticket (name) VALUES ($1) RETURNING id")
  .bind("a new ticket")
  .fetch_one(&pool)
  .await?;
```

### Reading Data `SELECT`


#### Example 1[^1]

Methods to read data with a query:

- `fetch_one`
  - single row
  - if row does not exists, return a error
- `fetch_optional`
  - single row (Some(row))
  - if don't exists, returns `None`
- `fetch_all`
  - vector
- `fetch`
  - stream
  - more "asynchonous" approach
  - better performance for large datasets

```rust
# fetch_one example
# need to import sqlx::Row;

use sqlx::Row;

async fn read(pool: &sqlx::PgPool) -> Result<Book, Box<dyn Error>> {
  let q = "SELECT title, author, isbn FROM book";
  let query = sqlx::query(q);
  let row = query.fetch_one(pool).await?;
  let book = Book {
    title: row.get("title"),
    author: row.get("author"),
    isbn: row.get("isbn"),
  };

  Ok(book)

}
```

```rust
# fetch example
# need to import:
#   - sqlx::Row;
#   - futures::TryStreamExt;

use sqlx::Row;
use futures::TryStreamExt;

async fn read(pool: &sqlx::PgPool) -> Result<Vec<Book>, Box<dyn Error>> {
  let q = "SELECT title, author, isbn FROM book";
  let query = sqlx::query(q);
  let rows = query.fetch(pool);
  let mut books = vec![];

  while let Some(row) = rows.try_next().await? {
    books.push(Book {
      title: row.get("title"),
      author: row.get("author"),
      isbn: row.get("isbn"),
    })
  }
  Ok(books)
}
```

#### Example 2[^2]

```rs
let rows: Vec<PgRow> = sqlx::query("SELECT * FROM ticket")
  .fetch_all(&pool)
  .await?;
let str_result: String = rows.iter()
  .map(|r| format!("{} - {}", r.get::<i64, _>("id"), r.get::<String, _>("name")))
  .collect::<Vec<String>>()
  .join(", ");
```

#### Example 3[^2]

Select query with `map()`, build type manually.

```rs
#[derive(Debug, FromRow)]
struct Ticket {
  id: i64,
  name: String,
}

async fn main() {
  let select_query = sqlx::query("SELECT id, name FROM ticket");
  let tickets: Vec<Ticket> = select_query
    .map(|row| Ticket {
      id: row.get("id"),
      name: row.get("name"),
    })
    .fetch_all(&pool)
    .await?;

}
```

#### Example 4: `query_as()`[^1]

`query_as()` From Row to Type Automatically. Convert automatically to the type.

```rust
# fetch_all example with query_as
use sqlx::FromRow;

#[derive(FromRow)]
struct Book {
  pub title: String,
  pub author: String,
  pub isbn: String,
}

async fn read(pool: &sqlx::PgPool) -> Result<Vec<Book>, Box<dyn Error>> {
  let q = "SELECT title, author, isbn FROM book";
  let query = sqlx::query_as::<_, Book>(q);
  let books = query.fetch_all(pool).await?;
  Ok(books)
}
```

#### Example 5: `query_as()`[^2]

```rs
let select_query = sqlx::query_as::<_, Ticket>("SELECT id, name FROM ticket");
let tickets: Vec<Ticket> = select_query.fetch_all(&pool).await?;
```

## Transactions

Atomic operations.

```sql
-- 0001_initial.sql
create table author (
  id bigint primary key GENERATED ALWAYS AS IDENTITY,
  name varchar not null
);

create table book (
  isbn varchar not null primary key,
  title varchar not null,
  author_id int not null references author(id)
);
```

```rust
async fn insert_book(book: Book, pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let mut txn = pool.begin.await?;
  let author_q = r"
    INSERT INTO author (name) VALUES ($1) RETURNING id
  ";
  let book_q = r"
    INSERT INTO book (title, author_id, isbn)
    VALUES ($1, $2, $3)
  ";
  let author_id: (i64,) = sqlx::query_as(author_q)
    .bind(&book.author)
    .fetch_one(&mut txn)
    .await?;
  sqlx::query(book_q)
    .bind(&book.title)
    .bind(&book.author_id.0)
    .bind(&book.isbn)
    .execute(&mut txn)
    .await?;
  txn.commit().await?;
  # can undo the transaction (txn) with `rollback` method
  # txn.rollback().await?;
  Ok(())
}
```

## Json (Serde)

```sql
-- 0001_initial.sql
create table book (
  title varchar not null,
  metadata json
);
```

```toml
# Cargo.toml
sqlx = { version = "0.7.2", features = ["runtime-tokio", "tls-rustls", "json"] }
```

```rust
#[derive(FromRow)]
struct Book {
  pub title: String,
  pub metadata: Metadata,
}

#[derive(Serialize, Deserialize)]
struct Metadata {
  pub avg_review: f32,
  pub tags: Vec<String>,
}

async fn insert_book(pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let book = Book {
    title: "Game of Thrones".to_string(),
    metadata: Metadata {
      avg_review: 9.4,
      tags: vec!["fantasy".to_string(), "epic".to_string()],
    }
  };
  let q = "INSERT INTO book (title, metadata) VALUES ($1, $2)";

  sqlx::query(q)
    .bind(&book.title)
    .bind(sqlx::types::Json(&book.metadata))
    .execute(pool)
    .await?;

  Ok(())
}
```

## UUID

```sql
-- 0001_initial.sql
create table book (
  id uuid primary key,
  title varchar not null
);
```


```toml
# Cargo.toml
sqlx = { version = "0.7.2", features = ["runtime-tokio", "tls-rustls", "json", "uuid"] }
uuid = "1.3"
```

```rust
#[derive(FromRow)]
struct Book {
  pub id: uuid::Uuid,
  pub title: String,
  pub metadata: Metadata,
}

#[derive(Serialize, Deserialize)]
struct Metadata {
  pub avg_review: f32,
  pub tags: Vec<String>,
}

async fn insert_book(pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let book = Book {
    id: uuid::Uuid::parse_str("8ea8d8de-155f-4dfb-8893-4f5b3f8a4fa5")?,
    title: "Game of Thrones".to_string(),
    metadata: Metadata {
      avg_review: 9.4,
      tags: vec!["fantasy".to_string(), "epic".to_string()],
    }
  };
  let q = "INSERT INTO book (id, title, metadata) VALUES ($1, $2, $3)";

  sqlx::query(q)
    .bind(&book.id)
    .bind(&book.title)
    .bind(sqlx::types::Json(&book.metadata))
    .execute(pool)
    .await?;

  let q = "SELECT id, title FROM book where id = $1";
  let res = sqlx::query_as::<_, Book>(q)
    .bind(&book.id)
    .fetch_one(pool)
    .await?;

  println!("result: {:?}", res);

  Ok(())
}
```

## Chrono (Date / Time)

Timestamps.

```sql
-- 0001_initial.sql
create table book (
  title varchar not null,
  published_date date not null,
  inserted_at timestamp with time zone default now()
);
```

```toml
# Cargo.toml
sqlx = { version = "0.7.2", features = ["runtime-tokio", "tls-rustls", "json", "uuid", "chrono"] }
chrono = "0.4"
```

```rust
#[derive(FromRow)]
struct Book {
  pub id: uuid::Uuid,
  pub title: String,
  pub metadata: Metadata,
  pub published_date: chrono::NaiveDate,
  pub inserted_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Serialize, Deserialize)]
struct Metadata {
  pub avg_review: f32,
  pub tags: Vec<String>,
}

async fn insert_book(pool: &sqlx::PgPool) -> Result<(), Box<dyn Error>> {
  let book = Book {
    id: uuid::Uuid::parse_str("8ea8d8de-155f-4dfb-8893-4f5b3f8a4fa5")?,
    title: "Game of Thrones".to_string(),
    metadata: Metadata {
      avg_review: 9.4,
      tags: vec!["fantasy".to_string(), "epic".to_string()],
    },
    published_date: chrono::NaiveDate::from_yml_opt(1997,8,1).unwrap(),
    inserted_at: None,
  };
  let q = "INSERT INTO book (id, title, metadata, published_date) VALUES ($1, $2, $3, $4)";

  sqlx::query(q)
    .bind(&book.id)
    .bind(&book.title)
    .bind(&book.metadata)
    .bind(&book.published_date)
    .bind(sqlx::types::Json(&book.metadata))
    .execute(pool)
    .await?;

  let q = "SELECT id, title, published_date, inserted_at FROM book";
  let res = sqlx::query_as::<_, Book>(q)
    .fetch_one(pool)
    .await?;

  println!("result: {:?}", res);

  Ok(())
}
```

## Macros feature

Powerful compile time verifications. Static type checking.

Requires the `DATABASE_URL` environment variable to be set.

```rust
let book = sqlx::query_as::<_, Book>(
  "
  SELECT book.title, author.name as author, book.isbn
  FROM book
  JOIN author ON author.id = book.author_id
  WHERE isbn = $1
  "
)
  .bind(isbn)
  .fetch_optional(pool).await?;

# with `query_as!` macro
let book = sqlx::query_as!(Book,
  "
  SELECT book.title, author.name as author, book.isbn
  FROM book
  JOIN author ON author.id = book.author_id
  WHERE isbn = $1
  ",
  isbn,
)
  .fetch_optional(pool).await?;

```

## Others

At video [SQLx is my favorite PostgreSQL driver to use with Rust.](https://www.youtube.com/watch?v=TCERYbgvbq0)[^1], there are more explanations about:

- ipnetwork type
- listen / notify
  - use postgres as an asynchonous notification system



[^1]: https://www.youtube.com/watch?v=TCERYbgvbq0 "SQLx is my favorite PostgreSQL driver to use with Rust."
[^2]: https://www.youtube.com/watch?v=VuVOyUbFSI0 "Rust to Postgres Database with SQLX - Rust Lang Tutorial 2021 - Jeremy Chone"


