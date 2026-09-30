-- Widget: "Orders — page 2" table.
--
-- A classic pagination use case: showing the *second* page of a list, 20
-- orders per page, most recent first. Page 1 would be the 20 most recent
-- orders; this widget is page 2 -- the next 20 after that.
--
-- Expected columns: order_id, customer_id, order_status, order_purchase_timestamp
-- Expected order: order_purchase_timestamp DESC
-- Expected row count: 20
--
-- Use OFFSET ... FETCH NEXT ... ROWS ONLY together: OFFSET skips past
-- page 1's rows, FETCH NEXT then takes the next batch. Skipping the wrong
-- number of rows (or forgetting to sort first) is a common, silent way to
-- get a "plausible looking" but wrong page -- the query still runs fine,
-- it just doesn't show what a real page 2 should show.

SELECT NULL::text AS order_id, NULL::text AS customer_id,
       NULL::text AS order_status, NULL::timestamp AS order_purchase_timestamp
WHERE FALSE;
