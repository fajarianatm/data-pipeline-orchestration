CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CREATE SCHEMA FOR STAGING
CREATE SCHEMA IF NOT EXISTS stg;

------------------------------------------------------------------

CREATE TABLE stg.customers (
    id uuid default uuid_generate_v4(),
    customer_id text NOT NULL,
    customer_unique_id text,
    customer_zip_code_prefix integer,
    customer_city text,
    customer_state text,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);

ALTER TABLE stg.customers OWNER TO postgres;
GRANT ALL ON TABLE stg.customers TO postgres;

------------------------------------------------------------------

CREATE TABLE stg.sellers (
    id uuid default uuid_generate_v4(),
    seller_id text NOT NULL,
    seller_zip_code_prefix integer,
    seller_city text,
    seller_state text,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sellers PRIMARY KEY (seller_id)
);


ALTER TABLE stg.sellers OWNER TO postgres;
GRANT ALL ON TABLE stg.sellers TO postgres;

----------------------------------------------------------------------------------

--
-- Name: product_category_name_translation; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.product_category_name_translation (
    id uuid default uuid_generate_v4(),
    product_category_name text NOT NULL,
    product_category_name_english text,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_product_category_name_translation PRIMARY KEY (product_category_name)
);


ALTER TABLE stg.product_category_name_translation OWNER TO postgres;
GRANT ALL ON TABLE stg.product_category_name_translation TO postgres;

----------------------------------------------------------------------------------

--
-- Name: products; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.products (
    id uuid default uuid_generate_v4(),
    product_id text NOT NULL,
    product_category_name text,
    product_name_length real,
    product_description_length real,
    product_photos_qty real,
    product_weight_g real,
    product_length_cm real,
    product_height_cm real,
    product_width_cm real,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT fk_products_product_category FOREIGN KEY (product_category_name) REFERENCES stg.product_category_name_translation(product_category_name)
);


ALTER TABLE stg.products OWNER TO postgres;
GRANT ALL ON TABLE stg.products TO postgres;

----------------------------------------------------------------------------------

--
-- Name: orders; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.orders (
    id uuid default uuid_generate_v4(),
    order_id text NOT NULL,
    customer_id text,
    order_status text,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES stg.customers(customer_id)
);


ALTER TABLE stg.orders OWNER TO postgres;
GRANT ALL ON TABLE stg.orders TO postgres;

----------------------------------------------------------------------------------

--
-- Name: order_items; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.order_items (
    id uuid default uuid_generate_v4(),
    order_id text NOT NULL,
    order_item_id integer NOT NULL,
    product_id text,
    seller_id text,
    shipping_limit_date TIMESTAMP,
    price real,
    freight_value real,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES stg.orders(order_id),
    CONSTRAINT fk_order_items_products FOREIGN KEY (product_id) REFERENCES stg.products(product_id),
    CONSTRAINT fk_order_items_sellers FOREIGN KEY (seller_id) REFERENCES stg.sellers(seller_id)
);


ALTER TABLE stg.order_items OWNER TO postgres;
GRANT ALL ON TABLE stg.order_items TO postgres;

----------------------------------------------------------------------------------

--
-- Name: order_payments; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.order_payments (
    id uuid default uuid_generate_v4(),
    order_id text NOT NULL,
    payment_sequential integer NOT NULL,
    payment_type text,
    payment_installments integer,
    payment_value real,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_order_payments_orders FOREIGN KEY (order_id) REFERENCES stg.orders(order_id)
);


ALTER TABLE stg.order_payments OWNER TO postgres;
GRANT ALL ON TABLE stg.order_payments TO postgres;

----------------------------------------------------------------------------------

--
-- Name: order_reviews; Type: TABLE; Schema: stg; Owner: postgres
--

CREATE TABLE stg.order_reviews (
    id uuid default uuid_generate_v4(),
    review_id text NOT NULL,
    order_id text NOT NULL,
    review_score integer,
    review_comment_title text,
    review_comment_message text,
    review_creation_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id),
    CONSTRAINT fk_order_reviews_orders FOREIGN KEY (order_id) REFERENCES stg.orders(order_id)
);


ALTER TABLE stg.order_reviews OWNER TO postgres;
GRANT ALL ON TABLE stg.order_reviews TO postgres;

----------------------------------------------------------------------------------