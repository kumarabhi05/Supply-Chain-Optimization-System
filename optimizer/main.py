import os
import sys
import pandas as pd
from sqlalchemy import create_engine, text
from ortools.linear_solver import pywraplp

def run_optimization(run_id: str):
    """
    Main function to run the supply chain optimization model.
    """
    print(f"Optimizer started for run_id: {run_id}")

    # --- Database Connection ---
    DATABASE_URL = os.getenv("DATABASE_URL")
    engine = create_engine(DATABASE_URL)

    with engine.connect() as connection:
        try:
            # --- 1. Load Data from Database ---
            print("Loading data from database...")
            facilities = pd.read_sql("SELECT * FROM facilities", connection)
            products = pd.read_sql("SELECT * FROM products", connection)
            lanes = pd.read_sql("SELECT * FROM transportation_lanes", connection)
            customer_orders = pd.read_sql("SELECT * FROM customer_orders", connection)

            # Insert initial run record
            connection.execute(text("INSERT INTO optimization_runs (run_id, status) VALUES (:run_id, 'running')"), {"run_id": run_id})
            connection.commit()

            # --- 2. Create the Solver ---
            solver = pywraplp.Solver.CreateSolver('GLOP')
            if not solver:
                raise Exception("Could not create solver.")
            print("Solver created.")

            # --- 3. Define Variables ---
            # Production variables: how much of each product to make at each plant
            production_vars = {}
            for _, facility in facilities[facilities['facility_type'] == 'Plant'].iterrows():
                for _, product in products.iterrows():
                    var_name = f"prod_{facility['facility_id']}_{product['product_id']}"
                    production_vars[(facility['facility_id'], product['product_id'])] = solver.NumVar(0, facility['capacity_units'], var_name)

            # Shipment variables: how much of each product to ship on each lane
            shipment_vars = {}
            for _, lane in lanes.iterrows():
                for _, product in products.iterrows():
                    var_name = f"ship_{lane['origin_facility_id']}_{lane['destination_id']}_{product['product_id']}"
                    shipment_vars[(lane['origin_facility_id'], lane['destination_id'], product['product_id'])] = solver.NumVar(0, solver.infinity(), var_name)
            print("Variables defined.")

            # --- 4. Define Constraints ---
            # Flow balance constraint for each warehouse
            for _, wh in facilities[facilities['facility_type'] == 'Warehouse'].iterrows():
                for _, product in products.iterrows():
                    inflow = solver.Sum(shipment_vars.get((orig, wh['facility_id'], product['product_id']), 0) for orig in facilities['facility_id'])
                    outflow = solver.Sum(shipment_vars.get((wh['facility_id'], dest, product['product_id']), 0) for dest in customer_orders['customer_id'].unique())
                    solver.Add(inflow == outflow, f"flow_balance_{wh['facility_id']}_{product['product_id']}")

            # Production equals outflow from plants
            for _, plant in facilities[facilities['facility_type'] == 'Plant'].iterrows():
                for _, product in products.iterrows():
                    total_produced = production_vars.get((plant['facility_id'], product['product_id']), 0)
                    total_shipped_out = solver.Sum(shipment_vars.get((plant['facility_id'], dest, product['product_id']), 0) for dest in facilities[facilities['facility_type'] == 'Warehouse']['facility_id'])
                    solver.Add(total_produced == total_shipped_out, f"prod_balance_{plant['facility_id']}_{product['product_id']}")

            # Meet customer demand
            demand = customer_orders.groupby(['customer_id', 'product_id'])['quantity_ordered'].sum().to_dict()
            for (customer, product_id), qty in demand.items():
                inflow_to_customer = solver.Sum(shipment_vars.get((orig, customer, product_id), 0) for orig in facilities[facilities['facility_type'] == 'Warehouse']['facility_id'])
                solver.Add(inflow_to_customer >= qty, f"demand_{customer}_{product_id}")
            print("Constraints defined.")

            # --- 5. Define Objective Function (Minimize Total Cost) ---
            total_cost = solver.Sum()
            # Production costs
            for (facility_id, product_id), var in production_vars.items():
                cost = facilities[facilities['facility_id'] == facility_id]['variable_cost_per_unit'].iloc[0]
                total_cost += var * cost
            # Transportation costs
            for (orig, dest, product_id), var in shipment_vars.items():
                cost_per_unit = lanes[(lanes['origin_facility_id'] == orig) & (lanes['destination_id'] == dest)]['cost_per_unit'].iloc[0]
                total_cost += var * cost_per_unit

            solver.Minimize(total_cost)
            print("Objective function defined.")

            # --- 6. Solve the Model ---
            print("Solving the model...")
            status = solver.Solve()

            # --- 7. Process and Save Results ---
            if status == pywraplp.Solver.OPTIMAL:
                print(f"Optimal solution found. Total cost: {solver.Objective().Value()}")

                # Save optimal shipments
                shipments_data = []
                for (orig, dest, prod), var in shipment_vars.items():
                    if var.solution_value() > 0.1:
                        shipments_data.append({
                            'run_id': run_id,
                            'origin_facility_id': orig,
                            'destination_id': dest,
                            'product_id': prod,
                            'quantity_shipped': var.solution_value()
                        })
                pd.DataFrame(shipments_data).to_sql('optimal_shipments', connection, if_exists='append', index=False)

                # Save optimal production
                production_data = []
                for (fac, prod), var in production_vars.items():
                    if var.solution_value() > 0.1:
                        production_data.append({
                            'run_id': run_id,
                            'facility_id': fac,
                            'product_id': prod,
                            'quantity_produced': var.solution_value()
                        })
                pd.DataFrame(production_data).to_sql('optimal_production', connection, if_exists='append', index=False)

                # Update run status
                update_query = text("""
                    UPDATE optimization_runs
                    SET status = 'completed', total_cost = :total_cost
                    WHERE run_id = :run_id
                """)
                connection.execute(update_query, {"total_cost": solver.Objective().Value(), "run_id": run_id})
                connection.commit()
                print("Results saved successfully.")
            else:
                print("The problem does not have an optimal solution.")
                update_query = text("UPDATE optimization_runs SET status = 'failed' WHERE run_id = :run_id")
                connection.execute(update_query, {"run_id": run_id})
                connection.commit()

        except Exception as e:
            print(f"An error occurred: {e}")
            update_query = text("UPDATE optimization_runs SET status = 'failed' WHERE run_id = :run_id")
            connection.execute(update_query, {"run_id": run_id})
            connection.commit()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_optimization(sys.argv[1])
    else:
        print("Error: No run_id provided.")

