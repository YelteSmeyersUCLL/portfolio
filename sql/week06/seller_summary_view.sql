-- Widget: "Seller summary" — backed by a VIEW instead of a raw query, so the
-- dashboard stays fast even as the dataset grows.
--
-- 1. CREATE OR REPLACE VIEW seller_summary AS ... (seller_id, seller_name,
--    items_sold, total_revenue, avg_review_score per seller)
-- 2. Then SELECT * FROM seller_summary ORDER BY total_revenue DESC;
--
-- This is also the week to look at geolocation with EXPLAIN ANALYZE and add
-- whatever index actually helps -- see the README's "performance week" note.

-- TODO: CREATE OR REPLACE VIEW seller_summary AS ...

SELECT NULL::text AS seller_id, NULL::text AS seller_name, NULL::bigint AS items_sold,
       NULL::numeric AS total_revenue, NULL::numeric AS avg_review_score
WHERE FALSE;
