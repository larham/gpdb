#!/usr/bin/env bash
set -euxo pipefail

source /opt/gpdb/greenplum_path.sh

createdb testdb

psql -U gpadmin testdb -c "CREATE TABLE test_table (test_col1 int, text_col2 text);"
psql -U gpadmin testdb -c "INSERT INTO test_table VALUES (1,'val');"

OUTPUT=`psql -t -U gpadmin testdb -c "SELECT COUNT(*) FROM test_table" | tr -d '[:space:]'`
if [ "$OUTPUT" != "1" ]; then
    exit 1
fi

