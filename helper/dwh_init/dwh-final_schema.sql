CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CREATE SCHEMA FOR FINAL AREA
CREATE SCHEMA IF NOT EXISTS final AUTHORIZATION postgres;

--=========================FINAL SCHEMA================================

-- dim_date

DROP TABLE if exists final.dim_date;
CREATE TABLE final.dim_date
(
  date_id                  INT NOT null primary KEY,
  date_actual              DATE NOT NULL,
  day_suffix               VARCHAR(4) NOT NULL,
  day_name                 VARCHAR(9) NOT NULL,
  day_of_year              INT NOT NULL,
  week_of_month            INT NOT NULL,
  week_of_year             INT NOT NULL,
  week_of_year_iso         CHAR(10) NOT NULL,
  month_actual             INT NOT NULL,
  month_name               VARCHAR(9) NOT NULL,
  month_name_abbreviated   CHAR(3) NOT NULL,
  quarter_actual           INT NOT NULL,
  quarter_name             VARCHAR(9) NOT NULL,
  year_actual              INT NOT NULL,
  first_day_of_week        DATE NOT NULL,
  last_day_of_week         DATE NOT NULL,
  first_day_of_month       DATE NOT NULL,
  last_day_of_month        DATE NOT NULL,
  first_day_of_quarter     DATE NOT NULL,
  last_day_of_quarter      DATE NOT NULL,
  first_day_of_year        DATE NOT NULL,
  last_day_of_year         DATE NOT NULL,
  mmyyyy                   CHAR(6) NOT NULL,
  mmddyyyy                 CHAR(10) NOT NULL,
  weekend_indr             VARCHAR(20) NOT NULL
);

CREATE INDEX dim_date_date_actual_idx
  ON final.dim_date(date_actual);

----------------------------------------------------------------------------------------------

-- dim_customers
CREATE TABLE final.dim_customers (
    customer_id UUID UNIQUE NOT NULL,  
    customer_nk VARCHAR(40) NOT NULL, 
    customer_zip_code INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expired_at TIMESTAMP,  
    current_flag VARCHAR(10) DEFAULT 'current' CHECK (current_flag IN ('current', 'expired')),
    version_id SERIAL,  
    PRIMARY KEY (customer_id, version_id) 
);



----------------------------------------------------------------------------------------------

-- dim_sellers

CREATE TABLE final.dim_sellers (
    seller_id UUID UNIQUE NOT NULL,
    seller_nk VARCHAR(40) NOT NULL,
    seller_zip_code INTEGER,
    seller_city VARCHAR(100),
    seller_state VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expired_at TIMESTAMP,
    current_flag VARCHAR(10) DEFAULT 'current' CHECK (current_flag IN ('current', 'expired')),
    version_id SERIAL, 
    PRIMARY KEY (seller_id, version_id)  -- Composite primary key: seller_id and expired_at
);

----------------------------------------------------------------------------------------------

-- dim_products

CREATE TABLE final.dim_products (
    product_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_nk VARCHAR(40) NOT NULL,
    product_category_name text,
    product_category_name_english text,
    product_name_length real,
    product_description_length real,
    product_photos_qty real,
    product_weight_g real,
    product_length_cm real,
    product_height_cm real,
    product_width_cm real,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

----------------------------------------------------------------------------------------------

-- fct_orders

CREATE TABLE final.fct_orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_nk text NOT NULL,
    order_item_nk integer NOT NULL,
    -- Foreign Keys
    customer_id UUID,
    seller_id UUID,
    product_id UUID,
    -- Foreign Keys
    price real, 
    freight_value real,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Constraint
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES final.dim_customers(customer_id),
    CONSTRAINT fk_orders_seller FOREIGN KEY (seller_id) REFERENCES final.dim_sellers(seller_id),
    CONSTRAINT fk_orders_product FOREIGN KEY (product_id) REFERENCES final.dim_products(product_id)
);

CREATE INDEX idx_orders_customer ON final.fct_orders (customer_id);
CREATE INDEX idx_orders_seller ON final.fct_orders (seller_id);
CREATE INDEX idx_orders_product ON final.fct_orders (product_id);

----------------------------------------------------------------------------------------------

-- fct_reviews

CREATE TABLE final.fct_reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_nk text NOT NULL,
    order_nk text NOT NULL,
    customer_id UUID,
    sentiment VARCHAR(10),
    payment_type text,
    review_score integer,
    review_comment_title text,
    review_comment_message text,
    review_creation_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES final.dim_customers(customer_id)
);
----------------------------------------------------------------------------------------------

-- fct_sales_daily

CREATE TABLE final.fct_sales_daily (
    sales_daily_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date_id INT,
    product_id UUID,
    sales_quantity INT,
    sales_value NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sales_date FOREIGN KEY (date_id) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES final.dim_products(product_id)
);

----------------------------------------------------------------------------------------------

-- fct_delivery_performance

CREATE TABLE final.fct_delivery_performance (
    delivery_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_nk text NOT NULL,
    order_purchase_at INT,
    order_approved_at INT,
    shipping_limit_date INT,
    order_carrier_date INT,
    order_delivered_customer_date INT,
    order_estimated_delivery_date INT,
    order_status text,
    purchase_to_approval_days INTERVAL,
    approval_to_shipping_days INTERVAL,
    shipping_to_delivery_days INTERVAL,
    delivery_to_estimated_days INTERVAL,
    purchase_to_delivery_days INTERVAL,
    shipping_limit_to_carrier_days INTERVAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_purchase_at FOREIGN KEY (order_purchase_at) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_order_approved_at FOREIGN KEY (order_approved_at) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_shipping_limit_date FOREIGN KEY (shipping_limit_date) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_order_carrier_date FOREIGN KEY (order_carrier_date) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_order_delivered_customer_date FOREIGN KEY (order_delivered_customer_date) REFERENCES final.dim_date(date_id),
    CONSTRAINT fk_order_estimated_delivery_date FOREIGN KEY (order_estimated_delivery_date) REFERENCES final.dim_date(date_id)
);

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- populate date dimension
INSERT INTO final.dim_date
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS date_id,
       datum AS date_actual,
       TO_CHAR(datum, 'fmDDth') AS day_suffix,
       TO_CHAR(datum, 'TMDay') AS day_name,
       EXTRACT(DOY FROM datum) AS day_of_year,
       TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum) AS week_of_year,
       EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW') AS week_of_year_iso,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum, 'TMMonth') AS month_name,
       TO_CHAR(datum, 'Mon') AS month_name_abbreviated,
       EXTRACT(QUARTER FROM datum) AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
           END AS quarter_name,
       EXTRACT(YEAR FROM datum) AS year_actual,
       datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
       datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(datum, 'mmyyyy') AS mmyyyy,
       TO_CHAR(datum, 'mmddyyyy') AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN 'weekend'
           ELSE 'weekday'
           END AS weekend_indr
FROM (SELECT '1998-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 29219) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

-- Add Unique Constraints to fact tables

ALTER TABLE final.fct_orders
ADD CONSTRAINT fct_orders_unique UNIQUE (order_nk, order_item_nk);

ALTER TABLE final.fct_reviews
ADD CONSTRAINT fct_reviews_unique UNIQUE (review_nk, order_nk);

ALTER TABLE final.fct_delivery_performance
ADD CONSTRAINT fct_delivery_performance_unique UNIQUE (order_nk);

ALTER TABLE final.fct_sales_daily
ADD CONSTRAINT fct_sales_daily_unique UNIQUE (date_id, product_id);
