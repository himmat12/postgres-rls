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
    
    if not exists (select 1 from pg_roles where rolname = 'user_role') then
        execute format(
            'create role %I with login password %L',
            'user_role',
            'user'
            );
    end if;
end $$;
commit;

-- 02   database level privileges
begin;
    grant connect on database demo_db to user_role;
    grant connect on database demo_db to dev_role;
commit;

-- 03   schemas
begin;
    create schema if not exists app;
commit;

-- 04   schema level privileges
begin;
    grant usage on schema app to user_role;
    grant usage on schema app to dev_role;

    alter default privileges for role dbo in schema app
        grant all privileges on tables to user_role;
        
    alter default privileges for role dbo in schema app
        grant all privileges on tables to dev_role;
    
    alter default privileges for role dbo in schema app
        grant all privileges on functions to user_role;
        
    alter default privileges for role dbo in schema app
        grant all privileges on functions to dev_role;
commit;

-- 05   tables
begin;
    create table if not exists app.tenants(
        id int generated always as identity primary key,
        name text,
        created_at timestamptz not null default current_timestamp
    );
    
    create table if not exists app.users(
        id int generated always as identity primary key,
        tenant_id int not null,
        name varchar(50),
        email text unique not null,
        password text not null,
        created_at timestamptz not null default current_timestamp,

        constraint users_tenant_id_fk
            foreign key (tenant_id)
            references app.tenants(id)
            on delete cascade
    );

    create table if not exists app.user_calendars(
        id int generated always as identity primary key,
        tenant_id int not null,
        user_id int not null,
        summary varchar(50),
        description text,
        owner text,
        created_at timestamptz not null default current_timestamp,

        constraint calendars_tenant_id_fk
            foreign key (tenant_id)
            references app.tenants(id)
            on delete cascade,
            
        constraint calendars_user_id_fk
            foreign key (user_id)
            references app.users(id)
            on delete cascade
    );
    
    create table if not exists app.user_calendar_events(
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
            references app.tenants(id)
            on delete cascade,
            
        constraint user_events_calendar_id_fk
            foreign key (calender_id)
            references app.user_calendars(id)
            on delete cascade
    );
commit;


-- 06   enable RLS
begin;
    alter table app.tenants enable row level security;
    -- alter table app.users enable row level security;
    alter table app.user_calendars enable row level security;
    alter table app.user_calendar_events enable row level security;
commit;


-- 07   RLS policies
begin;
    create policy tenant_data_isoation_policy on app.tenants
    for all
    to user_role
    using (id=nullif(current_setting('app.current_tenant', true), '')::int)
    with check (id=current_setting('app.current_tenant, true')::int);
    
    -- create policy users_data_isoation_policy on app.users
    -- for all
    -- to user_role
    -- using (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int)
    -- with check (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int);
    
    create policy users_calendar_isoation_policy on app.user_calendars
    for all
    to user_role
    using (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int)
    with check (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int);
    
    create policy users_calendar_event_isoation_policy on app.user_calendar_events
    for all
    to user_role
    using (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int)
    with check (tenant_id=nullif(current_setting('app.current_tenant', true), '')::int);

commit;


