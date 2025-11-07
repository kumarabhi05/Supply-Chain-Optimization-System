# Supply Chain Optimization System

This repository contains a complete, containerized reference implementation for a **supply chain network optimization system**. It's designed as a robust starting point for building sophisticated logistics and planning tools.

---

## 🚀 Features

- **PostgreSQL Database**: Includes a detailed schema, seed data, analytical views, and functions to model a realistic supply chain.
- **Optimization Engine**: A powerful Python-based engine using **Google OR-Tools** to solve complex network flow, production, and inventory problems.
- **FastAPI Backend**: A modern, high-performance API to trigger optimization runs and retrieve results and analytical reports.
- **Containerized with Docker**: The entire stack (database, backend, optimizer) is managed with Docker Compose for easy, one-command setup.
- **Advanced SQL Analytics**: Pre-built views for critical KPIs like **Cost-to-Serve**, **Service Level**, and **Stockout Risk**.
- **Extensible by Design**: Use this as a foundation and customize the models, data schema, and API endpoints to fit your specific needs.

---

## 🧱 System Architecture

The system consists of three main containerized services orchestrated by **docker-compose.yml**:

- **db (PostgreSQL)**: The central database that stores all supply chain data, including facilities, products, orders, and optimization results. It is initialized with a schema and seed data.
- **backend (FastAPI)**: The user-facing API. It provides endpoints to start new optimization runs and query the results. It communicates with both the database and the optimizer service.
- **optimizer (Python + OR-Tools)**: A headless service that contains the core mathematical optimization logic. When triggered by the API, it reads the latest data from the database, solves the optimization problem, and writes the results back to the database.

---

## 🧩 Getting Started

### Prerequisites
- Docker
- Docker Compose

### Installation & Setup

#### 1. Clone the repository:
```bash
git clone <your-repository-url>
cd <repository-name>
```

#### 2. Build and run the containers:
This single command will build the images for the backend and optimizer services, start all containers, and initialize the database.

```bash
docker-compose up --build
```

You should see logs from all three services. The database will initialize, and the backend API will become available at:
- **API Docs (Swagger UI):** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Frontend Dashboard:** [http://localhost:8081](http://localhost:8081)

---

## ⚙️ How to Use the API

You can interact with the API using tools like **curl**, **Postman**, or by navigating to the interactive Swagger documentation.

### 1. Trigger an Optimization Run
Send a POST request to the `/optimize` endpoint. This will start the optimization process in the background.

**Request:**
```bash
curl -X POST http://localhost:8000/optimize
```

**Response:**
```json
{
  "message": "Optimization run started",
  "run_id": "a1b2c3d4-e5f6-7890-1234-567890abcdef"
}
```

### 2. Retrieve Optimization Results
Once the run is complete (it may take a minute), use the `run_id` from the previous step to fetch the results.

**Request:**
```bash
curl -X GET http://localhost:8000/results/a1b2c3d4-e5f6-7890-1234-567890abcdef
```

---

## 📂 Project Structure
```
.
├── backend/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── db/
│   └── init/
│       ├── 0_init.sh
│       ├── 1_schema.sql
│       ├── 2_seed_data.sql
│       └── 3_views.sql
├── frontend/
│   └── index.html
├── optimizer/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── docker-compose.yml
└── README.md
```

---

### 🧠 Summary
This system provides a **ready-to-use architecture** for modeling and optimizing supply chains, featuring a **PostgreSQL database**, **Python optimization engine (OR-Tools)**, and **FastAPI backend**, all containerized with **Docker Compose** for simple deployment and scalability.

