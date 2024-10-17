#!/bin/bash

# Database credentials for master1 and master2
DB1_HOST="localhost"
DB1_PORT="5432"
DB1_USER="master1"
DB1_PASSWORD="master1pass"
DB1_DB="testdb"   # Updated to match your docker-compose setup

DB2_HOST="localhost"
DB2_PORT="5433"
DB2_USER="master2"
DB2_PASSWORD="master2pass"
DB2_DB="testdb"   # Updated to match your docker-compose setup

# Table name
TABLE_NAME="test_replication"

# Set PostgreSQL password for master1 (avoid interactive prompts)
export PGPASSWORD=$DB1_PASSWORD

# Create a table in master1
echo "Creating table in master1..."
psql -h $DB1_HOST -p $DB1_PORT -U $DB1_USER -d $DB1_DB -c "
DROP TABLE IF EXISTS $TABLE_NAME;
CREATE TABLE $TABLE_NAME (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    value INTEGER
);
"

# Batch insert 1000 rows of random data into master1
echo "Inserting 1000 rows into master1..."
INSERT_QUERY="INSERT INTO $TABLE_NAME (name, value) VALUES"
for i in {1..10}; do
  RANDOM_NAME="name_$RANDOM"
  RANDOM_VALUE=$RANDOM
  INSERT_QUERY+=" ('$RANDOM_NAME', $RANDOM_VALUE),"
done
INSERT_QUERY=${INSERT_QUERY%,}";"

psql -h $DB1_HOST -p $DB1_PORT -U $DB1_USER -d $DB1_DB -c "$INSERT_QUERY"

# Wait a few seconds to allow replication to complete
echo "Waiting for replication to sync..."
sleep 10

# Fetch data count from master1
echo "Fetching data count from master1..."
MASTER1_COUNT=$(psql -h $DB1_HOST -p $DB1_PORT -U $DB1_USER -d $DB1_DB -c "SELECT COUNT(*) FROM $TABLE_NAME;" -t | xargs)

# Set PostgreSQL password for master2
export PGPASSWORD=$DB2_PASSWORD

# Fetch data count from master2
echo "Fetching data count from master2..."
MASTER2_COUNT=$(psql -h $DB2_HOST -p $DB2_PORT -U $DB2_USER -d $DB2_DB -c "SELECT COUNT(*) FROM $TABLE_NAME;" -t | xargs)

# Compare the data count between master1 and master2
echo "Master1 count: $MASTER1_COUNT"
echo "Master2 count: $MASTER2_COUNT"

# Handle empty MASTER2_COUNT
if [ -z "$MASTER2_COUNT" ]; then
  echo "Error: Could not retrieve data from master2. Replication might have failed."
  exit 1
fi

# Calculate error rate (taux d'erreurs)
if [ "$MASTER1_COUNT" -eq "$MASTER2_COUNT" ]; then
  echo "Replication is consistent. No errors found."
  echo "Taux d'erreurs: 0%"
else
  ERROR_RATE=$(awk "BEGIN {print ($MASTER1_COUNT - $MASTER2_COUNT) / $MASTER1_COUNT * 100}")
  echo "Replication inconsistency detected."
  echo "Taux d'erreurs: $ERROR_RATE%"
fi

# Cleanup PostgreSQL password from environment
unset PGPASSWORD
