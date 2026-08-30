# BLOCK Database

Database layer for the BLOCKSYNC Automatic Block Planning System.

## Purpose

This database stores:

- Railway departments
- Corridors and sections
- Railway assets
- Train movements
- Available block windows
- Maintenance tasks
- Maintenance resources
- Task compatibility rules
- Optimization constraints
- Generated block plans
- Block assignments
- Unscheduled tasks

## Database Architecture

Input Data
    ↓
PostgreSQL / Supabase
    ↓
Backend API
    ↓
OR-Tools Optimization Engine
    ↓
Optimized Block Plan
    ↓
Frontend Gantt Chart

## Files

### schema.sql

Contains the PostgreSQL table definitions and relationships.

### seed/

Contains CSV files used to populate the database with demo data.

## Demo Scenarios

The dataset supports three main scenarios:

1. Integrated Block
   - Track + OHE maintenance can be coordinated.

2. Safety Priority
   - Higher-criticality maintenance receives priority.

3. Impossible Task
   - A task requiring more time than any available window remains unscheduled.

## Setup

1. Create a Supabase PostgreSQL project.
2. Open SQL Editor.
3. Run `schema.sql`.
4. Import the CSV files from `seed/`.
5. Connect the backend API to the database.