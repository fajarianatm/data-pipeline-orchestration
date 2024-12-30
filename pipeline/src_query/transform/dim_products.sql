-- Fungsi Insert/Update untuk SCD Tipe 1
CREATE OR REPLACE FUNCTION final.upsert_dim_products()
RETURNS TRIGGER AS $$
BEGIN
    -- Cek apakah data dengan product_nk sudah ada
    IF EXISTS (
        SELECT 1
        FROM final.dim_products
        WHERE product_nk = NEW.product_id
    ) THEN
        -- Update jika sudah ada
        UPDATE final.dim_products
        SET
            product_category_name = NEW.product_category_name,
            product_category_name_english = (
                SELECT pc.product_category_name_english
                FROM stg.product_category_name_translation AS pc
                WHERE pc.product_category_name = NEW.product_category_name
            ),
            product_name_length = NEW.product_name_length,
            product_description_length = NEW.product_description_length,
            product_photos_qty = NEW.product_photos_qty,
            product_weight_g = NEW.product_weight_g,
            product_length_cm = NEW.product_length_cm,
            product_height_cm = NEW.product_height_cm,
            product_width_cm = NEW.product_width_cm,
            updated_at = NOW()
        WHERE product_nk = NEW.product_id;
    ELSE
        -- Insert jika belum ada
        INSERT INTO final.dim_products (
            product_id,
            product_nk,
            product_category_name,
            product_category_name_english,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            created_at,
            updated_at
        )
        SELECT
            uuid_generate_v4() AS product_id, -- Gunakan UUID baru jika id tidak ada
            NEW.product_id AS product_nk,
            NEW.product_category_name,
            pc.product_category_name_english,
            NEW.product_name_length,
            NEW.product_description_length,
            NEW.product_photos_qty,
            NEW.product_weight_g,
            NEW.product_length_cm,
            NEW.product_height_cm,
            NEW.product_width_cm,
            NOW(),
            NOW()
        FROM stg.product_category_name_translation AS pc
        WHERE NEW.product_category_name = pc.product_category_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cek apakah trigger sudah ada sebelum membuat baru
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'products_upsert_trigger'
    ) THEN
        DROP TRIGGER products_upsert_trigger ON stg.products;
    END IF;
END;
$$;

-- Buat trigger untuk Insert/Update
CREATE TRIGGER products_upsert_trigger
AFTER INSERT OR UPDATE ON stg.products
FOR EACH ROW
EXECUTE FUNCTION final.upsert_dim_products();
