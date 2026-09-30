-- Widget: "What can this seller see?" -- a second RLS policy, this time on
-- order_items (which has seller_id -- orders itself doesn't, since one
-- order can contain items from several sellers).
--
-- Goal: a seller logged in as app_seller should only see order_items rows
-- where seller_id matches current_setting('app.current_seller_id', true).
--
-- Same idempotent-script, same marker convention as rls_policy.sql:
-- everything above `-- @switch-role` runs with full privileges, everything
-- below runs as whichever role the backend switched to.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_seller') THEN
    CREATE ROLE app_seller NOLOGIN;
  END IF;
END $$;

GRANT SELECT ON order_items TO app_seller;

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS seller_own_items ON order_items;

-- TODO: CREATE POLICY seller_own_items ON order_items FOR SELECT TO app_seller
--   USING (seller_id = current_setting('app.current_seller_id', true));

-- @switch-role
SELECT order_id, order_item_id, seller_id, price
FROM order_items
ORDER BY order_id, order_item_id;
