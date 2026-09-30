-- Widget: "Priority orders" filter toggle.
--
-- The dashboard wants to flag orders as "priority" when their estimated
-- delivery window is under 7 days. There's no column for that yet.
--
-- 1. ALTER TABLE orders to add an `is_priority BOOLEAN NOT NULL DEFAULT false`
--    column.
-- 2. UPDATE existing rows: set is_priority = true where
--    (order_estimated_delivery_date - order_purchase_timestamp) < interval '7 days'.
-- 3. Then write the SELECT the widget uses:
--    order_id, order_purchase_timestamp, order_estimated_delivery_date
--    for is_priority = true orders, soonest estimated delivery first.
--    Use FETCH FIRST 20 ROWS ONLY (not LIMIT) -- against the real dataset
--    there can be hundreds of priority orders, and the widget only needs
--    to show the most urgent 20.

-- TODO: ALTER TABLE ...
-- TODO: UPDATE ...

SELECT NULL::text AS order_id, NULL::timestamp AS order_purchase_timestamp,
       NULL::timestamp AS order_estimated_delivery_date
WHERE FALSE;
