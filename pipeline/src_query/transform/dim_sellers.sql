-- Step 1: Initial Load of dim_sellers data
WITH valid_sellers AS (
    SELECT
        s.id AS seller_id,
        s.seller_id AS seller_nk,
        s.seller_zip_code_prefix AS seller_zip_code,
        s.seller_city,
        s.seller_state
    FROM stg.sellers s
    LEFT JOIN final.dim_sellers d
        ON s.id = d.seller_id
        AND d.current_flag = 'current'
    WHERE d.seller_id IS NULL
       OR (
           s.seller_zip_code_prefix IS DISTINCT FROM d.seller_zip_code
           OR s.seller_city IS DISTINCT FROM d.seller_city
           OR s.seller_state IS DISTINCT FROM d.seller_state
       )
)
INSERT INTO final.dim_sellers (
    seller_id,
    seller_nk,
    seller_zip_code,
    seller_city,
    seller_state,
    current_flag,
    created_at,
    expired_at,
    version_id
)
SELECT 
    vs.seller_id,
    vs.seller_nk,
    vs.seller_zip_code,
    vs.seller_city,
    vs.seller_state,
    'current',
    NOW(),
    NULL,
    COALESCE((
        SELECT MAX(version_id)
        FROM final.dim_sellers d
        WHERE d.seller_id = vs.seller_id
    ), 0) + 1
FROM valid_sellers vs;

-- Trigger Function: Insert new data into dim_sellers
CREATE OR REPLACE FUNCTION final.insert_dim_sellers()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO final.dim_sellers (
        seller_id,
        seller_nk,
        seller_zip_code,
        seller_city,
        seller_state,
        current_flag,
        created_at,
        expired_at,
        version_id
    )
    VALUES (
        NEW.id,
        NEW.seller_id,
        NEW.seller_zip_code_prefix,
        NEW.seller_city,
        NEW.seller_state,
        'current',
        NOW(),
        NULL,
        (
            SELECT COALESCE(MAX(version_id), 0) + 1
            FROM final.dim_sellers
            WHERE seller_id = NEW.id
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remove and recreate seller_insert_trigger
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'seller_insert_trigger'
    ) THEN
        DROP TRIGGER seller_insert_trigger ON stg.sellers;
    END IF;

    CREATE TRIGGER seller_insert_trigger
    AFTER INSERT ON stg.sellers
    FOR EACH ROW
    EXECUTE FUNCTION final.insert_dim_sellers();
END;
$$;

-- Trigger Function: SCD Type 2 update
CREATE OR REPLACE FUNCTION final.update_dim_sellers()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE final.dim_sellers
    SET 
        current_flag = 'expired',
        expired_at = CURRENT_TIMESTAMP
    WHERE 
        seller_nk = NEW.seller_id
        AND current_flag = 'current'
        AND (
            NEW.seller_zip_code_prefix IS DISTINCT FROM seller_zip_code OR
            NEW.seller_city IS DISTINCT FROM seller_city OR
            NEW.seller_state IS DISTINCT FROM seller_state
        );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remove and recreate trg_update_dim_sellers
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_update_dim_sellers'
    ) THEN
        DROP TRIGGER trg_update_dim_sellers ON stg.sellers;
    END IF;

    CREATE TRIGGER trg_update_dim_sellers
    AFTER UPDATE ON stg.sellers
    FOR EACH ROW
    EXECUTE FUNCTION final.update_dim_sellers();
END;
$$;
