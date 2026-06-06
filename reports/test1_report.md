# Test 1: No Index V/S Index

### Test Objective

The objective of this experiment is to evaluate the impact of an **index** on query performance in PostgreSQL.

We want to measure:

- How PostgreSQL executes a lookup query without an index.
- How the execution plan changes after creating an index.
- The reduction in execution time.
- The reduction in the number of rows scanned.

This experiment demonstrates one of the most fundamental database optimization techniques: **INDEXING**.

---

### Query (Without Index)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 5000;
```

### Result

<img src="../docs/screenshots/test1/Screenshot 2026-06-05 234938.png" width="800">

### Metrics

| Metric	| Value |
|------------|-----|
| Scan Type	| Parallel Seq Scan|
|Workers Launched	|2|
|Rows Returned	|8|
|Rows Removed by Filter |	333,331 (per worker)
|Planning Time	|2.169 ms
|Execution Time	|153.677 ms

### Analysis

Since no index existed on `customer_id`, PostgreSQL had no efficient way to locate matching records.

The database was forced to:

- Read the entire table.
- Evaluate each row.
- Apply the filter condition.
- Return matching rows.

This approach becomes increasingly expensive as table size grows.

---

### Create Index

```sql
CREATE INDEX idx_orders_customer_id
ON orders(customer_id);
```

After creating the index:

```sql
ANALYZE orders;
```

This updates PostgreSQL statistics and helps the optimizer choose the best execution plan.

---

### Query Re-run (With Index)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 5000;
```

### Result

<img src="../docs/screenshots/test1/Screenshot 2026-06-05 235057.png" width="800">

### Metrics

|Metric|	Value|
|---|---|
|Scan Type|	Bitmap Heap Scan
|Index Type |	Bitmap Index Scan
|Rows Returned |	8
|Heap Blocks Accessed | 	8
|Index Searches	 | 1
|Planning Time	| 0.118 ms
|Execution Time	| 0.082 ms

### Analysis

The index enabled PostgreSQL to:

- Search the index structure.
- Identify matching row locations.
- Retrieve only the required rows.

Instead of reading one million rows, PostgreSQL directly accessed the required records.

---

### Benchmark Comparison

| Metric |	Without Index |	With Index
|:-|:-|:-|
| Execution Plan |	Parallel Seq Scan |	Bitmap Index Scan
| Rows Returned |	8 |	8
| Rows Examined |	~1,000,000 |	8
| Planning Time |	2.169 ms |	0.118 ms
| Execution Time |	153.677 ms |	0.082 ms


---

### Performance Improvement

**Execution Time Improvement**

$$
\frac{153.677}{0.082} \approx 1874
$$

Result: **1874x** faster

**Row Access Reduction**

Before Index:
```
~1,000,000 rows scanned
```

After Index:
```
8 rows accessed
```

This represents an almost complete elimination of unnecessary row scanning.* faster

---

### Key Findings

1. **Indexes dramatically reduce lookup time for selective queries.**
    - Query execution dropped from 153.677 ms to 0.082 ms.
2. **PostgreSQL switched from a Parallel Sequential Scan to a Bitmap Index Scan.**
    - This indicates that the optimizer recognized the index as the cheaper access path.
3. **Only the required rows were fetched after indexing.**
    - The database no longer needed to inspect the entire table.
4. **Planning overhead also decreased.**
    - Planning time reduced from 2.169 ms to 0.118 ms.
5. **Indexing is most effective for highly selective predicates.**
    - Since only 8 rows matched the condition, the index provided a massive performance gain.