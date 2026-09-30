-- Widget: "Seller performance" table.
--
-- Write a query that returns each seller's number of order_items sold and
-- their average review score across all reviews for orders containing their
-- items. Only include sellers with at least 2 items sold.
--
-- Expected columns: seller_id, seller_name, items_sold, avg_review_score
-- Expected order: items_sold DESC

SELECT NULL::text AS seller_id, NULL::text AS seller_name,
       NULL::bigint AS items_sold, NULL::numeric AS avg_review_score
WHERE FALSE;
