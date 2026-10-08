-- Widget: "Top products" card on the dashboard.
--
-- Write a query that returns the 5 products with the highest total revenue
-- (sum of order_items.price across all their line items).
--
-- Expected columns: product_id, product_name, total_revenue
-- Expected order: total_revenue DESC
-- Expected row count: 5 -- use FETCH FIRST 5 ROWS ONLY, not LIMIT. Same
-- result, but FETCH is the standard-SQL form (works the same way across
-- most databases, not just Postgres) and it's what the rest of this course
-- uses -- see week05's pagination widget for FETCH's other half, OFFSET.
--
-- Hint: JOIN order_items to products for product_name (and the category,
-- if you want it -- not required here, but good practice for later weeks).

-- SELECT NULL::text AS product_id, NULL::text AS product_name, NULL::numeric AS total_revenue
-- WHERE FALSE;
-- ^ placeholder so the widget builds and shows "locked" instead of erroring.
-- Replace this whole query with your own.

SELECT o.product_id, p.product_name, SUM(o.price) AS total_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
GROUP BY o.product_id, p.product_name 
ORDER BY total_revenue DESC
FETCH FIRST 5 ROWS ONLY;