# Test 6: Buffer Usage with EXPLAIN (ANALYZE, BUFFERS)

### Objective

The goal is to analyze:
- How many memory pages PostgreSQL accesses.
- How much data is retrieved from cache versus disk.
- How indexing affects I/O activity.
- Why execution time alone is not sufficient for performance analysis.

**Note**: <br>
In previous experiments, query performance was evaluated primarily using `execution time` and `execution plans`.

This experiment introduces PostgreSQL `buffer statistics` to understand the amount of work performed internally during query execution.

---

### Query

Check whether there is an index on the `customer_id` column. if yes:
```sql
DROP INDEX IF EXISTS idx_orders_customer_id;
```

Then run the following query:

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * 
FROM orders 
WHERE customer_id = 5000;
```

### Result:
<img src="../docs/screenshots/test6/no_index_buffers.png" width="800">

### Metrics
|Metric	|Value|
|---|---|
|Scan Type	|Parallel Seq Scan
|Execution Time|	130.285 ms
|Planning Time|	1.299 ms
|Shared Hits	|733
|Shared Reads	|6620

### Analysis

Without an index, PostgreSQL has no direct path to locate rows matching the filter condition.

As a result:
1. The entire table is scanned.
2. A large number of data pages are accessed.
3. More memory and I/O resources are consumed.
4. Query execution becomes increasingly expensive as table size grows.

---

### Create Index

```sql
CREATE INDEX idx_orders_customer_id 
ON orders(customer_id);
```

Update statistics:
```
ANALYZE orders;
```

### Query Re-run

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 5000;
```

### Result

<img src="../docs/screenshots/test6/with_index_buffers.png" width="800">

### Metrics

|Metric	|Value|
|---|---|
|Scan Type	|Bitmap Index + Heap Scan
|Execution Time	|0.078 ms
|Planning Time	|0.133 ms
|Shared Hits	|11
|Shared Reads	|0

### Analysis

The index allows PostgreSQL to:
1. Search the index structure.
2. Locate matching row locations.
3. Retrieve only the required records.

Instead of scanning the entire table, PostgreSQL accesses a much smaller portion of the dataset.

This reduces both latency and resource consumption.

---

### Benchmark Comparison

|Metric	|Without Index|	With Index|
|---|---|---|
|Scan Type	|Parallel Seq Scan|	Bitmap Index + Heap Scan|
|Execution Time	|130.285 ms|	0.078 ms|
|Planning Time	|1.299 ms|	0.133 ms|
|Shared Hits	|733|	11|
|Shared Reads	|6620|	0|

---

### Understanding Buffer Metrics

**Shared Hits**

Shared Hits represent pages that PostgreSQL found in memory.

Example:
```sql
Buffers: shared hit=100
```
This means PostgreSQL was able to retrieve data directly from its shared buffer cache without reading from disk.

Higher shared hits generally indicate efficient cache utilization.

**Shared Reads**

Shared Reads represent pages PostgreSQL had to load from disk.

Example:
```sql
Buffers: shared read=100
```
This means PostgreSQL needed to perform physical I/O operations to retrieve data.

Disk reads are significantly more expensive than memory accesses.

---

### Key Findings
1. Execution time alone does not fully describe query efficiency.
2. Buffer statistics reveal how much work PostgreSQL performs internally.
3. Indexes reduce the number of data pages that must be accessed.
4. Lower buffer usage typically results in lower memory pressure and reduced I/O activity.
5. Queries that touch fewer pages generally scale better as data volume grows.