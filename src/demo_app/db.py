import asyncio
import asyncpg
from os import getenv
from dotenv import load_dotenv
from typing import Any

load_dotenv()

DATABASE_URL = getenv("DATABASE_URL")
APP_USER = getenv("APP_USER")
APP_PASSWORD = getenv("APP_PASSWORD")


async def init_db():
    return await asyncpg.connect(f"{DATABASE_URL}")


async def auth(email: str, password: str, conn) -> dict[str, Any]:
    async with conn.transaction():
        row = await conn.fetchrow(f"""
                                    select * from app.users where email = '{email}';
                                  """)
    failed_res = {"authenticated": False, "tenant_id": None}
    if not row:
        return failed_res
    
    user = dict(row)
    success_res = {"authenticated": True, "tenant_id": user.get("tenant_id")}
    if user.get("password", "") == password:
        return success_res
    
    return failed_res


async def main():
    conn = await init_db()
    print(conn)

    auth_res = await auth("bob_vance@gmail.com", "bob_vance123", conn)
    print(auth_res)
    
    # async with conn.transaction():
    #     await conn.execute(f"""
    #             set local app.current_tenant = {tenant_id};
    #             insert into app.users(tenant_id, name, email, password) values(3, 'Jenny Reii', 'jenny_reii@gmail.com', 'jenny_reii123');
    #         """)
    # await conn.close()


asyncio.run(main())
