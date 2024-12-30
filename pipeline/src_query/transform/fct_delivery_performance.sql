WITH
    stg_orders AS (
        SELECT *
        FROM stg.orders
        WHERE order_status = 'delivered'
    ),
    stg_order_items AS (
        SELECT *
        FROM stg.order_items
    ),
    dim_date AS (
        SELECT *
        FROM final.dim_date
    ),
    final_fct_delivery_performance AS (
        SELECT 
            so.order_id AS order_nk,
            dd1.date_id AS order_purchase_at,
            dd2.date_id AS order_approved_at,
            dd3.date_id AS shipping_limit_date,
            dd4.date_id AS order_carrier_date,
            dd5.date_id AS order_delivered_customer_date,
            dd6.date_id AS order_estimated_delivery_date,
            so.order_status AS order_status,
            (so.order_approved_at - so.order_purchase_timestamp) AS purchase_to_approval_days,
            (so.order_delivered_carrier_date - so.order_approved_at) AS approval_to_shipping_days,
            (so.order_delivered_customer_date - order_delivered_carrier_date) AS shipping_to_delivery_days,
            (so.order_delivered_customer_date - order_estimated_delivery_date) AS delivery_to_estimated_days,
            (so.order_delivered_customer_date - order_approved_at) AS purchase_to_delivered_days,
            (soi.shipping_limit_date - order_delivered_carrier_date) AS shipping_limit_to_carrier_days,
            ROW_NUMBER() OVER (PARTITION BY so.order_id ORDER BY so.order_purchase_timestamp DESC) AS row_num
        FROM stg.orders so
        JOIN stg.order_items soi 
            ON soi.order_id = so.order_id
        JOIN final.dim_date dd1 
            ON dd1.date_actual = DATE(so.order_purchase_timestamp)
        JOIN final.dim_date dd2
            ON dd2.date_actual = DATE(so.order_approved_at)
        JOIN final.dim_date dd3
            ON dd3.date_actual = DATE(soi.shipping_limit_date)
        JOIN final.dim_date dd4
            ON dd4.date_actual = DATE(so.order_delivered_carrier_date)
        JOIN final.dim_date dd5
            ON dd5.date_actual = DATE(so.order_delivered_customer_date)
        JOIN final.dim_date dd6
            ON dd6.date_actual = DATE(so.order_estimated_delivery_date)
    )
-- Pilih hanya satu baris untuk setiap order_id berdasarkan row_number
INSERT INTO final.fct_delivery_performance (
    order_nk,
    order_purchase_at,
    order_approved_at,
    shipping_limit_date,
    order_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_status,
    purchase_to_approval_days,
    approval_to_shipping_days,
    shipping_to_delivery_days,
    delivery_to_estimated_days,
    purchase_to_delivery_days,
    shipping_limit_to_carrier_days
)
SELECT 
    order_nk,
    order_purchase_at,
    order_approved_at,
    shipping_limit_date,
    order_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_status,
    purchase_to_approval_days,
    approval_to_shipping_days,
    shipping_to_delivery_days,
    delivery_to_estimated_days,
    purchase_to_delivered_days,
    shipping_limit_to_carrier_days
FROM final_fct_delivery_performance
WHERE row_num = 1

ON CONFLICT(order_nk) 
DO UPDATE SET
    order_purchase_at = EXCLUDED.order_purchase_at,
    order_approved_at = EXCLUDED.order_approved_at,
    shipping_limit_date = EXCLUDED.shipping_limit_date,
    order_carrier_date = EXCLUDED.order_carrier_date,
    order_delivered_customer_date = EXCLUDED.order_delivered_customer_date,
    order_estimated_delivery_date = EXCLUDED.order_estimated_delivery_date,
    order_status = EXCLUDED.order_status,
    purchase_to_approval_days = EXCLUDED.purchase_to_approval_days,
    approval_to_shipping_days = EXCLUDED.approval_to_shipping_days,
    shipping_to_delivery_days = EXCLUDED.shipping_to_delivery_days,
    delivery_to_estimated_days = EXCLUDED.delivery_to_estimated_days,
    purchase_to_delivery_days = EXCLUDED.purchase_to_delivery_days,
    shipping_limit_to_carrier_days = EXCLUDED.shipping_limit_to_carrier_days,
    updated_at = CASE 
                    WHEN final.fct_delivery_performance.order_purchase_at <> EXCLUDED.order_purchase_at
                        OR final.fct_delivery_performance.order_approved_at <> EXCLUDED.order_approved_at
                        OR final.fct_delivery_performance.shipping_limit_date <> EXCLUDED.shipping_limit_date
                        OR final.fct_delivery_performance.order_carrier_date <> EXCLUDED.order_carrier_date
                        OR final.fct_delivery_performance.order_delivered_customer_date <> EXCLUDED.order_delivered_customer_date
                        OR final.fct_delivery_performance.order_estimated_delivery_date <> EXCLUDED.order_estimated_delivery_date
                        OR final.fct_delivery_performance.order_status <> EXCLUDED.order_status
                        OR final.fct_delivery_performance.purchase_to_approval_days <> EXCLUDED.purchase_to_approval_days
                        OR final.fct_delivery_performance.approval_to_shipping_days <> EXCLUDED.approval_to_shipping_days
                        OR final.fct_delivery_performance.shipping_to_delivery_days <> EXCLUDED.shipping_to_delivery_days
                        OR final.fct_delivery_performance.delivery_to_estimated_days <> EXCLUDED.delivery_to_estimated_days
                        OR final.fct_delivery_performance.purchase_to_delivery_days <> EXCLUDED.purchase_to_delivery_days
                        OR final.fct_delivery_performance.shipping_limit_to_carrier_days <> EXCLUDED.shipping_limit_to_carrier_days
                    THEN CURRENT_TIMESTAMP
                    ELSE final.fct_delivery_performance.updated_at
                 END;
