-- ERP Service Schema
CREATE TABLE IF NOT EXISTS employees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(100),
    department VARCHAR(100),
    salary DECIMAL(15,2),
    hire_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(255),
    country VARCHAR(100),
    contract_start DATE,
    contract_end DATE
);

CREATE TABLE IF NOT EXISTS accounting_entries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'XAF',
    type VARCHAR(10) NOT NULL,
    date DATE,
    reference VARCHAR(100)
);
