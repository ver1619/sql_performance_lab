INSERT INTO orders
SELECT
    gs,
    floor(random()*100000 + 1)::BIGINT,
    DATE '2024-01-01'
        + floor(random()*1095)::INT,
    (
        ARRAY[
            'PENDING',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED'
        ]
    )[floor(random()*4 + 1)]
FROM generate_series(1,1000000) gs;