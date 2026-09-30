-- Widget: "Audit log" panel -- shows every status change your trigger has
-- recorded. This stays locked until process_refund.sql's trigger has
-- actually written a row.
--
-- Expected columns: order_id, old_status, new_status, changed_at
-- Expected order: changed_at DESC

SELECT order_id, old_status, new_status, changed_at
FROM order_status_history
ORDER BY changed_at DESC;
