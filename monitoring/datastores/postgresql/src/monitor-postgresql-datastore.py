import psycopg2, os

def main(event, context):
    conn = psycopg2.connect(
        dbname = os.environ.get('POSTGRESQL_DBNAME'),
        user = os.environ.get('POSTGRESQL_USER'),
        password = os.environ.get('POSTGRESQL_PASSWORD'),
        host = os.environ.get('POSTGRESQL_SATORI_HOST'),
        port = os.environ.get('POSTGRESQL_SATORI_PORT'),
        sslmode = 'require',
        channel_binding = 'disable')

    cur = conn.cursor()
    try:
        cur.execute(os.environ.get("POSTGRESQL_QUERY"))
        resp = cur.fetchone()
        print(resp)
    except Exception as error:
        raise Exception("ERROR: ", error)