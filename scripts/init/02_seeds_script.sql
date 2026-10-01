
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
        password_hash
    )
    values
    (
        1,
        'Bob Vance',
        'bob_vance@email.com',
        crypto.crypt('bob_vance', crypto.gen_salt('bf', 12))
    ),
    (
        2,
        'Dwieght Shrude',
        'dweight_shrude@email.com',
        crypto.crypt('dweight_shrude', crypto.gen_salt('bf', 12))
    ),
    (
        2,
        'Michal Scott',
        'michal_scott@email.com',
        crypto.crypt('michal_scott', crypto.gen_salt('bf', 12))
    );
commit;
