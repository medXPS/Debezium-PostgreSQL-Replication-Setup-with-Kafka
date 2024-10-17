
# Debezium PostgreSQL Replication Setup with Kafka

## Architecture Overview

This project demonstrates the use of Debezium to capture row-level changes from PostgreSQL and stream them to Kafka. It leverages PostgreSQL's logical decoding to stream inserts, updates, and deletes to Kafka topics. However, **DDL (schema changes) are not automatically replicated**.

Key components:
- **Debezium PostgreSQL connector** captures changes.
- **Kafka** serves as the message broker.
- **PostgreSQL** master-slave setup with replication.
### Step 0: Clone the project

```bash
git clone https://github.com/medXPS/Debezium-PostgreSQL-Replication-Setup-with-Kafka.git
```
  
### Step 1: Launch the environment

```bash
docker-compose up
```

### Step 2: Configure Debezium

Use the following curl commands to set up the connectors:

- **Configure master1 connector:**
```bash
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

```

- **Configure master2 connector:**
```bash
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

```

### Step 3: Run `stress.sh`

This script creates a table in **master1**, inserts 1000 rows, and compares the count of rows between **master1** and **master2**. If replication fails, it displays an error like:

```bash
./stress.sh

---___---- OOPS

ERROR: relation "test_replication" does not exist
```

### Handling Replication Issues

If you encounter replication issues, ensure that the subscription is set up properly on **master2**:
1. Create the missing role on **master2**.

```sql
CREATE ROLE master1 WITH LOGIN PASSWORD 'master1pass' REPLICATION;
```
2. Grant the appropriate privileges and create the subscription.

```sql
GRANT ALL PRIVILEGES ON DATABASE testdb TO master1;
GRANT USAGE ON SCHEMA public TO master1;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO master1;
```
3. create stress table test_replication

```sql
 CREATE TABLE public.test_replication ( id SERIAL PRIMARY KEY, name VARCHAR(50), value INTEGER );
 ```
 
4.  create subscription
```sql
CREATE SUBSCRIPTION my_subscription CONNECTION 'host=postgres-master1 port=5432 user=master1 password=master1pass dbname=testdb' PUBLICATION dbz_publication;
```

### Step 4: Rerun `stress.sh`

Check if replication is now consistent. After proper setup, the output should confirm:



```bash
./stree.sh
```

```
Creating table in master1...
DROP TABLE
CREATE TABLE
Inserting 1000 rows into master1...
INSERT 0 1000
Waiting for replication to sync...
Fetching data count from master1...
Fetching data count from master2...
Master1 count: 1000
Master2 count: 1000
Replication is consistent. No errors found.
Taux d'erreurs: 0%
```

for 1000 line it looks good 
but what about 100k+?   the use case of debezium is not to stream replication  !!!  Crunchy data  or other solutions seems the best solution for that use case

### Conclusion

The current setup replicates changes efficiently but lacks automatic handling of DDL changes (schema modifications). Tools like **Crunchy Data Operator** offer more comprehensive support, including automatic failover, full DDL replication, and management of PostgreSQL clusters.
