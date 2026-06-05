ALTER TABLE customers
ADD CONSTRAINT pk_customers
PRIMARY KEY (customer_id);

ALTER TABLE products
ADD CONSTRAINT pk_products
PRIMARY KEY (product_id);

ALTER TABLE orders
ADD CONSTRAINT pk_orders
PRIMARY KEY (order_id);

ALTER TABLE order_items
ADD CONSTRAINT pk_order_items
PRIMARY KEY (order_item_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE products
ADD CONSTRAINT chk_price
CHECK (price > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_quantity
CHECK (quantity > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_amount
CHECK (amount > 0);