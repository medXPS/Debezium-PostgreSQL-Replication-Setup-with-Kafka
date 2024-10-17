curl -X POST http://localhost:8083/connectors/ -H "Content-Type: application/json" -d '{
  "name": "master1-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "postgres-master1",
    "database.port": "5432",
    "database.user": "master1",
    "database.password": "master1pass",
    "database.dbname": "testdb",
    "database.server.name": "master1",
    "plugin.name": "pgoutput",
    "slot.name": "debezium",
    "publication.name": "dbz_publication",
    "topic.prefix": "master1",
    "schema.include.list": "public",              
    "include.schema.changes": "true"             
  }
}'



######################################
curl -X POST http://localhost:8083/connectors/ -H "Content-Type: application/json" -d '{
  "name": "master2-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "postgres-master2",
    "database.port": "5432",
    "database.user": "master2",
    "database.password": "master2pass",
    "database.dbname": "testdb",
    "database.server.name": "master2",
    "plugin.name": "pgoutput",
    "slot.name": "debezium",
    "publication.name": "dbz_publication",
    "topic.prefix": "master2",
    "schema.include.list": "public",           
    "include.schema.changes": "true"             
  }
}'
