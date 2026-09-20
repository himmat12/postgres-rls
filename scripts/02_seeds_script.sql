
begin;
    -- tenants
    insert into app.tenants(name) 
    values
        ('Doublone Studios'),
        ('Lightspeed Studios'),
        ('Demo PLC');
commit;
