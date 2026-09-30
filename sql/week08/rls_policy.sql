-- Widget: "Who can see this customer's orders?" role switcher.
--
-- Goal: enable Row-Level Security on `orders` so that THREE roles see
-- three genuinely different slices of the data:
--
--   - app_customer: only orders belonging to the PERSON currently set via
--     current_setting('app.current_person_id', true) -- ALL of their
--     orders, not just one. That means filtering through
--     customer_unique_id, not customer_id: remember customer_id is
--     per-ORDER here (see the comment on the customers table in
--     db/schema.sql, or the repeat_customers widget in week 4), so a
--     policy that only compares against customer_id would show a logged-in
--     customer just one single order even if they've bought many times --
--     not what a real "my orders" account view should do.
--
--   - app_district_admin: every order belonging to customers in ONE state
--     (current_setting('app.current_district', true)) -- a realistic
--     "regional manager" role. Most real systems have this kind of tiered
--     access, not just a flat customer/admin split.
--
--   - app_admin: every order, unrestricted, no filtering at all.
--
-- Cap the final SELECT with FETCH FIRST 50 ROWS ONLY -- this matters most
-- for app_district_admin and app_admin: against the real dataset,
-- "unrestricted" can mean tens of thousands of rows, and dumping all of
-- them into one table is both slow and not how a real admin dashboard
-- would behave (a real one paginates or shows "most recent N" by default).
--
-- This script runs top-to-bottom EVERY time the widget is used, so it's
-- written to be idempotent: it (re)creates the roles/policies, then runs
-- the SELECT the widget displays. The backend switches to whichever role
-- was picked in the dropdown before running this file -- see role_switch.js.
--
-- The line `-- @switch-role` below is a real marker the backend looks for --
-- don't remove or rename it. Everything ABOVE it runs with full privileges
-- (so your CREATE ROLE / ALTER TABLE / CREATE POLICY statements can actually
-- take effect). Everything BELOW it runs as whichever role was picked in the
-- dropdown -- that's what makes the RLS policy actually apply.

-- 1. Roles (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_customer') THEN
    CREATE ROLE app_customer NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_district_admin') THEN
    CREATE ROLE app_district_admin NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_admin') THEN
    CREATE ROLE app_admin NOLOGIN;
  END IF;
END $$;

GRANT SELECT ON orders TO app_customer, app_district_admin, app_admin;
GRANT SELECT ON customers TO app_customer, app_district_admin;

-- 2. Enable RLS and define the policies
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS customer_own_orders ON orders;
DROP POLICY IF EXISTS district_admin_orders ON orders;
DROP POLICY IF EXISTS admin_all_orders ON orders;

-- TODO: CREATE POLICY customer_own_orders ON orders FOR SELECT TO app_customer
--   USING (customer_id IN (
--     SELECT c.customer_id FROM customers c
--     WHERE c.customer_unique_id = current_setting('app.current_person_id', true)
--   ));

-- TODO: CREATE POLICY district_admin_orders ON orders FOR SELECT TO app_district_admin
--   USING (customer_id IN (
--     SELECT c.customer_id FROM customers c
--     WHERE c.customer_state = current_setting('app.current_district', true)
--   ));

-- app_admin needs to see everything -- either add a permissive policy for
-- app_admin with USING (true), or research BYPASSRLS. Either is fine;
-- explain your choice in a one-line comment.

-- 3. The query the widget displays -- leave this as-is. What comes back
-- depends entirely on your policies above and which role the backend
-- switched to. FETCH FIRST 50 ROWS ONLY is already here -- don't remove it.
-- @switch-role
SELECT order_id, customer_id, order_status, order_purchase_timestamp
FROM orders
ORDER BY order_purchase_timestamp DESC
FETCH FIRST 50 ROWS ONLY;
