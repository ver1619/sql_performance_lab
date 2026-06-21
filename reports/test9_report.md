# Test 9: BRIN vs B-Tree Indexes

**Note**:<br>
PostgreSQL provides multiple index types designed for different workloads.

In previous experiments, only traditional B-Tree indexes were used. While B-Tree indexes are highly effective for many queries, PostgreSQL also offers BRIN (Block Range Indexes) for large tables where data is naturally ordered.

### Objective

- Compare BRIN and B-Tree indexes.
- Observe PostgreSQL's index selection behavior.
- Analyze execution plans and buffer usage.
- Compare query performance across different index types.
- Understand when BRIN indexes may be preferred over B-Tree indexes.

---

### No Index

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * 
FROM orders 
WHERE order_date BETWEEN 
'2026-01-01' 
AND 
'2026-12-31';
```

### Result

<img src="../docs/screenshots/test9/no_index.png" width="800">

### Metrics

|Metric|	Value|
|---|---|
|Scan Type	|Sequential Scan|
|Execution Time	|340.170 ms|
|Planning Time	|28.050 ms|
|Shared Hits	|0|
|Shared Reads	|7353|
|Rows Returned	|331680|

### Analysis

- PostgreSQL performs a Sequential Scan.
- Every row in the table is examined.
- A large number of pages are accessed.
- Buffer activity is high.

---

### BRIN Index

**Block Range Index**

Create BRIN Index:

```sql
CREATE INDEX idx_orders_order_date_brin
ON orders 
USING BRIN (order_date);
```

Update statistics:
```
ANALYZE orders;
```

Re-run the same query

### Result

<img src="../docs/screenshots/test9/brin_index.png" width="800">

### Metrics

|Metric|	Value|
|---|---|
|Scan Type|	Sequential Scan
|Execution Time|	255.954 ms
|Planning Time|	0.247 ms
|Shared Hits|	726
|Shared Reads|	6627
|Rows Returned|	331680

### Analysis

- PostgreSQL uses the BRIN index.
- Relevant block ranges are identified before row access.
- Fewer pages are processed compared to a full table scan.
- Buffer activity decreases.

---

### B-Tree Index

Remove BRIN:
```sql
DROP INDEX idx_orders_order_date_brin;
```

Create B-Tree:
```sql
CREATE INDEX idx_orders_order_date_btree 
ON orders(order_date);
```

Update statistics:

```sql
ANALYZE orders;
```

Re-run the query.

### Result

<img src="../docs/screenshots/test9/btree_index.png" width="800">

### Metrics

Metric	Value
|Metric|Value|
|---|---|
|Scan Type|Bitmap Heap Scan|
|Execution Time|117.257 ms|
|Planning Time|0.236 ms|
|Shared Hits|7647|
|Shared Reads|0|
|Rows Returned|331680|

### Analysis

- PostgreSQL uses the B-Tree index.
- Matching rows are located more precisely.
- Buffer activity is reduced.
- Query execution improves compared to a Sequential Scan.

---

### Benchmark Comparison

|Metric|	No Index|	BRIN|	B-Tree|
|---|---|---|---|
|Scan Type|	Sequential Scan|	Sequential Scan|	Bitmap Heap Scan|
|Execution Time|	340.170 ms|	255.954 ms|	117.257 ms|
|Planning Time|	28.050 ms|	0.247 ms|	0.236 ms|
|Shared Hits|	0|	726|	7647|
|Shared Reads	|7353|	6627|	0|
|Rows Returned|	331680|	331680|	331680|

---

### Performance Comparision

**BRIN vs No Index**

$$
\frac{340.170}{255.954} \approx 1.33
$$

Result: BRIN index improves query performance by approximately **1.33x**.

**B-Tree vs BRIN**

$$
\frac{255.954}{117.257} \approx 2.18
$$

Result: B-Tree index improves query performance by approximately **2.18x**.

**B-Tree vs No Index**

$$
\frac{340.170}{117.257} \approx 2.90
$$

Result: B-Tree index improves query performance by approximately **2.90x**.

---

### Key Findings

- PostgreSQL supports multiple index types optimized for different workloads.
- Both BRIN and B-Tree indexes reduce the amount of work performed compared to a Sequential Scan.
- BRIN indexes help PostgreSQL identify relevant data ranges before accessing rows.
- B-Tree indexes provide more precise row access and are often chosen for highly selective queries.
- Query performance depends not only on the presence of an index but also on the index type and workload characteristics.