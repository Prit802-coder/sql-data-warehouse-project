# sql-data-warehouse-project
Building A Modern Data Warehouse With SQL Server ,Including ETL Process, Data Modelling, And Analytics 

# Objectives
Consolidate data from multiple source files or systems.

Clean, standardize, and validate data through ETL processes.

Build a dimensional model using fact and dimension tables.

Deliver business-ready datasets for reporting and analysis.

Maintain clear data lineage from raw data to final reporting tables.

# Architecture
The project follows a layered data-warehouse approach:

text
Source Data
    ↓
Bronze Layer — Raw data ingestion
    ↓
Silver Layer — Cleaned and standardized data
    ↓
Gold Layer — Business-ready dimensional model
    ↓
Analytics / Reporting
This separation keeps raw data intact while making transformations traceable and easier to test. Star-schema models commonly place fact tables at the center, connected to descriptive dimension tables.

# Data Model
Dimension tables: Store descriptive attributes, such as customer, product, date, location, or employee details.

Fact tables: Store measurable business events, such as sales quantity, revenue, cost, orders, or transactions.

Surrogate keys: Integer warehouse-generated keys used to connect dimensions and facts reliably.

Example:

text
dim_customers
dim_products
dim_dates
dim_locations
        ↓
     fact_sales
Repository Structure
text
├── datasets/           # Raw source files
├── docs/               # Architecture, data model, and documentation
├── scripts/
│   ├── init_database.sql
│   ├── bronze/         # Raw-layer tables and load procedures
│   ├── silver/         # Cleaning and transformation scripts
│   └── gold/           # Dimensions, facts, and reporting views
├── tests/              # Data-quality and validation queries
└── README.md
Keeping datasets, documentation, scripts, and tests separated makes a warehouse project easier to maintain and review.

# ETL Process
Extract: Load data from CSV files, source databases, or APIs.

Load to Bronze: Preserve raw source records with minimal changes.

Transform to Silver: Remove duplicates, handle missing values, standardize formats, and apply business rules.

Load to Gold: Create dimensions and fact tables for analytics.

Validate: Check row counts, null values, duplicates, referential integrity, and business totals.

# Technologies
Microsoft SQL Server

SQL Server Management Studio (SSMS)

T-SQL

CSV / source datasets

Git and GitHub for version control

# Quality Standards
Avoid changing original raw data after ingestion.

Use repeatable scripts and stored procedures for loads.

Document every source, transformation, and business rule.

Test data for completeness, accuracy, and duplicate records.

Use meaningful names and consistent naming conventions.

A strong warehouse design begins with business requirements, then moves from logical modeling to physical implementation.

# How to Run
Create the database using scripts/init_database.sql.

Run the Bronze-layer table and load scripts.

Run Silver-layer transformation scripts.

Run Gold-layer dimension and fact table scripts.

Execute validation queries in the tests/ folder.

Connect reporting tools to the Gold layer.

# Project Outcome
This project delivers a structured SQL Server data warehouse that converts raw operational data into trusted analytical data. The final Gold layer supports reporting, KPI analysis, trend analysis, and data-driven business decisions.
