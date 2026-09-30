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