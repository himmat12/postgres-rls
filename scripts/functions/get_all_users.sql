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