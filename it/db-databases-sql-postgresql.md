# PostgreSQL
> $sql $database $postgresql

<!-- vim-markdown-toc GitLab -->

* [TODO: To study](#todo-to-study)
* [General PostgreSQL](#general-postgresql)
    * [Import/export data to/from postgresql:](#importexport-data-tofrom-postgresql)
        * [Tools](#tools)
        * [csvkit](#csvkit)
* [Users, Roles, Connections, Authentications](#users-roles-connections-authentications)
* [Install and first config](#install-and-first-config)
* [Examples](#examples)
    * [`main.sql` with env variable, users roles, import schema](#mainsql-with-env-variable-users-roles-import-schema)
* [PostgREST:](#postgrest)
* [References:](#references)

<!-- vim-markdown-toc -->

## TODO: To study
> `# PostgreSQL`

- create a database:
    - https://www.tutorialspoint.com/postgresql/postgresql_create_database.htm
    - https://www.postgresql.org/docs/12/sql-createdatabase.html

## General PostgreSQL
> `# PostgreSQL`


- Grant select on every table inside schema
```
GRANT SELECT ON ALL TABLES IN SCHEMA public TO user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO user;
```

- pretty print output, alternative output formats for tables in terminal[^sql11]

- Generate SQL table statement/code from csv:[^sql8]
```
csvsql -i postgresql examples/realdata/FY09_EDU_Recipients_by_State.csv
```

**environment variables and psql variables:**[^sql10]

- environment variable inside psql variable:

```
\set afile `echo "$outputdir/a.csv"`
COPY (SELECT * FROM a) TO :'afile';
```

```
\set auth_passwd `echo "${AUTH_PASSWD}"`;
```

- only psql variables

```
\set outputdir '/path/to/output'
\set afile :outputdir '/a.csv'
COPY (SELECT * FROM a) TO :'afile';
```
- set variable when call psql command:
```
psql --set=outputdir="$outputdir" <conn parameters> -f /path/to/yourscript.sql
```

**Pivot and unpivot tables:**

[Equivalent to unpivot() in PostgreSQL](https://stackoverflow.com/questions/1128737/equivalent-to-unpivot-in-postgresql)
- using `UNION ALL`
- `unnest(array[a, b, c])`
- `VALUES()` and `JOIN LATERAL`

[How to Create Pivot Table in PostgreSQL](https://ubiq.co/database-blog/create-pivot-table-postgresql/)
[Pivot Tables in PostgreSQL Using the Crosstab Function](https://learnsql.com/blog/creating-pivot-tables-in-postgresql-using-the-crosstab-function/)


**Find list tables in a PostgreSQL schema using meta-command:**

- `\l` : list all databases
1. `\c adventureworks`: Switch to the database
2. `\dn`: list of schemas in this database
3. `\dt sales.* `: list of tables in sales schema.
4. `\dt *.*`: get tables from all schemas

**Run postgresql sql script from another script:**
**import script:**

```[^sql12][^sql13]
\i other_script.sql
SELECT * FROM table_1;
SELECT * FROM table_2;
```

- run a `main.sql`[^sql13]
```
psql -U postgres -h localhost -d postgres -f filename.sql
 or
psql ... < filename.sql
```

**psql command flags:**

- `psql -U USER_NAME_HERE` — The -U flag is used to specify the user role that will execute the script. This option can be omited if this option’s username is the first parameter. The default username is the system’s current username, if one has not been explicitly specified.
- `psql -h 127.0.0.1` — The -h flag is for the remote host or domain IP address where the PostgreSQL server is running. Use 127.0.0.1 for a localhost server.
- `psql -d some_database` — The -d option is used for the database name.
- `psql -a` — The -a or --echo-all flags will print all of the lines in the SQL file that conatin any content.
- `psql -f /some/path/my_script_name.sql` — The -f option will instruct psql to execute the file. This is arguably the most critical of all the options.

[Find the host name and port using PSQL commands](https://stackoverflow.com/questions/5598517/find-the-host-name-and-port-using-psql-commands)


### Import/export data to/from postgresql:

```
COPY api.tab0042(var0014, ind0471, ind0472, ind0483, ind0484, ind0465, ind0466, ind0464, ind0468, ind0461, ind0462, ind0463, ind0467, ind0469)
FROM '/vagrant/data/tab0042.csv'
DELIMITER ','
CSV HEADER;
```

#### Tools


- pgfutter: https://github.com/lukasmartinelli/pgfutter
    - import csv and json
- csvkit: https://github.com/wireservice/csvkit
- pgclimb: https://github.com/lukasmartinelli/pgclimb

#### csvkit

Dependency to generate SQL insert command from CSV file: `csvkit` package.

- https://csvkit.readthedocs.io/en/latest/index.html

Generate a statement in the PostgreSQL dialect [^2]:

```
csvsql -i postgresql -d "," examples/realdata/FY09_EDU_Recipients_by_State.csv
```


## Users, Roles, Connections, Authentications

[4 types of postgresql user authentication methods you must know](https://postgreshelp.com/postgresql-user-authentication-demystified/)
- How the PostgreSQL user authentication is done when you login to the database?
- How to Change a Password for PostgreSQL user?
    - \password
- PostgreSQL User Authentication types:
    - Peer Authentication:
        - User Name Mapping :
    - Trust Authentication
    - md5 Authentication
    - ident Authentication

- create a role in database:
```
create role contacts_read noinherit nologin;
```
    - `nologin`: its not possible to connect to database using this user. Have to connect with a different user and switch to this role.
    - `noinherit`: does not inherit any permissions from other users/roles.

- Connect with password as a environment variable[^sql9].1
```
PGPASSWORD=<my-pass> psql -U ...
```

- Other plenty connection examples commands[^sql14][^sql15]

_password prompt_
```
psql -h uta.biocommons.org -U foo
Password for user foo: 
```

_`pgpass` file_
```
<host>:<port>:<database>:<user>:<password>
```

_`PGPASSWORD` environment variable_
```
export PGPASSWORD=yourpass
psql ...

# Or in one line for this invocation only:

PGPASSWORD=yourpass psql ...
```

_connection string_

- TCP/IP
```
psql postgresql://username:password@dbmaster:5433/mydb?sslmode=require
```
- Unix socket and the Peer Authentication method
```
psql postgres://username@/dbname
```
    - `username`: has to be a system username


- `psql -c "CREATE USER admin WITH PASSWORD 'test101';"` : run this command in database to create a user with password
    - to run it as `postgres` user, just add `sudo -u postgres <command>` before the command


## Install and first config
_breadcrumbs: `## PostgreSQL`_

- install: with package manager of your distribution or by building it from source
- enable and start service:
```
sudo systemctl enable postgresql --now
```

There are usually two default ways to login to PostgreSQL server:[^sql5]

1. By running the "psql" command as a UNIX user (so-called IDENT/PEER authentication), e.g.: `sudo -u postgres psql`. Note that `sudo -u` does NOT unlock the UNIX user.
2. by TCP/IP connection using PostgreSQL's own managed username/password (so-called TCP authentication) (i.e., NOT the UNIX password).

So you never want to set the password for UNIX account "postgres". Leave it locked as it is by default.

- secure users passwords[^sql4]
```
/var/lib/pgsql/data/postgresql.conf
---
password_encryption = scram-sha-256     # md5 or scram-sha-256
```

- change permissions to connections[^sql6]
```
/var/lib/pgsql/data/pg_hba.conf
---
#  "local" is for Unix domain socket connections only
# local   all             all                                     peer
# local   all             all                                     trust
local   all             all                                     scram-sha-256
#  IPv4 local connections:
# host    all             all             127.0.0.1/32            ident
# host    all             all             127.0.0.1/32            trust
host    all             all             127.0.0.1/32            scram-sha-256
#  IPv6 local connections:
# host    all             all             ::1/128                 ident
# host    all             all             ::1/128                 trust
host    all             all             ::1/128                 scram-sha-256
```
- Restart `postgresql.service,` and then re-add each user's password using

- create password for user `postgres`
```
sudo -u postgres psql -c "ALTER USER postgres WITH ENCRYPTED PASSWORD '${MY_PASS}';"
```

- make all users set new passwords, and change the authentication method specifications in pg_hba.conf to scram-sha-256

```
CREATE ROLE foo WITH LOGIN PASSWORD 'secret';
--or
ALTER ROLE foo WITH LOGIN PASSWORD 'secret';
--or
ALTER USER user WITH ENCRYPTED PASSWORD 'password';
```

## Examples

### `main.sql` with env variable, users roles, import schema

Used to create a $postgrest database and rest API.[^1]

```
\set auth_passwd `echo "${AUTH_PASSWD}"`;

create schema api;
\i tab0042.sql;

create role web_anon nologin;

grant usage on schema api to web_anon;
grant select on all tables in schema api to web_anon;
grant execute on all functions in schema api to web_anon;
create role authenticator noinherit login password 'auth_passwd';
grant web_anon to authenticator;
create role gubasso noinherit login password 'auth_passwd';
grant web_anon to gubasso;
```

## PostgREST:

PostgREST is a standalone web server that turns your PostgreSQL database directly into a RESTful API. The structural constraints and permissions in the database determine the API endpoints and operations.[^1]

```postgrest.conf
db-uri = "postgres://gubasso@/postgres"
db-schema = "api"
db-anon-role = "web_anon"
```

```postgrest.service
[Unit]
Description=REST API for any PostgreSQL database
After=postgresql.service

[Service]
User=gubasso
Group=wheel
ExecStart=/bin/postgrest /etc/postgrest/postgrest.conf
ExecReload=/bin/kill -SIGUSR1 $MAINPID

[Install]
WantedBy=multi-user.target
```

## References:

[^1]: [PostgREST: standalone web server that turns your PostgreSQL database directly into a RESTful API](https://postgrest.org/en/stable/)
[^2]: [csvkit Docs » Reference » csvsql » Examples](https://csvkit.readthedocs.io/en/latest/scripts/csvsql.html#examples)


