import os
import subprocess
import uuid
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, text
from pydantic import BaseModel
from typing import List, Optional

# --- Database Connection ---
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)

app = FastAPI(
    title="Supply Chain Optimization API",
    description="API to trigger optimization runs and view results."
)

# --- Pydantic Models for API Response Structure ---
class RunDetails(BaseModel):
    run_id: str
    run_timestamp: str
    status: str
    total_cost: Optional[float]

class Shipment(BaseModel):
    origin_facility_id: str
    destination_id: str
    product_id: str
    quantity_shipped: int

class Production(BaseModel):
    facility_id: str
    product_id: str
    quantity_produced: int

class OptimizationResult(BaseModel):
    run_details: RunDetails
    shipments: List[Shipment]
    production: List[Production]

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Welcome to the Supply Chain Optimization API"}

@app.post("/optimize", status_code=202)
def trigger_optimization():
    """
    Triggers a new optimization run.
    This endpoint starts the optimizer script as a background process.
    """
    run_id = str(uuid.uuid4())
    print(f"Starting optimization run with ID: {run_id}")

    # In a real-world scenario, this would be a robust job queue (e.g., Celery, RQ)
    # For this reference implementation, we use a simple subprocess.
    subprocess.Popen(["python", "/app/main.py", run_id], cwd="/optimizer")

    return {"message": "Optimization run started", "run_id": run_id}

@app.get("/results/{run_id}", response_model=OptimizationResult)
def get_results(run_id: str):
    """
    Retrieves the results of a specific optimization run.
    """
    with engine.connect() as connection:
        # Get Run Details
        run_query = text("SELECT run_id, run_timestamp, status, total_cost FROM optimization_runs WHERE run_id = :run_id")
        run_result = connection.execute(run_query, {"run_id": run_id}).fetchone()

        if not run_result:
            raise HTTPException(status_code=404, detail="Run ID not found")

        run_details = dict(run_result)

        # Get Shipment Results
        shipments_query = text("""
            SELECT origin_facility_id, destination_id, product_id, quantity_shipped
            FROM optimal_shipments WHERE run_id = :run_id
        """)
        shipments_result = connection.execute(shipments_query, {"run_id": run_id}).fetchall()
        shipments = [dict(row) for row in shipments_result]

        # Get Production Results
        production_query = text("""
            SELECT facility_id, product_id, quantity_produced
            FROM optimal_production WHERE run_id = :run_id
        """)
        production_result = connection.execute(production_query, {"run_id": run_id}).fetchall()
        production = [dict(row) for row in production_result]

    return {
        "run_details": run_details,
        "shipments": shipments,
        "production": production
    }

@app.get("/analytics/{view_name}")
def get_analytics_view(view_name: str):
    """
    A generic endpoint to query pre-built analytical views.
    Example view_name: 'cost_to_serve', 'stockout_risk'
    """
    allowed_views = ["cost_to_serve", "service_level_by_customer", "stockout_risk"]
    if view_name not in allowed_views:
        raise HTTPException(status_code=400, detail="Invalid analytical view name.")

    with engine.connect() as connection:
        query = text(f"SELECT * FROM {view_name}") # Be cautious with direct string formatting in real apps
        result = connection.execute(query).fetchall()
        return [dict(row) for row in result]

