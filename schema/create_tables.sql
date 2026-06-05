CREATE TABLE customers (
    customer_id BIGINT,
    name VARCHAR(100),
    email VARCHAR(255),
    city VARCHAR(100),
    created_at TIMESTAMP
);

CREATE TABLE products (
    product_id BIGINT,
    product_name VARCHAR(255),
    category VARCHAR(100),
    price NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE order_items (
    order_item_id BIGINT,
    order_id BIGINT,
    product_id BIGINT,
    quantity INTEGER,
    amount NUMERIC(12,2)
);