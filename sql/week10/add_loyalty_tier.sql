-- Widget: "Loyalty tiers" table.
--
-- 1. ALTER TABLE customers to add a `loyalty_tier TEXT` column.
-- 2. UPDATE it based on how many total orders that PERSON has placed --
--    grouped by customer_unique_id, not customer_id (see the
--    repeat_customers widget in week 4 if you need the reminder: customer_id
--    is per-order here, so counting by it can never find a repeat customer):
--      'platinum' for 4+ orders, 'gold' for 2-3 orders, 'standard' for 1.
-- 3. SELECT loyalty_tier, COUNT(*) AS customer_count FROM customers
--    GROUP BY loyalty_tier -- ordered platinum, gold, standard (best to
--    worst). Plain alphabetical order would put gold before platinum,
--    which isn't what a real loyalty dashboard would want -- a CASE
--    expression inside ORDER BY lets you define a custom sort order that
--    doesn't have to match the text values alphabetically.

-- TODO: ALTER TABLE customers ADD COLUMN ...
-- TODO: UPDATE customers SET loyalty_tier = ...

SELECT NULL::text AS loyalty_tier, NULL::bigint AS customer_count
WHERE FALSE;
