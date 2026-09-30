-- Widget: "Process refund" button + the trigger that makes the audit log
-- widget (order_audit_log.sql) come alive.
--
-- This script does two things (idempotent -- safe to redefine every run):
--
--   1. A trigger function + AFTER UPDATE trigger on `orders` that inserts a
--      row into order_status_history whenever order_status actually changes.
--   2. A stored PROCEDURE refund_order(p_order_id text) that sets that
--      order's order_status to 'canceled'. You do NOT insert into
--      order_status_history yourself here -- the trigger should do that
--      automatically as a side effect of the UPDATE.
--
-- The backend substitutes :order_id with the value from the form (as a
-- quoted, escaped literal) before running this file -- it appears twice
-- below, in the CALL and in the confirmation SELECT at the end. Leave both.

-- 1. Trigger function + trigger
CREATE OR REPLACE FUNCTION log_order_status_change() RETURNS trigger AS $$
BEGIN
  -- TODO: IF NEW.order_status IS DISTINCT FROM OLD.order_status THEN
  --         INSERT INTO order_status_history (order_id, old_status, new_status)
  --         VALUES (OLD.order_id, OLD.order_status, NEW.order_status);
  --       END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_order_status_change ON orders;
-- TODO: CREATE TRIGGER trg_log_order_status_change
--   AFTER UPDATE ON orders
--   FOR EACH ROW EXECUTE FUNCTION log_order_status_change();

-- 2. Refund procedure
CREATE OR REPLACE PROCEDURE refund_order(p_order_id text) AS $$
BEGIN
  -- TODO: UPDATE orders SET order_status = 'canceled' WHERE order_id = p_order_id;
  NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Actually process the refund for this widget invocation, then confirm it:
CALL refund_order(:order_id);

SELECT order_id, order_status FROM orders WHERE order_id = :order_id;
