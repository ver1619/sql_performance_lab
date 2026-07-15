# Test 11: Index Storage Analysis

### Objective

- Analyze the storage overhead introduced by indexes
- Evaluate whether the storage consumed was justified by the performance improvements observed in previous tests

This test focuses on the cost side of optimization by measuring:

- Table storage
- Index storage
- Total relation size
- Storage efficiency of indexes

---

### Table Size 

Query:
```sql
SELECT
    relname AS table_name,
    pg_size_pretty(pg_relation_size(relid)) AS table_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_relation_size(relid) DESC;
```

<img src="../docs/screenshots/test11/tables_size.png" width="600">

---

### Index Size Per Table

Query:
```sql
SELECT
    relname AS table_name,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_indexes_size(relid) DESC;
```

<img src="../docs/screenshots/test11/index_size_per_table.png" width="600">

---

### Total Relation Size

Query:
```sql
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

<img src="../docs/screenshots/test11/total_size.png" width="600">

---

### Individual Index Size

Query:
```sql
SELECT
    indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

<img src="../docs/screenshots/test11/size_per_index.png" width="600">

---

### Overview

|Table	|Table Size|	Index Size|	Total Size| 
|---|---|---|---|
|`orders`	|57 MB|	61 MB|	118 MB|
|`customers`	|9440 kB|	2904 kB|	12 MB|
|`order_items`	|326 MB|	107 MB|	433 MB|
|`products`	|672 kB|	240 kB|	944 kB|

---

### Index Report on Tests

Reference: Previous benchmark reports

|Index	|Test	|Execution Time before Index| Execution Time after Index| Time Saved |Index Size|Performance Gain (ms/MB)
|---|---|---|---|---|---|---|
|`idx_orders_customer_id`|	Test 1| 153.677 ms|0.082 ms|153.595 ms|9088 kB ~ 8.875 MB|17.31 ms/MB
|`idx_orders_customer_status`|Test 2|68.213 ms|0.066 ms|68.147 ms|20 MB|3.41 ms/MB
|`idx_orders_customer_id`, `idx_customers_city`|Test 3|178.638 ms|146.870 ms|31.768 ms|9764 kB ~ 9.54 MB|3.33 ms/MB
|`idx_delivered_orders`|Test 8|0.700 ms|0.059 ms|0.641 ms|3832 kB ~ 3.74 MB|0.17 ms/MB
|`idx_orders_order_date_brin`|Test 9|340.170 ms|255.954 ms|84.216 ms|24 kB ~ 0.023 MB|3598.97 ms/MB
|`idx_orders_order_date_btree`|Test 9|340.170 ms|117.257 ms|222.913 ms|7088 kB ~ 6.92 MB|32.21 ms/MB


---

### Most Efficient Index


|Index	|Size	|Performance Gain|
|---|---|---|
|`idx_orders_order_date_brin`	|24 kB (~0.023 MB)	|3598.97 ms/MB|

**why?**

- Extremely small storage footprint.
- BRIN stores metadata summaries of page ranges instead of indexing every row.
- Achieves meaningful query acceleration while consuming virtually no disk space.
- Highest performance gain per MB among all indexes by a large margin.

`idx_orders_order_date_brin` is the most storage-efficient index because it delivers substantial performance improvement with negligible storage cost.

---

### Least Efficient Index


|Index|	Size|	Performance Gain|
|---|---|---|
|`idx_delivered_orders`|	3832 kB (~3.74 MB)|	0.17 ms/MB|

**Why?**

- Consumes several MB of storage.
- Query was already very fast (0.700 ms) before indexing.
- Only saved 0.641 ms of execution time.
- Marginal improvement relative to storage consumed.

`idx_delivered_orders` is the least storage-efficient index because it occupies multiple megabytes while providing only a minor reduction in execution time.

---

### Best Performance 

|Index	|Actual Query Time without index|Time Saved	|
|---|---|---|
|`idx_orders_order_date_btree`	|340.170 ms|222.913 ms|

**Why?**

- Produces the largest reduction in execution time.
- Reduces query latency by ~65%.
- `idx_orders_order_date_brin` is more storage-efficient, but `idx_orders_order_date_btree` provides better performance.
- Best choice when query speed is more important than storage consumption.

---

### Key Findings

- Query-specific indexes (`single`, `composite`, and `partial`) consistently delivered greater benefits than general-purpose indexing strategies.
- Index effectiveness depended more on query selectivity and predicate alignment than on index size.
- `B-Tree` indexes provided the strongest execution-time improvements, while BRIN indexes offered the highest storage efficiency.
- `Composite indexes` were most effective when query predicates matched the indexed column order, reducing additional filtering overhead.
- `Join-heavy` workloads benefited less from indexing than filter-heavy workloads because join processing remained a significant portion of total execution cost.
- Workload-aware index design proved more effective than applying a uniform indexing strategy across all queries.