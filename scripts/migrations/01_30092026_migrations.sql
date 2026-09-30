-- ---------------------------------------------------------
-- CHANGELOG:
-- Changes going to deploy
-- ---------------------------------------------------------


-- add new user
begin;
    -- set role to db_worker to own the function
    set role db_worker;

    -- create function with security definer
    create or replace function api.add_user(
        p_tenant_id int, 
        p_name varchar(50), 
        p_email text, 
        p_password text
    )
    returns table(
        id int,
        tenant_id int,
        name varchar(50),
        email text,
        created_at timestamptz
    )
    language plpgsql
    security definer
    set search_path = pg_catalog, pg_temp
    as $$
        begin
            insert into data.users as u (
                tenant_id, 
                name, 
                email, 
                password
            ) 
            values(
                p_tenant_id,
                p_name,
                p_email,
                p_password
            )
            returning
                u.id,
                u.tenant_id, 
                u.name,    
                u.email,
                u.created_at
            into
                id,
                tenant_id,
                name,
                email,
                created_at;

            return next;
        end;
    $$;

    -- reset the role
    reset role;

    -- make sure to revoke public execution to th function
    revoke execute on function api.add_user from public;

    -- grant execute to the function to app_role and dev_role
    grant execute on function api.add_user to app_role;
    grant execute on function api.add_user to dev_role;

commit;

-- get user by email
begin;
    -- set role to db_worker to own the function
    set role db_worker;

    -- create function with security definer
    create or replace function api.get_user_by_email(p_email text)
    returns setof data.users
    language plpgsql
    security definer
    set search_path = pg_catalog, pg_temp
    as $$
        begin
            return query
                select * from data.users u where u.email = p_email;
        end;
    $$;

    -- reset the role
    reset role;

    -- make sure to revoke public execution to th function
    revoke execute on function api.get_user_by_email from public;

    -- grant execute to the function to app_role and dev_role
    grant execute on function api.get_user_by_email to app_role;
    grant execute on function api.get_user_by_email to dev_role;

commit;


-- get all users
begin;
    -- set role to db_worker to own the function
    set role db_worker;

    -- create function with security definer
    create or replace function api.get_all_users()
    returns table(
        id int,
        tenant_id int,
        name varchar(50),
        email text,
        created_at timestamptz
    )
    language plpgsql
    security definer
    set search_path = pg_catalog, pg_temp
    as $$
        begin
        return query
            select 
                u.id,
                u.tenant_id,
                u.name,
                u.email,
                u.created_at 
            from data.users as u;
        end;
    $$;

    -- reset the role
    reset role;

    -- make sure to revoke public execution to th function
    revoke execute on function api.get_all_users from public;

    -- grant execute to the function to app_role and dev_role
    grant execute on function api.get_all_users to app_role;
    grant execute on function api.get_all_users to dev_role;

commit;


--  get user calendars
begin;
    -- set role to db_worker to own the function
    set role db_worker;

    -- create function with security definer
    create or replace function api.get_all_user_calendars(p_tenant_id int, p_user_id int)
    returns setof data.user_calendars
    language plpgsql
    security definer
    set search_path = pg_catalog, pg_temp
    as $$
        begin
            return query
                select * from data.user_calendars uc
                    where uc.tenant_id = p_tenant_id and uc.user_id = p_user_id;
        end;
    $$;

    -- reset the role
    reset role;

    -- make sure to revoke public execution to th function
    revoke execute on function api.get_all_user_calendars from public;

    -- grant execute to the function to app_role and dev_role
    grant execute on function api.get_all_user_calendars to app_role;
    grant execute on function api.get_all_user_calendars to dev_role;

commit;