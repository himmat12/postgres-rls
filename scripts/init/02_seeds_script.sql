
begin;
    -- tenants
    insert into data.tenants(name) 
    values
        ('Vance Refrigerator LLC'),
        ('Dunder Mifland Papers'),
        ('Lightspeed Studios'),
        ('Demo PLC');
commit;

begin;
    -- users
    insert into data.users(
        tenant_id,
        name,
        email,
        password
    )
    values
    (
        1,
        'Bob Vance',
        'bob_vance@email.com',
        'bob_vance'
    ),
    (
        2,
        'Dwieght Shrude',
        'dweight_shrude@email.com',
        'dweight_shrude'
    ),
    (
        2,
        'Michal Scott',
        'michal_scott@email.com',
        'michal_scott'
    );
commit;
