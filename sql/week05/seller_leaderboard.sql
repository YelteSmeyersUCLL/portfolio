-- Widget: "Seller leaderboard by state" table.
--
-- For each seller, compute their total revenue (sum of order_items.price)
-- and their RANK() within their own seller_state, ordered by revenue
-- descending. Only show the top 3 sellers per state.
--
-- Expected columns: seller_id, seller_name, seller_state, total_revenue, state_rank
-- Expected order: seller_state ASC, state_rank ASC

SELECT NULL::text AS seller_id, NULL::text AS seller_name, NULL::text AS seller_state,
       NULL::numeric AS total_revenue, NULL::bigint AS state_rank
WHERE FALSE;
