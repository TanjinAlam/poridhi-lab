#!/bin/bash
exec > >(tee /var/log/mysql-setup.log) 2>&1 # Log output to file

# Update system
apt update
apt upgrade -y

# Install MySQL server
apt-get install -y mysql-server

# Configure MySQL to allow remote connections
sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Create database
mysql -e "CREATE DATABASE app_db;"

# Create user with privileges
mysql -e "CREATE USER 'app_user'@'%' IDENTIFIED BY 'app_user';"
mysql -e "GRANT ALL PRIVILEGES ON app_db.* TO 'app_user'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Create users table and insert sample data
mysql app_db -e "
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL
);

INSERT INTO users (name, email) VALUES 
  ('John Doe', 'john.doe@example.com'),
  ('Jane Smith', 'jane.smith@example.com'),
  ('Robert Johnson', 'robert.johnson@example.com');
"

# Restart MySQL
systemctl restart mysql

echo "MySQL setup complete with database, users table, and sample data."