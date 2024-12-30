WITH
    stg_orders AS (
        SELECT *
        FROM stg.orders
    ),

    stg_order_items AS (
        SELECT *
        FROM stg.order_items
    ),

    dim_products AS (
        SELECT *
        FROM final.dim_products
    ),

    cnt_product_sales AS (
        SELECT
            dd.date_id,
            dp.product_id,
            COUNT(dp.product_id) AS sales_quantity,
            SUM(soi.price) AS total_sales_value
        FROM stg.order_items soi
        JOIN stg.orders so ON so.order_id = soi.order_id
        JOIN final.dim_date dd ON dd.date_actual = DATE(so.order_purchase_timestamp)
        JOIN final.dim_products dp ON dp.product_nk = soi.product_id
        WHERE so.order_status = 'delivered'
        GROUP BY dd.date_id, dp.product_id
    )

INSERT INTO final.fct_sales_daily (
    date_id,
    product_id,
    sales_quantity,
    sales_value
)
SELECT
    date_id,
    product_id,
    sales_quantity,
    total_sales_value
FROM cnt_product_sales
ON CONFLICT (date_id, product_id)
DO UPDATE SET
    sales_quantity = EXCLUDED.sales_quantity,
    sales_value = EXCLUDED.sales_value,
    updated_at = CASE 
                    WHEN final.fct_sales_daily.sales_quantity <> EXCLUDED.sales_quantity
                        OR final.fct_sales_daily.sales_value <> EXCLUDED.sales_value
                    THEN CURRENT_TIMESTAMP
                    ELSE final.fct_sales_daily.updated_at
                 END;
