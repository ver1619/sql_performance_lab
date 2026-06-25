EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 1000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 1000
AND status = 'DELIVERED';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM customer_spending_mview;

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
);

EXPLAIN ANALYZE
SELECT *
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.name,
    o.order_id
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE c.city = 'Bangalore';