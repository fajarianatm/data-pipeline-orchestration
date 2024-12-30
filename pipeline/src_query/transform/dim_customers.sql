-- Step 1: Initial Load of dim_customers data
WITH valid_customers AS (
    SELECT
        c.id AS customer_id,
        c.customer_id AS customer_nk,
        c.customer_zip_code_prefix AS customer_zip_code,
        c.customer_city,
        c.customer_state
    FROM stg.customers c
    LEFT JOIN final.dim_customers d
        ON c.id = d.customer_id
        AND d.current_flag = 'current'
    WHERE d.customer_id IS NULL
       OR (
           c.customer_zip_code_prefix IS DISTINCT FROM d.customer_zip_code
           OR c.customer_city IS DISTINCT FROM d.customer_city
           OR c.customer_state IS DISTINCT FROM d.customer_state
       )
)
INSERT INTO final.dim_customers (
    customer_id,
    customer_nk,
    customer_zip_code,
    customer_city,
    customer_state,
    current_flag,
    created_at,
    expired_at,
    version_id
)
SELECT 
    vc.customer_id,
    vc.customer_nk,
    vc.customer_zip_code,
    vc.customer_city,
    vc.customer_state,
    'current',
    NOW(),
    NULL,
    COALESCE((
        SELECT MAX(version_id)
        FROM final.dim_customers d
        WHERE d.customer_id = vc.customer_id
    ), 0) + 1
FROM valid_customers vc;

-- Trigger Function: Insert new data into dim_customers
CREATE OR REPLACE FUNCTION final.insert_dim_customers()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO final.dim_customers (
        customer_id,
        customer_nk,
        customer_zip_code,
        customer_city,
        customer_state,
        current_flag,
        created_at,
        expired_at,
        version_id
    )
    VALUES (
        NEW.id,
        NEW.customer_id,
        NEW.customer_zip_code_prefix,
        NEW.customer_city,
        NEW.customer_state,
        'current',
        NOW(),
        NULL,
        (
            SELECT COALESCE(MAX(version_id), 0) + 1
            FROM final.dim_customers
            WHERE customer_id = NEW.id
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remove and recreate customer_insert_trigger
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'customer_insert_trigger'
    ) THEN
        DROP TRIGGER customer_insert_trigger ON stg.customers;
    END IF;

    CREATE TRIGGER customer_insert_trigger
    AFTER INSERT ON stg.customers
    FOR EACH ROW
    EXECUTE FUNCTION final.insert_dim_customers();
END;
$$;

-- Trigger Function: SCD Type 2 update
CREATE OR REPLACE FUNCTION final.update_dim_customers()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE final.dim_customers
    SET 
        current_flag = 'expired',
        expired_at = CURRENT_TIMESTAMP
    WHERE 
        customer_nk = NEW.customer_id
        AND current_flag = 'current'
        AND (
            NEW.customer_zip_code_prefix IS DISTINCT FROM customer_zip_code OR
            NEW.customer_city IS DISTINCT FROM customer_city OR
            NEW.customer_state IS DISTINCT FROM customer_state
        );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remove and recreate trg_update_dim_customers
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_update_dim_customers'
    ) THEN
        DROP TRIGGER trg_update_dim_customers ON stg.customers;
    END IF;

    CREATE TRIGGER trg_update_dim_customers
    AFTER UPDATE ON stg.customers
    FOR EACH ROW
    EXECUTE FUNCTION final.update_dim_customers();
END;
$$;
