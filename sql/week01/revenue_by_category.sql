-- Widget: "Revenue by category" card.
--
-- Write a query that returns total revenue (sum of order_items.price) per
-- product category, in English (product_category_name_translation has the
-- English names -- product_category_name on its own is Portuguese).
--
-- Expected columns: category, total_revenue
-- Expected order: total_revenue DESC
--
-- Hint: this needs a three-table join: order_items -> products ->
-- product_category_name_translation.

-- SELECT NULL::text AS category, NULL::numeric AS total_revenue
-- WHERE FALSE;

SELECT c.product_category_name_english AS category, SUM(o.price) AS total_revenue
FROM order_items o
JOIN products p ON o.product_id = p.product_id
JOIN product_category_name_translation c ON p.product_category_name = c.product_category_name
GROUP BY category;