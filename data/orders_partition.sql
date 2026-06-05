CREATE TABLE orders_partitioned (
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    status VARCHAR(20)
)
PARTITION BY RANGE (order_date);

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

INSERT INTO orders_partitioned
SELECT *
FROM orders;