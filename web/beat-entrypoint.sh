#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
max_retries=30
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    python3 -c "
import os
import sys
import psycopg2

try:
    conn = psycopg2.connect(
        dbname=os.environ.get('POSTGRES_DB', 'rengine'),
        user=os.environ.get('POSTGRES_USER', 'rengine'),
        password=os.environ.get('POSTGRES_PASSWORD', ''),
        host=os.environ.get('POSTGRES_HOST', 'db'),
        port=os.environ.get('POSTGRES_PORT', '5432')
    )
    conn.close()
    sys.exit(0)
except Exception as e:
    print(f'Database not ready: {e}')
    sys.exit(1)
" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "PostgreSQL is ready!"
        break
    fi

    retry_count=$((retry_count + 1))
    echo "Waiting for database... attempt $retry_count/$max_retries"
    sleep 2
done

if [ $retry_count -eq $max_retries ]; then
    echo "Error: Could not connect to PostgreSQL after $max_retries attempts"
    exit 1
fi

python3 manage.py migrate

exec "$@"
