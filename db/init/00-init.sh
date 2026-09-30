#!/usr/bin/env bash
# Runs automatically on first container boot (Postgres docker-entrypoint-initdb.d
# convention). Loads the schema, then loads seed data: the full dataset if
# scripts/fetch_full_dataset.sh has been run, otherwise the small sample set.
set -euo pipefail

SCHEMA_DIR="/db"
SEED_FULL="$SCHEMA_DIR/seed/full"
SEED_SAMPLE="$SCHEMA_DIR/seed/sample"

echo "[init] applying schema..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_DIR/schema.sql"

if [ -d "$SEED_FULL" ] && [ -n "$(ls -A "$SEED_FULL" 2>/dev/null)" ]; then
  SEED_DIR="$SEED_FULL"
  echo "[init] loading FULL Olist dataset from $SEED_DIR"
else
  SEED_DIR="$SEED_SAMPLE"
  echo "[init] no full dataset found — loading small sample dataset from $SEED_DIR"
  echo "[init] run ./scripts/fetch_full_dataset.sh for the real ~100k-order dataset"
fi

# Load order matters: parents before children (FK dependencies).
LOAD_ORDER=(
  product_category_name_translation
  sellers
  products
  customers
  geolocation
  orders
  order_items
  order_payments
  order_reviews
)

for table in "${LOAD_ORDER[@]}"; do
  file="$SEED_DIR/${table}.csv"
  if [ ! -f "$file" ]; then
    echo "[init]   WARNING: $file not found, skipping $table"
    continue
  fi

  if [ "$table" = "products" ]; then
    # The real Olist dataset has a known gap: a handful of categories show
    # up on products but were never added to the category-translation
    # lookup table (e.g. "pc_gamer"). Load into a staging table first (no
    # FK enforced there), backfill any missing category with a placeholder
    # translation, then insert for real -- so the FK stays meaningful
    # instead of just being dropped to work around messy real data.
    echo "[init]   loading products (backfilling any categories missing from the translation table first)"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" << SQL
CREATE TEMP TABLE products_staging (LIKE products INCLUDING ALL);
\copy products_staging FROM '$file' WITH (FORMAT csv, HEADER true, NULL '')

INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
SELECT DISTINCT product_category_name, product_category_name
FROM products_staging
WHERE product_category_name IS NOT NULL
ON CONFLICT (product_category_name) DO NOTHING;

INSERT INTO products SELECT * FROM products_staging;
SQL
  elif [ "$table" = "order_reviews" ]; then
    # Another known real-data quirk: order_reviews.csv has a handful of
    # duplicate review_id rows (looks like a re-survey/export artifact from
    # Olist's own pipeline). review_id is our primary key, so load into a
    # staging table WITHOUT that constraint (duplicates can land there),
    # then keep one row per review_id -- the most recently created, on the
    # reasonable assumption a later copy reflects a more complete review.
    echo "[init]   loading order_reviews (de-duplicating repeated review_ids first)"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" << SQL
CREATE TEMP TABLE order_reviews_staging (LIKE order_reviews INCLUDING DEFAULTS);
\copy order_reviews_staging FROM '$file' WITH (FORMAT csv, HEADER true, NULL '')

INSERT INTO order_reviews
SELECT DISTINCT ON (review_id) *
FROM order_reviews_staging
ORDER BY review_id, review_creation_date DESC NULLS LAST, review_answer_timestamp DESC NULLS LAST;
SQL
  else
    echo "[init]   loading $table"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
      -c "\copy $table FROM '$file' WITH (FORMAT csv, HEADER true, NULL '')"
  fi
done

echo "[init] done."
