-- ----------------------------
-- Basic Data Tables
-- ----------------------------

-- Facilities (Plants, Warehouses)
CREATE TABLE facilities (
    facility_id VARCHAR(50) PRIMARY KEY,
    facility_name VARCHAR(255),
    facility_type VARCHAR(50), -- 'Plant' or 'Warehouse'
    location_city VARCHAR(100),
    capacity_units INT,
    fixed_cost DECIMAL(12, 2),
    variable_cost_per_unit DECIMAL(12, 2) -- e.g., production cost at plants
);

-- Products
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255),
    unit_volume_m3 DECIMAL(10, 4)
);

-- Customers
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(255),
    location_city VARCHAR(100)
);

-- Transportation Lanes (includes warehouse-to-customer)
CREATE TABLE transportation_lanes (
    lane_id SERIAL PRIMARY KEY,
    origin_facility_id VARCHAR(50),
    destination_id VARCHAR(50), -- Can be a facility_id or a customer_id
    distance_km INT,
    cost_per_km DECIMAL(10, 2),
    cost_per_unit DECIMAL(10, 2) -- Simplified cost for modeling
);

-- Customer Orders (Demand Data)
CREATE TABLE customer_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    product_id VARCHAR(50) REFERENCES products(product_id),
    quantity_ordered INT,
    order_date DATE
);

-- Inventory (Snapshot)
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    facility_id VARCHAR(50) REFERENCES facilities(facility_id),
    product_id VARCHAR(50) REFERENCES products(product_id),
    quantity_on_hand INT,
    snapshot_date DATE
);


-- ----------------------------
-- Optimization Results Tables
-- ----------------------------

-- A record for each optimization run
CREATE TABLE optimization_runs (
    run_id VARCHAR(255) PRIMARY KEY,
    run_timestamp TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(50), -- e.g., 'running', 'completed', 'failed'
    total_cost DECIMAL(20, 2)
);

-- Stores the optimal shipment plan from a run
CREATE TABLE optimal_shipments (
    shipment_id SERIAL PRIMARY KEY,
    run_id VARCHAR(255) REFERENCES optimization_runs(run_id),
    origin_facility_id VARCHAR(50),
    destination_id VARCHAR(50),
    product_id VARCHAR(50),
    quantity_shipped INT,
    shipment_cost DECIMAL(12, 2) -- Can be calculated post-optimization
);

-- Stores the optimal production plan from a run
CREATE TABLE optimal_production (
    production_result_id SERIAL PRIMARY KEY,
    run_id VARCHAR(255) REFERENCES optimization_runs(run_id),
    facility_id VARCHAR(50), -- Plant ID
    product_id VARCHAR(50),
    quantity_produced INT,
    production_cost DECIMAL(12, 2) -- Can be calculated post-optimization
);