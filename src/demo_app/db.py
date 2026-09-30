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
                                    select * from api.get_user_by_email('{email}');
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

    auth_res = await auth("bob_vance@email.com", "bob_vance", conn)
    print(auth_res)

    async with conn.transaction():
        await conn.execute(f"""
                set local data.current_tenant = {auth_res["tenant_id"]};
            """)
        res = await conn.fetchrow(
            """
                select * from api.add_user($1, $2, $3, $4)
            """,
            2,
            "Troy Stone",
            "troy_stone@email.com",
            "troy_stone",
        )

        new_user = dict(res)
        
        print(new_user['id'])
        print(new_user['name'])
        print(new_user['email'])
        print(new_user['created_at'])
    await conn.close()


asyncio.run(main())
