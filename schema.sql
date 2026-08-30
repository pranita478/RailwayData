CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE corridors (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    traffic_weight FLOAT NOT NULL DEFAULT 1.0
);

CREATE TABLE sections (
    id SERIAL PRIMARY KEY,
    corridor_id INTEGER NOT NULL REFERENCES corridors(id),
    code VARCHAR(20) UNIQUE NOT NULL,
    from_station VARCHAR(50) NOT NULL,
    to_station VARCHAR(50) NOT NULL,
    length_km FLOAT,
    line_type VARCHAR(30),
    electrified BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE assets (
    id VARCHAR(30) PRIMARY KEY,
    section_id INTEGER NOT NULL REFERENCES sections(id),
    department_id INTEGER NOT NULL REFERENCES departments(id),
    asset_type VARCHAR(50) NOT NULL,
    asset_name VARCHAR(100) NOT NULL,
    asset_criticality INTEGER NOT NULL CHECK (asset_criticality BETWEEN 1 AND 5),
    status VARCHAR(30) NOT NULL DEFAULT 'Operational'
);

CREATE TABLE trains (
    id VARCHAR(30) PRIMARY KEY,
    train_number VARCHAR(20) UNIQUE NOT NULL,
    train_type VARCHAR(50),
    priority_class VARCHAR(30)
);

CREATE TABLE train_movements (
    id VARCHAR(40) PRIMARY KEY,
    train_id VARCHAR(30) NOT NULL REFERENCES trains(id),
    section_id INTEGER NOT NULL REFERENCES sections(id),
    service_date DATE NOT NULL,
    entry_time TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_time TIMESTAMP WITH TIME ZONE NOT NULL,
    movement_status VARCHAR(30) NOT NULL DEFAULT 'Scheduled',
    CHECK (exit_time > entry_time)
);

CREATE TABLE block_windows (
    id VARCHAR(40) PRIMARY KEY,
    section_id INTEGER NOT NULL REFERENCES sections(id),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_min INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60
    ) STORED,
    availability_status VARCHAR(30) NOT NULL DEFAULT 'Available',
    CHECK (end_time > start_time)
);

CREATE TABLE maintenance_tasks (
    id VARCHAR(30) PRIMARY KEY,

    department_id INTEGER NOT NULL
        REFERENCES departments(id),

    asset_id VARCHAR(30) NOT NULL
        REFERENCES assets(id),

    defect_type VARCHAR(100) NOT NULL,

    severity INTEGER NOT NULL
        CHECK (severity BETWEEN 1 AND 5),

    days_overdue INTEGER NOT NULL DEFAULT 0
        CHECK (days_overdue >= 0),

    est_duration_min INTEGER NOT NULL
        CHECK (est_duration_min > 0),

    requested_start TIMESTAMP WITH TIME ZONE,

    requested_end TIMESTAMP WITH TIME ZONE,

    criticality_score FLOAT,

    status VARCHAR(30) NOT NULL DEFAULT 'Pending',

    is_safety_critical BOOLEAN NOT NULL DEFAULT FALSE,

    FOREIGN KEY (department_id)
        REFERENCES departments(id),

    CHECK (
        requested_end IS NULL
        OR requested_start IS NULL
        OR requested_end > requested_start
    )
);

CREATE TABLE task_compatibility (
    id SERIAL PRIMARY KEY,

    task_id_1 VARCHAR(30) NOT NULL
        REFERENCES maintenance_tasks(id),

    task_id_2 VARCHAR(30) NOT NULL
        REFERENCES maintenance_tasks(id),

    compatible BOOLEAN NOT NULL DEFAULT FALSE,

    compatibility_reason VARCHAR(255),

    UNIQUE (task_id_1, task_id_2),

    CHECK (task_id_1 <> task_id_2)
);

