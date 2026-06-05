INSERT INTO customers
SELECT
    gs,
    'Customer_' || gs,
    'customer' || gs || '@example.com',
    (
        ARRAY[
            'Bangalore',
            'Mumbai',
            'Delhi',
            'Chennai',
            'Hyderabad',
            'Pune'
        ]
    )[floor(random()*6 + 1)],
    NOW() - (random() * interval '1000 days')
FROM generate_series(1,100000) gs;