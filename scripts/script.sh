#!/bin/bash

DB_NAME=#e.g, performance_lab
DB_USER=#e.g, postgres/user
DB_HOST=#e.g, localhost
DB_PORT=#e.g, 5432

OUTPUT_FILE="scripts/results.txt"

echo "===================================="
echo " PostgreSQL Benchmark Runner"
echo "===================================="

echo "[1/3] Running benchmark queries..."

echo "Benchmark Started: $(date)" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

psql \
-h "$DB_HOST" \
-p "$DB_PORT" \
-U "$DB_USER" \
-d "$DB_NAME" \
-f scripts/benchmark_queries.sql \
>> "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "[2/3] Queries executed successfully."
else
    echo "[ERROR] Query execution failed."
    exit 1
fi

echo "" >> "$OUTPUT_FILE"
echo "Benchmark Completed: $(date)" >> "$OUTPUT_FILE"

echo "[3/3] Results saved."
echo ""
echo "Output File: $OUTPUT_FILE"
echo ""
echo "Benchmark completed successfully."