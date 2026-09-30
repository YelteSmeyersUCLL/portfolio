-- Widget: "Category summary" -- backed by a VIEW, same pattern as
-- seller_summary_view.sql. Different table, same idea: get comfortable
-- writing views, not just one.
--
-- 1. CREATE OR REPLACE VIEW category_summary AS ... (category, items_sold,
--    total_revenue, joining order_items -> products -> category translation)
-- 2. Then SELECT * FROM category_summary ORDER BY total_revenue DESC;

-- TODO: CREATE OR REPLACE VIEW category_summary AS ...

SELECT NULL::text AS category, NULL::bigint AS items_sold, NULL::numeric AS total_revenue
WHERE FALSE;
