-- Widget: "Monthly revenue trend" chart.
--
-- For each calendar month, compute total revenue (sum of order_items.price
-- for orders purchased that month), and the change from the previous month.
--
-- Expected columns: month, monthly_revenue, change_from_prev_month
-- Expected order: month ASC
--
-- Hint: date_trunc('month', order_purchase_timestamp) buckets a timestamp
-- into its month. LAG() OVER (ORDER BY month) gets the previous row's value
-- to subtract from the current one -- the first month should show NULL,
-- there's nothing before it to compare against.

SELECT NULL::date AS month, NULL::numeric AS monthly_revenue, NULL::numeric AS change_from_prev_month
WHERE FALSE;
