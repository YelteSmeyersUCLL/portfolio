-- Widget: "Ghost customers" table — the 20 customers with the most orders
-- who never left a review.
--
-- Expected columns: customer_id, customer_name, orders_without_review
-- Expected order: orders_without_review DESC
-- Expected row count: 20 -- use FETCH FIRST 20 ROWS ONLY (not LIMIT).
--
-- Hint: an anti-join (NOT EXISTS / LEFT JOIN ... WHERE IS NULL) is usually
-- clearer here than a correlated subquery in the SELECT list.

SELECT NULL::text AS customer_id, NULL::text AS customer_name, NULL::bigint AS orders_without_review
WHERE FALSE;
