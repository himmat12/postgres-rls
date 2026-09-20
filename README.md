# Multi-Tenancy with RLS policy in PostgreSQL

In modern software industry Software as a Service (Saas) is quiet familier term in the world of technology space. However, most of us might not yet know about how these services provided as software solutions to the end users wile storing everyones data privately and securely in the datbase.

Yes, we are talking about a database design approach called Multi-Tenancy which is implemented primarily to isolate multiple tenants (users/enterprise/teams) sensitive data on the resources which is shared between hundreds to milions of other tenants. And Saas products are the prime candiadate which cannot compromise end users data leake due to invisible exploits and backdoors left in your system in production.

This repository contains the production ready data and service layer template for implementing Multi-Tenant design architecture with Row Level Security (RLS) Policies in PosgreSQL.

The goal is to isolate all data tables in the database with shared data between multiple tenants by validating each row level access through postgres built in RLS feature and RLS policy.

Furthermore, this project is scaffolded with NORM (No Object Relational Mapper) and Least Privileges design principle in mind. Therefore, you will not see `SQLAlchamy` or any other ORM you usually see paired together with FastAPI to build backend services. The data layer (a complete isolation layer where data lives and is the single source of truth for the application/service) exposes least privileged seperate schema which only holds postgres functions which is owned by a specific database worker role which itself has least privileges on that schema and the application/service layer uses application user role which is the most least privileged role in the database which only has `USAGE` and `EXECUTE` `GRANT` on that schema and the application role will deligate the function execution to database worker role (importantly this role will not have LOGIN hence this is completely invisible to outside world from data layer).

And the python client (app/service layer) just executes the data layer (postgres) functions via database driver (asyncpg) which respects the NORM design principle. The whole point of engineering your data layer in multiple vectors is to keep it secure from attacks and exploits which is yet to happen in the advancement of frontier models and agentic capabilities. This measure will not completely eliminate and cover all attack vectors for your system but it reduces the blast radius when D-day.


## Project Structure
* [`scripts`](scripts/) holds all required database provisioning scripts (roles, privileges, schemas, tables, RLS, Policies). This is executed initialy when the compose spin up `postgres` service and when it is running an healthy you already have a database and RLS already setup to get your hands on with postgres.
* [`src`](src/) contains the python client which uses `asyncpg` postgres database driver to establish connection with the running postgres service and execute database operations (execute/fetch/fetchrow and so on).

## Getting Started

**Clone and setup**
- `git clone <repo-url>`
- `cd <repo-name>` 

**Spin-up postgres server (Data Layer)** 
- `docker compose up -d`

**Connect to postgres with `psql` client terminal**
- `docker compose exec postgres bash`
- `psql -U user_role -d demo_db`
> Check the postgres and psql cheatsheet [here](https://github.com/himmat12/CS-Archive/tree/main/SQL/PostgreSQL).</br>

**Running the python client service (Service Layer)**</br>
- First navigate to `cd ./<repo-name>/src/` and start the service `uv run fastapi dev`. *NOTE: This service is not fully implemeted as of now but will be updated later.*
- Then `python ./demo_app/db.py` to see the results of `asyncpg` db driver establishing with the postgres server which simulates a basic pasword based authentication with database users and then retrives the `tenant_id` which is key to everything we do afterwards and this tenant identifier helps your data keep safe from accidantial leake or exploits from other tenant users accounts access to shared database.

