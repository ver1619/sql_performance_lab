INSERT INTO order_items
SELECT
    gs,
    floor(random()*1000000 + 1)::BIGINT,
    floor(random()*10000 + 1)::BIGINT,
    floor(random()*10 + 1)::INT,
    ROUND((random()*10000 + 100)::numeric,2)
FROM generate_series(1,5000000) gs;