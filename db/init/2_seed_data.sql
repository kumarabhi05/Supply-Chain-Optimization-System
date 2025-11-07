-- Seed Facilities
INSERT INTO facilities (facility_id, facility_name, facility_type, location_city, capacity_units, fixed_cost, variable_cost_per_unit) VALUES
('PLANT_CHI', 'Chicago Manufacturing Plant', 'Plant', 'Chicago', 10000, 50000.00, 10.50),
('PLANT_LA', 'Los Angeles Manufacturing Plant', 'Plant', 'Los Angeles', 8000, 45000.00, 11.20),
('WH_NYC', 'New York Warehouse', 'Warehouse', 'New York', 20000, 15000.00, 1.50),
('WH_ATL', 'Atlanta Warehouse', 'Warehouse', 'Atlanta', 18000, 12000.00, 1.30);

-- Seed Products
INSERT INTO products (product_id, product_name, unit_volume_m3) VALUES
('PROD001', 'Standard Widget', 0.1),
('PROD002', 'Premium Gadget', 0.25);

-- Seed Customers
INSERT INTO customers (customer_id, customer_name, location_city) VALUES
('CUST_BOS', 'Boston Retail Co', 'Boston'),
('CUST_MIA', 'Miami Wholesale Inc', 'Miami'),
('CUST_DAL', 'Dallas Distributors', 'Dallas');

-- Seed Transportation Lanes
-- Plant to Warehouse
INSERT INTO transportation_lanes (origin_facility_id, destination_id, distance_km, cost_per_unit) VALUES
('PLANT_CHI', 'WH_NYC', 1200, 5.50),
('PLANT_CHI', 'WH_ATL', 1000, 4.80),
('PLANT_LA', 'WH_NYC', 4500, 15.00),
('PLANT_LA', 'WH_ATL', 3500, 12.50);
-- Warehouse to Customer
INSERT INTO transportation_lanes (origin_facility_id, destination_id, distance_km, cost_per_unit) VALUES
('WH_NYC', 'CUST_BOS', 300, 2.10),
('WH_ATL', 'CUST_MIA', 1000, 4.50),
('WH_ATL', 'CUST_DAL', 1200, 5.20),
-- Add a lane that is needed for demand
('WH_NYC', 'CUST_MIA', 1800, 8.00);


-- Seed Customer Orders (Demand)
INSERT INTO customer_orders (customer_id, product_id, quantity_ordered, order_date) VALUES
('CUST_BOS', 'PROD001', 500, '2025-10-01'),
('CUST_MIA', 'PROD001', 800, '2025-10-02'),
('CUST_MIA', 'PROD002', 400, '2025-10-02'),
('CUST_DAL', 'PROD002', 1200, '2025-10-03');

-- Seed Initial Inventory
INSERT INTO inventory (facility_id, product_id, quantity_on_hand, snapshot_date) VALUES
('WH_NYC', 'PROD001', 1000, '2025-09-30'),
('WH_NYC', 'PROD002', 200, '2025-09-30'),
('WH_ATL', 'PROD001', 1500, '2025-09-30'),
('WH_ATL', 'PROD002', 800, '2025-09-30');