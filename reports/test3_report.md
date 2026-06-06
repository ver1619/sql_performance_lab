# Test 3: Join Optimization

### Test Objective

The objective of this experiment is to analyze how PostgreSQL executes joins on large datasets and to evaluate the impact of indexing on join performance.

This test aims to:

- Observe the join strategy selected by PostgreSQL.
- Measure execution time before and after indexing.
- Understand when indexes are beneficial in join operations.
- Study PostgreSQL's query planner behavior.

---

### Query (Without Index)

```sql
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.name,
    o.order_id
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE c.city = 'Bangalore';
```

### Result

<img src="../docs/screenshots/test3/Screenshot 2026-06-06 004854.png" width="800">

### Metrics

|Metric | Value |
|---|--|
|Join Type |Hash Join|
|Customer Rows Scanned |100,000|
|Orders Rows Scanned |1,000,000|
|Matching Customers |16,693|
|Rows Returned |166,717|
|Planning Time |5.960 ms|
|Execution Time |178.638 ms|

---

### Analysis

Execution flow:

1. PostgreSQL scanned all customers.
2. Applied the filter: `city = 'Bangalore'`
3. Created a hash table containing matching customer IDs.
4. Scanned all one million orders.
5. Matched rows using hash lookups.

Although the query returned a large result set efficiently, PostgreSQL still needed to perform full-table scans.

---

### Create Indexes

City Filter Index

```sql
CREATE INDEX idx_customers_city
ON customers(city);
```

Join Column Index
```sql
CREATE INDEX idx_orders_customer
ON orders(customer_id);
```

Update statistics:
```
ANALYZE customers;
ANALYZE orders;
```

---

### Query Re-run (With Index)

```sql
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.name,
    o.order_id
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE c.city = 'Bangalore';
```

### Result

<img src="../docs/screenshots/test3/Screenshot 2026-06-06 005411.png" width="800">

### Metrics

|Metric | Value |
|---|---|
|Join Type |Hash Join|
|Customer Access Method |Bitmap Index Scan|
|Orders Access Method |Seq Scan|
|Matching Customers |16,693|
|Rows Returned |166,717|
|Planning Time |0.278 ms|
|Execution Time |146.870 ms|

---

### Analysis

PostgreSQL used:
```sql
idx_customers_city
```
to quickly locate Bangalore customers.

Execution flow:

1. Index lookup retrieves Bangalore customers.
2. Hash table is created from filtered customers.
3. Entire orders table is scanned.
4. Hash join is performed.

Notice:
```sql
Bitmap Index Scan on idx_customers_city
```
This significantly reduced customer filtering cost.

However:
```sql
Seq Scan on orders
```
was still chosen.

---

### Why Was idx_orders_customer Not Used?

This is the most important observation of the experiment.

Although an index existed on:

```sql
orders(customer_id)
```

PostgreSQL deliberately chose not to use it.

Reason:

- The query ultimately returns 166,717 rows.
- A large percentage of the orders table participates in the join.
- Sequential scanning one million rows is cheaper than performing thousands of index lookups and heap fetches.

This demonstrates PostgreSQL's cost-based optimization.

---

### Benchmark Comparison

|Metric |Before Indexes |After Indexes |
|---|---|---|
|Join Type |Hash Join|Hash Join|
|Customer Access |Seq Scan|Bitmap Index Scan|
|Orders Access |Seq Scan|Seq Scan|
|Planning Time |5.960 ms|0.278 ms|
|Execution Time |178.638 ms|146.870 ms|
|Rows Returned	| 166,717	| 166,717 |

---

### Performance Improvement

#### Execution Time Improvement

$$
\frac{178.638}{146.870} \approx 1.22
$$


Result: **~1.22×** faster

#### Planning Time Improvement

$$
\frac{5.960}{0.278} \approx 21.4
$$


Result: **~21×** faster planning

---

### Key Findings

1. **PostgreSQL selected a Hash Join in both scenarios.**
    - Hash Join was the most efficient strategy for this workload.
2. **The city index improved customer filtering performance.**
    - Customer retrieval changed from Sequential Scan to Bitmap Index Scan.
3. **The orders(customer_id) index was not used.**
    - PostgreSQL determined that a Sequential Scan was cheaper for processing a large portion of the table.
4. **Indexes do not guarantee usage.**
    - PostgreSQL chooses indexes only when they reduce overall query cost.
5. **Query selectivity determines index effectiveness.**
    - Since the join returned over 166,000 rows, scanning the orders table remained the optimal strategy.