# Test 2: Single Index vs Composite Index

### Test Objective

The objective of this experiment is to compare the effectiveness of:

- No Index
- Single-Column Index
- Composite Index

for a query containing multiple filtering conditions.

This experiment helps answer:

- Does a single-column index improve performance?
- Does a composite index provide additional benefits?
- How does PostgreSQL modify its execution plan as indexes become more specific?

---

### Query (Without Index)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 5000
  AND status = 'DELIVERED';
```

### Result

<img src="../docs/screenshots/test2/Screenshot 2026-06-06 004153.png" width="800">

### Metrics

| Metric |	Value |
|---|---|
| Scan Type |	Parallel Seq Scan |
| Workers Launched |	2 |
| Rows Returned |	0 |
| Rows Removed by Filter |	333,333 (per worker)|
| Planning Time |	1.314 ms |
| Execution Time |	68.213 ms |

---

### Analysis

Without an index, PostgreSQL had to inspect every row in the table. Both conditions were evaluated row by row.

The optimizer had no efficient path to locate records matching:

```sql
customer_id = 5000
AND status = 'DELIVERED'
```

---

### Create Single-Column Index

```sql
CREATE INDEX idx_orders_customer
ON orders(customer_id);
```

Update statistics:

```
ANALYZE orders;
```

---

### Query Re-run (Single Index)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 5000
  AND status = 'DELIVERED';
```

### Result

<img src="../docs/screenshots/test2/Screenshot 2026-06-06 004338.png" width="800">

### Metrics 

| Metric |	Value |
|---|---|
| Scan Type | Bitmap Heap Scan |
Index Type | Bitmap Index Scan |
Rows Returned | 0 |
Rows Removed by Filter | 8 |
Index Searches | 1 |
Planning Time | 0.226 ms |
Execution Time | 0.106 ms |

### Analysis

The index efficiently located rows where:

```sql
customer_id = 5000
```

However, PostgreSQL still needed to evaluate:

```sql
status = 'DELIVERED'
```
after retrieving rows.

Evidence:

```sql
Rows Removed by Filter: 8
```

The index helped with customer_id, but not with status.

---

### Create Composite Index

Remove the previous index:
```sql
DROP INDEX idx_orders_customer;
```
Create a composite index:

```sql
CREATE INDEX idx_orders_customer_status
ON orders(customer_id, status);
```

Update statistics:
```sql
ANALYZE orders;
```

---

### Query Re-run (Composite Index)

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 5000
  AND status = 'DELIVERED';
```

### Result

<img src="../docs/screenshots/test2/Screenshot 2026-06-06 004516.png" width="800">

### Metrics

| Metric | Value |
|---|---|
| Scan Type | Bitmap Heap Scan |
| Index Type | Bitmap Index Scan |
| Rows Returned | 0 |
| Rows Removed by Filter | 0 |
| Index Searches | 1 |
| Planning Time | 0.128 ms |
| Execution Time | 0.066 ms |

---

### Analysis

The composite index contains:
```sql
(customer_id, status)
```
Therefore PostgreSQL can evaluate:
```sql
customer_id = 5000
AND status = 'DELIVERED'
```
inside the index itself.

Notice the execution plan:

```sql
Index Cond:
(customer_id = 5000)
AND
(status = 'DELIVERED')
```

No additional filtering step is required.

---

### Benchmark Comparision

| Metric | No Index | Single Index | Composite Index |
|---|---|---|---|
| Execution Plan | Parallel Seq Scan | Bitmap Index Scan | Bitmap Index Scan |
| Planning Time | 1.314 ms | 0.226 ms | 0.128 ms |
| Execution Time | 68.213 ms | 0.106 ms | 0.066 ms |
| Rows Returned | 0 | 0 | 0 |
| Rows Removed by Filter | 333,333+ | 8 | 0 |

**NOTE** : `Rows returned` = 0 because there were no rows in the **orders** table corresponding to the **WHERE** clause.

---

### Performance Measurement

#### Single Index vs No Index

$$
\frac{68.213}{0.106} \approx 644
$$

Result: **~644×** faster

#### Composite Index vs No Index

$$
\frac{68.213}{0.066} \approx 1034
$$

Result: **~1034×** faster

#### Composite Index vs Single Index

$$
\frac{0.106}{0.066} \approx 1.6
$$

Result: **~1.6×** faster

---

### Key Findings

1. **A single-column index dramatically improved performance.**
    - Execution time decreased from 68.213 ms to 0.106 ms.
2. **The single index optimized only one predicate.**
    - PostgreSQL still applied the status filter after row retrieval.
3. **The composite index optimized both predicates simultaneously.**
    - Both conditions became part of the index lookup process.
4. **The composite index eliminated post-retrieval filtering.**
    - Rows Removed by Filter decreased from 8 to 0.
5. **The additional gain from the composite index was modest.**
    - Because customer_id was already highly selective, only a few rows remained to be filtered.