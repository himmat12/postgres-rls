# Multi-Tenancy with RLS Policy in PostgreSQL

## Table of Contents
- [Motivation](#motivation)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Security and Isolation Guarantees](#security-and-isolation-guarantees)

## Motivation

In the modern software industry, Software as a Service (SaaS) is a familiar term in the technology space. However, most of us might not yet know how these services are provided as software solutions to end users while storing everyone’s data privately and securely in the database.

Yes, we are talking about a database design approach called Multi-Tenancy, which is implemented primarily to isolate multiple tenants’ (users/enterprises/teams) sensitive data on resources that are shared between hundreds to millions of other tenants. SaaS products are the prime candidates that cannot compromise end users’ data due to invisible exploits and backdoors left in your system in production.

This repository contains a production-ready data and service layer template for implementing a Multi-Tenant design architecture with Row-Level Security (RLS) policies in PostgreSQL.

The goal is to isolate all data tables in the database with shared data between multiple tenants by validating each row-level access through PostgreSQL’s built-in RLS feature and RLS policies.

Furthermore, this project is scaffolded with NORM (No Object-Relational Mapper) and the Least Privilege design principle in mind. Therefore, you will not see `SQLAlchemy` or any other ORM you usually see paired together with FastAPI to build backend services. The data layer (a complete isolation layer where data lives and is the single source of truth for the application/service) exposes a least-privileged separate schema which only holds PostgreSQL functions. These functions are owned by a specific database worker role, which itself has least privileges on that schema. The application/service layer uses an application user role, which is the most least-privileged role in the database and only has `USAGE` and `EXECUTE` grants on that schema. The application role delegates function execution to the database worker role (importantly, this role will not have `LOGIN`, hence it is completely invisible to the outside world from the data layer).

The Python client (app/service layer) just executes the data layer (PostgreSQL) functions via a database driver (`asyncpg`), which respects the NORM design principle. The whole point of engineering your data layer in multiple vectors is to keep it secure from attacks and exploits, which is yet to happen with the advancement of frontier models and agentic capabilities. This measure will not completely eliminate and cover all attack vectors for your system, but it reduces the blast radius when D-day comes.

## Project Structure

- [`scripts`](scripts/) holds all required database provisioning scripts (roles, privileges, schemas, tables, RLS, policies). This is executed initially when the compose spins up the `postgres` service, and when it is running and healthy you already have a database and RLS set up to get your hands on with PostgreSQL.
- [`src`](src/) contains the Python client which uses the `asyncpg` PostgreSQL database driver to establish a connection with the running PostgreSQL service and execute database operations (`execute`, `fetch`, `fetchrow`, and so on).

## Getting Started

**Clone and setup**
- `git clone <repo-url>`
- `cd <repo-name>`

**Spin up PostgreSQL server (Data Layer)**
- `docker compose up -d`

**Connect to PostgreSQL with `psql` client terminal**
- `docker compose exec postgres bash`
- `psql -U user_role -d demo_db`

> Check the PostgreSQL and `psql` cheatsheet [here](https://github.com/himmat12/CS-Archive/tree/main/SQL/PostgreSQL).

**Running the Python client service (Service Layer)**  
- First navigate to `cd ./<repo-name>/src/` and start the service `uv run fastapi dev`. 
- Then `python ./demo_app/db.py` to see the results of the `asyncpg` DB driver establishing a connection with the PostgreSQL server, which simulates a basic password-based authentication with database users and then retrieves the `tenant_id`, which is key to everything we do afterwards. This tenant identifier helps keep your data safe from accidental leaks or exploits from other tenant users’ account access to the shared database.
> *NOTE: This service is not fully implemented as of now but will be updated later.*


## Architecture

This project follows a clear separation between the data layer and the service layer:

- **Data layer (PostgreSQL)**  
  All tenant data lives in shared tables under a dedicated schema (for example, `data`). Every table includes a `tenant_id` column and has Row-Level Security (RLS) enabled. Access to these tables is not done directly from the application code. Instead, all operations go through PostgreSQL functions in a separate schema (for example, `api` or `service`).

- **Service layer (Python + FastAPI)**  
  The Python client connects to PostgreSQL using `asyncpg` and never issues raw `SELECT`, `INSERT`, `UPDATE`, or `DELETE` on tenant tables. It only calls functions in the `api` schema. These functions encapsulate all business logic at the database level and act as the single entry point to the data layer.

- **NORM (No ORM) approach**  
  There is no SQLAlchemy or other ORM in this stack. SQL is written explicitly in PostgreSQL functions, and the Python side only handles connection management, tenant context, and function calls. This keeps the data layer as the single source of truth and avoids hidden queries generated by an ORM.

- **Tenant context**  
  Tenant isolation is enforced by RLS policies that read a session-local setting (for example, `app.current_tenant`). At the beginning of each request or transaction, the service layer sets this value (via `SET LOCAL`) to the authenticated tenant’s ID. All subsequent operations in that transaction automatically respect the tenant boundary.

## Security Model

The security model is built around least privilege and defense in depth:

- **Database roles**
  - `app_user` (or similar):  
    - Has `LOGIN` and is used by the Python service to connect.  
    - Has very limited privileges: only `USAGE` on the `api` schema and `EXECUTE` on specific functions.  
    - Cannot directly access tenant tables.
  - `db_worker` (or similar):  
    - Does **not** have `LOGIN`, so it cannot be used to connect from outside.  
    - Owns the `api` schema and all functions.  
    - Has minimal required privileges (e.g., `SELECT`, `INSERT`, `UPDATE`, `DELETE`) on the `data` schema tables.  
    - Functions are defined with `SECURITY DEFINER` so they execute with `db_worker` privileges, but RLS still applies per row.

- **Row-Level Security (RLS)**
  - Every tenant-scoped table has `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY`.  
  - Policies use the `tenant_id` column and the session setting `app.current_tenant` to restrict which rows are visible or modifiable.  
  - Even if a future change introduces a direct query (by mistake), RLS will still block access to rows outside the current tenant, as long as the role does not have `BYPASSRLS`.

- **Attack surface reduction**
  - The application cannot construct arbitrary SQL against tenant tables; it can only call vetted functions.  
  - The `db_worker` role is not directly accessible from outside the database.  
  - Tenant isolation is enforced at the database engine level, not just in application code.  
  - This design does not eliminate all possible attacks, but it significantly reduces the blast radius if part of the system is compromised.


## Security and Isolation Guarantees
Together, these layers ensure that:

- Tenant data is isolated by design, not by convention.  
- The data layer remains the authoritative and secure boundary for all data operations.  
- The service layer remains thin, focused, and harder to misuse, even as the codebase or team grows.

#### [BACK TO TOP](#multi-tenancy-with-rls-policy-in-postgresql)