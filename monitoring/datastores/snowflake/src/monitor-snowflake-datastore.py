import snowflake.connector, os

def main(event, context):
  con = snowflake.connector.connect(
    user = os.environ.get('SNOWFLAKE_USER'),
    password = os.environ.get('SNOWFLAKE_PASSWORD'),
    account = os.environ.get('SNOWFLAKE_ACCOUNT'),
    host = os.environ.get('SNOWFLAKE_SATORI_HOST'),
    warehouse = os.environ.get('SNOWFLAKE_WAREHOUSE')
  )

  try:
    print(con.cursor().execute(os.environ.get("SNOWFLAKE_QUERY")).fetchall())
  except Exception as error:
    raise Exception("ERROR: ", error)
