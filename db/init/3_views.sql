-- Cost-to-Serve View
-- Calculates the total cost to serve each customer based on the latest completed run
CREATE OR REPLACE VIEW cost_to_serve AS
WITH latest_run AS (
    SELECT run_id
    FROM optimization_runs
    WHERE status = 'completed'
    ORDER BY run_timestamp DESC
    LIMIT 1
),
production_costs AS (
    SELECT
        op.run_id,
        op.product_id,
        SUM(op.quantity_produced * f.variable_cost_per_unit) / SUM(op.quantity_produced) as avg_production_cost
    FROM optimal_production op
    JOIN facilities f ON op.facility_id = f.facility_id
    WHERE op.run_id = (SELECT run_id FROM latest_run)
    GROUP BY op.run_id, op.product_id
),
transport_costs AS (
    SELECT
        os.run_id,
        os.destination_id as customer_id,
        os.product_id,
        SUM(os.quantity_shipped * tl.cost_per_unit) as total_transport_cost
    FROM optimal_shipments os
    JOIN transportation_lanes tl ON os.origin_facility_id = tl.origin_facility_id AND os.destination_id = tl.destination_id
    WHERE os.run_id = (SELECT run_id FROM latest_run) AND os.destination_id LIKE 'CUST_%'
    GROUP BY os.run_id, os.destination_id, os.product_id
)
SELECT
    tc.customer_id,
    c.customer_name,
    SUM(
        tc.total_transport_cost +
        (os.quantity_shipped * pc.avg_production_cost)
    ) as total_cost_to_serve
FROM transport_costs tc
JOIN customers c ON tc.customer_id = c.customer_id
JOIN optimal_shipments os ON tc.customer_id = os.destination_id AND tc.product_id = os.product_id AND tc.run_id = os.run_id
JOIN production_costs pc ON tc.product_id = pc.product_id AND tc.run_id = pc.run_id
GROUP BY tc.customer_id, c.customer_name;


-- Service Level View
-- Calculates the percentage of demand met for each customer in the latest run
CREATE OR REPLACE VIEW service_level_by_customer AS
WITH latest_run AS (
    SELECT run_id FROM optimization_runs WHERE status = 'completed' ORDER BY run_timestamp DESC LIMIT 1
),
demand AS (
    SELECT customer_id, product_id, SUM(quantity_ordered) as total_demand
    FROM customer_orders
    GROUP BY customer_id, product_id
),
fulfilled AS (
    SELECT destination_id as customer_id, product_id, SUM(quantity_shipped) as total_fulfilled
    FROM optimal_shipments
    WHERE run_id = (SELECT run_id FROM latest_run) AND destination_id LIKE 'CUST_%'
    GROUP BY destination_id, product_id
)
SELECT
    d.customer_id,
    c.customer_name,
    d.product_id,
    d.total_demand,
    COALESCE(f.total_fulfilled, 0) as total_fulfilled,
    (COALESCE(f.total_fulfilled, 0) * 100.0 / d.total_demand) as service_level_percent
FROM demand d
JOIN customers c ON d.customer_id = c.customer_id
LEFT JOIN fulfilled f ON d.customer_id = f.customer_id AND d.product_id = f.product_id;


-- Stockout Risk View
-- Identifies products at warehouses where current inventory is less than upcoming demand
CREATE OR REPLACE VIEW stockout_risk AS
WITH upcoming_demand AS (
    SELECT
        tl.origin_facility_id as warehouse_id,
        co.product_id,
        SUM(co.quantity_ordered) as demand
    FROM customer_orders co
    -- This is a simplified join; a real model would need to know routing
    JOIN transportation_lanes tl ON co.customer_id = tl.destination_id
    GROUP BY tl.origin_facility_id, co.product_id
)
SELECT
    i.facility_id,
    f.facility_name,
    i.product_id,
    p.product_name,
    i.quantity_on_hand,
    ud.demand as upcoming_demand_from_warehouse,
    (i.quantity_on_hand - ud.demand) as safety_stock_delta
FROM inventory i
JOIN facilities f ON i.facility_id = f.facility_id
JOIN products p ON i.product_id = p.product_id
LEFT JOIN upcoming_demand ud ON i.facility_id = ud.warehouse_id AND i.product_id = ud.product_id
WHERE f.facility_type = 'Warehouse' AND (i.quantity_on_hand - ud.demand) < 0;