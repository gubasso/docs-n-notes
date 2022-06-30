# SQL / Databases

<!-- vim-markdown-toc GFM -->

* [Related Articles](#related-articles)
* [General SQL](#general-sql)
* [Organize SQL Project (files, directories)](#organize-sql-project-files-directories)

<!-- vim-markdown-toc -->

## Related Articles

- [PosgreSQL](./it/sql-db-databases-postgresql.md)

## General SQL

- `Sqitch`: Sqitch is a database change management application.
    - http://sqitch.org/
    - [Simple SQL Change Management with Sqitch](https://www.youtube.com/watch?v=LYevw5cYozw)
    - [sqitch tutorial postgresql](https://github.com/sqitchers/sqitch/blob/develop/lib/sqitchtutorial.pod)

## Organize SQL Project (files, directories)

```
.
├── build
│   ├── main.sql
│   ├── db.sql
│   ├── users.sql
│   ├── roles.sql
│   ├── indexes.sql
│   ├── (...).sql
│   └── tables.sql
├── set
│   ├── functions
│   │   ├── do_this.sql
│   │   └── do_that.sql
│   ├── views
│   │   ├── view_this.sql
│   │   └── also_view_that.sql
│   └── main.sql
├── README.md
├── .env
├── .gitignore
├── some_script.sh
└── some_conf.conf

```

- `build`: keep persistent (hard) objects[^sql1]
- `set`: everything else is soft objects: views, functions sprocs, trigger functions, etc[^sql1]

