-- Widget: "Mark delivered" button.
--
-- Same trigger as process_refund.sql -- redefine it here too (idempotent,
-- harmless to redefine) so this widget works even if a student clicks it
-- before ever touching process_refund.sql.
--
-- Then a stored PROCEDURE mark_delivered(p_order_id text) that sets that
-- order's order_status to 'delivered' and order_delivered_customer_date to
-- now(). The trigger should log the status change automatically.

-- 1. Trigger function + trigger (same as process_refund.sql)
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

-- 2. mark_delivered procedure
CREATE OR REPLACE PROCEDURE mark_delivered(p_order_id text) AS $$
BEGIN
  -- TODO: UPDATE orders SET order_status = 'delivered',
  --         order_delivered_customer_date = now()
  --       WHERE order_id = p_order_id;
  NULL;
END;
$$ LANGUAGE plpgsql;

CALL mark_delivered(:order_id);

SELECT order_id, order_status, order_delivered_customer_date FROM orders WHERE order_id = :order_id;
