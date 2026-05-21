-- Supply Chain Service Schema
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(20),
    origin VARCHAR(100),
    unit VARCHAR(50),
    current_stock INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS shipments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    origin VARCHAR(255),
    destination VARCHAR(255),
    quantity INT,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_TRANSIT',
    departure_date DATE,
    arrival_date DATE,
    tracking_code VARCHAR(100) UNIQUE
);

CREATE TABLE IF NOT EXISTS checkpoints (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shipment_id BIGINT NOT NULL,
    location VARCHAR(255),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent_name VARCHAR(255),
    note TEXT
);
