#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Your SQL commands will be executed by psql.
    -- You can add initialization logic here if needed beyond the .sql files.
    SELECT 'Running initialization scripts...';
EOSQL

# The docker-entrypoint for postgres will automatically run any .sql files
# in this directory. This script is here for potential future use or complex logic.
# For now, it just confirms that it's running.