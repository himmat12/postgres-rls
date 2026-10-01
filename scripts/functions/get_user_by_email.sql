begin;
    -- set role to db_worker to own the function
    set role db_worker;

    -- create function with security definer
    create or replace function api.get_user_by_email(p_email text)
    returns table(
        id int,
        tenant_id int,
        email text,
        name varchar(50)
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
                    u.email,
                    u.name
                from data.users as u 
                where 
                u.email = p_email
                and u.tenant_id = nullif(current_setting('data.current_tenant', true), '')::int;
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