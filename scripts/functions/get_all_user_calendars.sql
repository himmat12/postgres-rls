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