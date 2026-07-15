# Test 5: Partitioning and Partition Pruning

### Test Objective

The objective of this experiment is to evaluate the impact of table partitioning on query performance for date-based filtering.

Specifically, this test aims to:

- Compare query execution before and after partitioning.
- Observe PostgreSQL's partition pruning behavior.
- Measure reduction in scanned data.
- Analyze execution time and buffer usage improvements.

This experiment demonstrates how partitioning can reduce unnecessary I/O and improve performance for large tables.

---

### Query (Before Partitioning)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_date BETWEEN '2026-01-01'
                     AND '2026-12-31';
```

### Result

<img src="../docs/screenshots/test5/Screenshot 2026-06-06 012504.png" width="800">

### Metrics

|Metric|	Value |
|---|---|
|Access Method|	Seq Scan|
|Rows Returned|	331,680|
|Rows Removed by Filter|	668,320|
|Buffers|	7,353|
|Planning Time|	0.280 ms|
|Execution Time|	283.966 ms|

---

### PostgreSQL scanned the entire orders table.

Execution flow:

1. Read all 1,000,000 rows.
2. Apply the date filter.
3. Discard rows outside the specified range.
4. Return matching rows.

Evidence:
```sql
Rows Removed by Filter: 668320
```
This indicates that approximately two-thirds of the table was scanned unnecessarily.

---

### Create Partitioned Table

#### Parent Table

```sql
CREATE TABLE orders_partitioned (
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    status VARCHAR(20)
)
PARTITION BY RANGE (order_date);
```

#### Yearly Partitions

```sql
CREATE TABLE orders_2024
PARTITION OF orders_partitioned
FOR VALUES FROM ('2024-01-01')
TO ('2025-01-01');

CREATE TABLE orders_2025
PARTITION OF orders_partitioned
FOR VALUES FROM ('2025-01-01')
TO ('2026-01-01');

CREATE TABLE orders_2026
PARTITION OF orders_partitioned
FOR VALUES FROM ('2026-01-01')
TO ('2027-01-01');
```

#### Load Data

```sql
INSERT INTO orders_partitioned
SELECT *
FROM orders;
```

#### Update statistics:

```sql
ANALYZE orders_partitioned;
```

---

### Query on Partitioned Table

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders_partitioned
WHERE order_date BETWEEN '2026-01-01'
                     AND '2026-12-31';
```

### Result

<img src="../docs/screenshots/test5/Screenshot 2026-06-06 013009.png" width="800">

### Metrics

|Metric	|Value|
|---|---|
|Access Method	|Seq Scan
|Partition Accessed|	orders_2026
|Rows Returned|	331,680
|Buffers	|2,439
|Planning Time	|0.170 ms
|Execution Time|	89.824 ms


---

### Analysis

PostgreSQL accessed only:
```sql
orders_2026
```
The other partitions were completely skipped.

This behavior is known as **Partition Pruning**.

Execution flow:

1. PostgreSQL examines the filter condition.
2. Determines only the 2026 partition contains matching rows.
3. Skips partitions for 2024 and 2025.
4. Scans only the relevant partition.

---

### Evidence of Partition Pruning

**Before**
```sql
Seq Scan on orders
```
Entire table scanned.

**After**
```sql
Seq Scan on orders_2026
```
Only one partition scanned.

If pruning had not occurred, the execution plan would have contained:

```sql
Append
 ├── orders_2024
 ├── orders_2025
 └── orders_2026
```
Since only orders_2026 appears, PostgreSQL successfully pruned the other partitions.

---

### Benchmark Comparison

|Metric|Before Partitioning|After Partitioning
|---|---|---
|Table Accessed|orders|orders_2026
|Rows Returned|331,680|331,680
|Rows Removed by Filter|668,320|0
|Buffers|7,353|2,439
|Planning Time|0.280 ms|0.170 ms
|Execution Time|283.966 ms|89.824 ms

---

### Performance Improvements

#### Execution Time Improvement

$$
\frac{283.966}{89.824} \approx 3.16
$$

Result: **~3.16×** faster

#### Buffer Reduction

$$
\frac{7353}{2439} \approx 3.01
$$

Result: **~3×** fewer buffer accesses

---

### Data Scanned Reduction

Before:
```sql
1,000,000 rows scanned
```
After:
```sql
331,680 rows scanned
```
Approximately **66.8%** less data processed.

---

### Key Findings

1. **Partition pruning significantly reduced query execution time.**
    - Execution time improved from 283.966 ms to 89.824 ms.
2. **Only the relevant partition was scanned.**
    - PostgreSQL skipped partitions containing unrelated data.
3. **Buffer usage decreased by approximately 3×.**
    - Less data needed to be loaded into memory.
4. **Partitioning reduced unnecessary row processing.**
    - Rows outside the requested date range were never scanned.
5. **Partitioning improves scalability for time-series workloads.**
    - As data volume grows, partition pruning becomes increasingly valuable