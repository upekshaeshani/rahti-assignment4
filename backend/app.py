from flask import Flask, jsonify
import os
import mysql.connector

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "db")
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_NAME = os.getenv("DB_NAME", "appdb")


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
    """Read data dynamically from MySQL."""

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT NOW()")
    server_time = cur.fetchone()[0]

    cur.execute("SELECT page_views FROM page_views WHERE id = 1")
    page_views = cur.fetchone()[0]

    cur.close()
    conn.close()

    return jsonify(
        message="Hello from MySQL via Flask!",
        mysql_server_time=str(server_time),
        page_views=page_views,
    )


@app.post("/api/view")
def record_view():
    """Write data to MySQL by incrementing the page-view counter."""

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

    return jsonify(page_views=page_views)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
