from flask import Flask, jsonify
import os
import json
import mysql.connector
import redis

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "db")
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_NAME = os.getenv("DB_NAME", "appdb")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    decode_responses=True,
)


def get_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api")
def index():
    """Read application data using Redis cache with MySQL as the source."""

    cache_key = "app:page_data"

    cached = redis_client.get(cache_key)

    if cached:
        data = json.loads(cached)
        data["cache"] = "HIT"
        return jsonify(data)

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT NOW()")
    server_time = cur.fetchone()[0]

    cur.execute("SELECT page_views FROM page_views WHERE id = 1")
    page_views = cur.fetchone()[0]

    cur.close()
    conn.close()

    data = {
        "message": "Hello from MySQL via Flask!",
        "mysql_server_time": str(server_time),
        "page_views": page_views,
    }

    redis_client.setex(
        cache_key,
        30,
        json.dumps(data),
    )

    data["cache"] = "MISS"
    return jsonify(data)


@app.post("/api/view")
def record_view():
    """Write page-view data to MySQL and invalidate the Redis cache."""

    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "UPDATE page_views SET page_views = page_views + 1 WHERE id = 1"
    )

    conn.commit()

    cur.execute("SELECT page_views FROM page_views WHERE id = 1")
    page_views = cur.fetchone()[0]

    cur.close()
    conn.close()

    redis_client.delete("app:page_data")

    return jsonify(
        page_views=page_views,
        cache="INVALIDATED",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)