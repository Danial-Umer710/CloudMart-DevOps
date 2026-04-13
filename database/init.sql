CREATE DATABASE IF NOT EXISTS cloudmart;
USE cloudmart;

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Sample products data
INSERT INTO products (name, description, price, stock, category) VALUES
('Laptop', 'High performance laptop', 999.99, 50, 'Electronics'),
('Phone', 'Latest smartphone', 699.99, 100, 'Electronics'),
('Headphones', 'Noise cancelling headphones', 199.99, 75, 'Electronics'),
('Desk Chair', 'Ergonomic office chair', 299.99, 30, 'Furniture'),
('Monitor', '4K Ultra HD monitor', 449.99, 45, 'Electronics'),
('Gaming Mouse', 'RGB wireless gaming mouse', 49.99, 50, 'Accessories'),
('Mechanical Keyboard', 'Blue switch mechanical keyboard', 89.99, 30, 'Accessories'),
('Webcam 4K', 'Ultra HD webcam for streaming', 129.99, 20, 'Electronics');