CREATE TABLE resources (
    id VARCHAR(30) PRIMARY KEY,

    department_id INTEGER NOT NULL
        REFERENCES departments(id),

    resource_name VARCHAR(100) NOT NULL,

    resource_type VARCHAR(50) NOT NULL,

    capacity INTEGER NOT NULL DEFAULT 1
        CHECK (capacity > 0),

    availability_status VARCHAR(30) NOT NULL DEFAULT 'Available'
);

CREATE TABLE task_resource_requirements (
    id SERIAL PRIMARY KEY,

    task_id VARCHAR(30) NOT NULL
        REFERENCES maintenance_tasks(id),

    resource_id VARCHAR(30) NOT NULL
        REFERENCES resources(id),

    quantity INTEGER NOT NULL DEFAULT 1
        CHECK (quantity > 0),

    UNIQUE (task_id, resource_id)
);

CREATE TABLE constraints (
    id SERIAL PRIMARY KEY,

    constraint_code VARCHAR(50) UNIQUE NOT NULL,

    constraint_name VARCHAR(100) NOT NULL,

    description TEXT NOT NULL,

    constraint_type VARCHAR(50) NOT NULL,

    is_hard_constraint BOOLEAN NOT NULL DEFAULT TRUE,

    penalty_weight FLOAT DEFAULT 0
);


CREATE TABLE block_plans (
    id VARCHAR(50) PRIMARY KEY,

    plan_name VARCHAR(100),

    planning_horizon VARCHAR(30) NOT NULL,

    horizon_start TIMESTAMP WITH TIME ZONE NOT NULL,

    horizon_end TIMESTAMP WITH TIME ZONE NOT NULL,

    generated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    optimization_status VARCHAR(30) NOT NULL DEFAULT 'Generated',

    objective_score FLOAT,

    CHECK (horizon_end > horizon_start)
);

CREATE TABLE block_assignments (
    id SERIAL PRIMARY KEY,

    plan_id VARCHAR(50) NOT NULL
        REFERENCES block_plans(id),

    task_id VARCHAR(30) NOT NULL
        REFERENCES maintenance_tasks(id),

    window_id VARCHAR(40) NOT NULL
        REFERENCES block_windows(id),

    assigned_start TIMESTAMP WITH TIME ZONE NOT NULL,

    assigned_end TIMESTAMP WITH TIME ZONE NOT NULL,

    is_integrated BOOLEAN NOT NULL DEFAULT FALSE,

    integration_group_id VARCHAR(50),

    ai_explanation TEXT,

    assignment_score FLOAT,

    CHECK (assigned_end > assigned_start)
);

CREATE TABLE unscheduled_tasks (
    id SERIAL PRIMARY KEY,

    plan_id VARCHAR(50) NOT NULL
        REFERENCES block_plans(id),

    task_id VARCHAR(30) NOT NULL
        REFERENCES maintenance_tasks(id),

    reason_code VARCHAR(50) NOT NULL,

    reason TEXT NOT NULL,

    priority_at_failure FLOAT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sections_corridor
    ON sections(corridor_id);

CREATE INDEX idx_assets_section
    ON assets(section_id);

CREATE INDEX idx_assets_department
    ON assets(department_id);

CREATE INDEX idx_train_movements_section
    ON train_movements(section_id);

CREATE INDEX idx_train_movements_time
    ON train_movements(entry_time, exit_time);

CREATE INDEX idx_block_windows_section
    ON block_windows(section_id);

CREATE INDEX idx_block_windows_time
    ON block_windows(start_time, end_time);

CREATE INDEX idx_tasks_department
    ON maintenance_tasks(department_id);

CREATE INDEX idx_tasks_asset
    ON maintenance_tasks(asset_id);

CREATE INDEX idx_tasks_status
    ON maintenance_tasks(status);

CREATE INDEX idx_tasks_criticality
    ON maintenance_tasks(criticality_score);

CREATE INDEX idx_assignments_plan
    ON block_assignments(plan_id);

CREATE INDEX idx_unscheduled_plan
    ON unscheduled_tasks(plan_id);