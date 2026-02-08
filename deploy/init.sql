-- ═══════════════════════════════════════════════════════════════
-- Selcom IoT Hub - Inicialización de Base de Datos
-- ═══════════════════════════════════════════════════════════════

-- Crear tablas principales

CREATE TABLE IF NOT EXISTS companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    logo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    full_name VARCHAR(255),
    role ENUM('admin', 'operator', 'viewer') DEFAULT 'viewer',
    company_id INT,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    INDEX idx_username (username),
    INDEX idx_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    description TEXT,
    company_id INT,
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    status ENUM('online', 'offline', 'maintenance', 'error') DEFAULT 'offline',
    last_seen TIMESTAMP NULL,
    maintenance_mode BOOLEAN DEFAULT FALSE,
    calibration_offset DECIMAL(10, 4) DEFAULT 0,
    expected_interval_seconds INT DEFAULT 300,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    INDEX idx_device_id (device_id),
    INDEX idx_company (company_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    sensor_type VARCHAR(50),
    value DECIMAL(20, 6),
    unit VARCHAR(20),
    raw_value DECIMAL(20, 6),
    quality ENUM('good', 'uncertain', 'bad') DEFAULT 'good',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_timestamp (device_id, timestamp),
    INDEX idx_timestamp (timestamp),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS alarms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    alarm_type VARCHAR(100),
    severity ENUM('info', 'low', 'medium', 'high', 'critical') DEFAULT 'medium',
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT NULL,
    acknowledged_at TIMESTAMP NULL,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_device (device_id),
    INDEX idx_severity (severity),
    INDEX idx_acknowledged (acknowledged)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    updated_by INT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_device_config (device_id, config_key),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS event_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100),
    user_id INT,
    event_type ENUM('config_change', 'alarm', 'maintenance', 'calibration', 'login', 'logout', 'device_create', 'device_update', 'device_delete') NOT NULL,
    description TEXT,
    old_value TEXT,
    new_value TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_device (device_id),
    INDEX idx_user (user_id),
    INDEX idx_type (event_type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_id VARCHAR(100),
    notification_type ENUM('email', 'whatsapp', 'push') NOT NULL,
    severity_threshold ENUM('info', 'low', 'medium', 'high', 'critical') DEFAULT 'medium',
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_device_type (user_id, device_id, notification_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════
-- Datos iniciales
-- ═══════════════════════════════════════════════════════════════

-- Empresa demo
INSERT INTO companies (name, address, contact_email) VALUES 
('Selcom IoT', 'Santiago, Chile', 'info@selcom.cl')
ON DUPLICATE KEY UPDATE name = name;

-- Usuario admin por defecto (password: admin123)
-- Hash generado con password_hash('admin123', PASSWORD_BCRYPT)
INSERT INTO users (username, password_hash, email, full_name, role, company_id) VALUES 
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@selcom.cl', 'Administrador', 'admin', 1)
ON DUPLICATE KEY UPDATE username = username;

-- Dispositivo de demostración
INSERT INTO devices (device_id, name, type, description, company_id, location, status, firmware_version) VALUES 
('DEMO-TEMP-001', 'Sensor Temperatura Demo', 'temperature', 'Sensor de temperatura para demostración del sistema', 1, 'Oficina Principal', 'online', '1.0.0'),
('DEMO-HUM-001', 'Sensor Humedad Demo', 'humidity', 'Sensor de humedad para demostración del sistema', 1, 'Bodega', 'online', '1.0.0')
ON DUPLICATE KEY UPDATE device_id = device_id;

-- Datos de ejemplo para gráficos
INSERT INTO sensor_data (device_id, sensor_type, value, unit, timestamp) VALUES
('DEMO-TEMP-001', 'temperature', 22.5, '°C', DATE_SUB(NOW(), INTERVAL 5 HOUR)),
('DEMO-TEMP-001', 'temperature', 23.1, '°C', DATE_SUB(NOW(), INTERVAL 4 HOUR)),
('DEMO-TEMP-001', 'temperature', 24.0, '°C', DATE_SUB(NOW(), INTERVAL 3 HOUR)),
('DEMO-TEMP-001', 'temperature', 23.5, '°C', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
('DEMO-TEMP-001', 'temperature', 22.8, '°C', DATE_SUB(NOW(), INTERVAL 1 HOUR)),
('DEMO-TEMP-001', 'temperature', 22.3, '°C', NOW()),
('DEMO-HUM-001', 'humidity', 45.0, '%', DATE_SUB(NOW(), INTERVAL 5 HOUR)),
('DEMO-HUM-001', 'humidity', 48.2, '%', DATE_SUB(NOW(), INTERVAL 4 HOUR)),
('DEMO-HUM-001', 'humidity', 52.1, '%', DATE_SUB(NOW(), INTERVAL 3 HOUR)),
('DEMO-HUM-001', 'humidity', 50.5, '%', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
('DEMO-HUM-001', 'humidity', 47.8, '%', DATE_SUB(NOW(), INTERVAL 1 HOUR)),
('DEMO-HUM-001', 'humidity', 46.3, '%', NOW());

SELECT '✅ Base de datos Selcom IoT Hub inicializada correctamente' AS resultado;
