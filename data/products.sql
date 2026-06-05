INSERT INTO products
SELECT
    gs,
    'Product_' || gs,
    (
        ARRAY[
            'Electronics',
            'Books',
            'Clothing',
            'Sports',
            'Home'
        ]
    )[floor(random()*5 + 1)],
    ROUND((100 + random()*9900)::numeric,2)
FROM generate_series(1,10000) gs;