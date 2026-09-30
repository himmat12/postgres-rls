-- 01   roles
begin;
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'dev_role') then
        execute format(
            'create role %I with login password %L',
            'dev_role',
            'dev'
            );
    end if;
    
    if not exists (select 1 from pg_roles where rolname = 'app_role') then
        execute format(
            'create role %I with login password %L',
            'app_role',
            'app'
            );
    end if;
    
    if not exists (select 1 from pg_roles where rolname = 'db_worker') then
        execute format(
            'create role %I',
            'db_worker'
            );
    end if;
end $$;
commit;

-- 02   database level privileges
begin;
    grant connect on database demo_db to app_role;
    grant connect on database demo_db to dev_role;
commit;

-- 03   schemas
begin;
    create schema if not exists data;
    create schema if not exists api;
commit;

-- 04   schema level privileges
begin;

    -- developer access to data
    grant usage, create on schema data to dev_role;
    grant all privileges on all tables in schema data to dev_role;

    -- worker access to existing data tables
    grant usage on schema data to db_worker;
    grant select, insert, update, delete
        on all tables in schema data to db_worker;

    -- future data tables created as dbo
    alter default privileges for role dbo in schema data
        grant all privileges on tables to dev_role;

    alter default privileges for role dbo in schema data
        grant select, insert, update, delete on tables to db_worker;

    -- future data tables created as dev_role
    alter default privileges for role dev_role in schema data
        grant select, insert, update, delete on tables to db_worker;

    -- worker can create and own functions in api
    grant usage, create on schema api to db_worker;

    -- app can resolve functions in api
    grant usage on schema api to app_role;

    -- developers can call existing api functions
    grant usage on schema api to dev_role;
    grant execute on all functions in schema api to dev_role;

commit;

-- 05   tables
begin;
    create table if not exists data.tenants(
        id int generated always as identity primary key,
        name text,
        created_at timestamptz not null default current_timestamp
    );
    
    create table if not exists data.users(
        id int generated always as identity primary key,
        tenant_id int not null,
        name varchar(50),
        email text unique not null,
        password text not null,
        created_at timestamptz not null default current_timestamp,

        constraint users_tenant_id_fk
            foreign key (tenant_id)
            references data.tenants(id)
            on delete cascade
    );

    create table if not exists data.user_calendars(
        id int generated always as identity primary key,
        tenant_id int not null,
        user_id int not null,
        summary varchar(50),
        description text,
        owner text,
        created_at timestamptz not null default current_timestamp,

        constraint calendars_tenant_id_fk
            foreign key (tenant_id)
            references data.tenants(id)
            on delete cascade,
            
        constraint calendars_user_id_fk
            foreign key (user_id)
            references data.users(id)
            on delete cascade
    );
    
    create table if not exists data.user_calendar_events(
        id int generated always as identity primary key,
        tenant_id int not null,
        calender_id int not null,
        name varchar(50),
        description text,
        organiser text,
        participants text,
        hangout_link text,
        starts_at timestamptz not null,
        ends_at timestamptz not null,
        created_at timestamptz not null default current_timestamp,

        constraint user_events_tenant_id_fk
            foreign key (tenant_id)
            references data.tenants(id)
            on delete cascade,
            
        constraint user_events_calendar_id_fk
            foreign key (calender_id)
            references data.user_calendars(id)
            on delete cascade
    );
commit;


-- 06   enable RLS
begin;
    alter table data.tenants enable row level security;
    -- alter table data.users enable row level security;
    alter table data.user_calendars enable row level security;
    alter table data.user_calendar_events enable row level security;
commit;


-- 07   RLS policies
begin;
    create policy tenant_data_isoation_policy on data.tenants
    for all
    to app_role
    using (id=nullif(current_setting('data.current_tenant', true), '')::int)
    with check (id=current_setting('data.current_tenant, true')::int);
    
    -- create policy users_data_isoation_policy on data.users
    -- for all
    -- to app_role
    -- using (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int)
    -- with check (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int);
    
    create policy users_calendar_isoation_policy on data.user_calendars
    for all
    to app_role
    using (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int)
    with check (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int);
    
    create policy users_calendar_event_isoation_policy on data.user_calendar_events
    for all
    to app_role
    using (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int)
    with check (tenant_id=nullif(current_setting('data.current_tenant', true), '')::int);

commit;


