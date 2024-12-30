WITH stg_fct_reviews AS (
    SELECT 
        orw.review_id AS review_nk,
        orw.order_id AS order_nk,
        fdc.customer_id AS customer_id,
        CASE
            WHEN orw.review_score BETWEEN 1 AND 2 THEN 'negative'
            WHEN orw.review_score = 3 THEN 'neutral'
            WHEN orw.review_score BETWEEN 4 AND 5 THEN 'positive'
            ELSE 'unknown'
        END AS sentiment,
        fp.payment_type,
        orw.review_score,
        orw.review_comment_title,
        orw.review_comment_message,
        orw.review_creation_date
    FROM stg.order_reviews orw
    JOIN stg.orders so
        ON so.order_id = orw.order_id
    LEFT JOIN stg.order_payments fp
        ON fp.order_id = so.order_id AND fp.payment_sequential = 1  -- memilih pembayaran pertama jika ada
    LEFT JOIN final.dim_customers fdc
        ON fdc.customer_nk = so.customer_id
)
INSERT INTO final.fct_reviews (
    review_nk,
    order_nk,
    customer_id,
    sentiment,
    payment_type,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date
)
SELECT *
FROM stg_fct_reviews
ON CONFLICT (review_nk, order_nk)
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    sentiment = EXCLUDED.sentiment,
    payment_type = EXCLUDED.payment_type,
    review_score = EXCLUDED.review_score,
    review_comment_title = EXCLUDED.review_comment_title,
    review_comment_message = EXCLUDED.review_comment_message,
    review_creation_date = EXCLUDED.review_creation_date,
    updated_at = CASE 
                    WHEN final.fct_reviews.customer_id <> EXCLUDED.customer_id
                        OR final.fct_reviews.sentiment <> EXCLUDED.sentiment
                        OR final.fct_reviews.payment_type <> EXCLUDED.payment_type
                        OR final.fct_reviews.review_score <> EXCLUDED.review_score
                        OR final.fct_reviews.review_comment_title <> EXCLUDED.review_comment_title
                        OR final.fct_reviews.review_comment_message <> EXCLUDED.review_comment_message
                        OR final.fct_reviews.review_creation_date <> EXCLUDED.review_creation_date
                    THEN CURRENT_TIMESTAMP
                    ELSE final.fct_reviews.updated_at
                 END;
