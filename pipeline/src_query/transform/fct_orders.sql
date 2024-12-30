WITH stg_fct_orders AS (
    SELECT
        so.order_id AS order_nk,
        soi.order_item_id AS order_item_nk,
        fdc.customer_id AS customer_id,
        fds.seller_id AS seller_id,
        fdp.product_id AS product_id,
        soi.price AS price,
        soi.freight_value AS freight_value
    FROM
        stg.orders so

    JOIN stg.order_items soi
        ON soi.order_id = so.order_id

    JOIN final.dim_customers fdc
        ON fdc.customer_nk = so.customer_id

    JOIN final.dim_sellers fds
        ON fds.seller_nk = soi.seller_id

    JOIN final.dim_products fdp
        ON fdp.product_nk = soi.product_id

)

INSERT INTO final.fct_orders (
    order_nk,
    order_item_nk,
    customer_id,
    seller_id,
    product_id,
    price,
    freight_value
)

SELECT *
FROM stg_fct_orders

ON CONFLICT(order_nk, order_item_nk)
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    seller_id = EXCLUDED.seller_id,
    product_id = EXCLUDED.product_id,
    price = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value,
    updated_at = CASE
                    WHEN final.fct_orders.customer_id <> EXCLUDED.customer_id
                         OR final.fct_orders.seller_id <> EXCLUDED.seller_id
                         OR final.fct_orders.product_id <> EXCLUDED.product_id
                         OR final.fct_orders.price <> EXCLUDED.price
                         OR final.fct_orders.freight_value <> EXCLUDED.freight_value
                    THEN CURRENT_TIMESTAMP
                    ELSE final.fct_orders.updated_at
                 END;