#!/bin/bash

#===============================================================================
# SELCOM IoT Hub - Script de Instalación Automática para Coolify
# 
# Este script instala y configura automáticamente:
# - Coolify (plataforma de hosting)
# - Docker y Docker Compose
# - MySQL Database
# - Tu aplicación Selcom IoT Hub
#
# Uso: curl -fsSL https://raw.githubusercontent.com/flopezlopezureta/selcom-iot-hub-git/main/deploy/install-coolify.sh | sudo bash
#===============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
DOMAIN=""
GEMINI_API_KEY=""
DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 16)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 16)

#===============================================================================
# Funciones de utilidad
#===============================================================================

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║          SELCOM IoT Hub - Instalador Automático              ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[i] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Este script debe ejecutarse como root (usa sudo)"
        exit 1
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            print_error "Este script solo funciona en Ubuntu o Debian"
            exit 1
        fi
    else
        print_error "No se pudo detectar el sistema operativo"
        exit 1
    fi
    print_step "Sistema operativo compatible: $PRETTY_NAME"
}

get_user_input() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                    CONFIGURACIÓN INICIAL                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Dominio
    read -p "Ingresa tu dominio (ej: regentry.cl): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        print_error "El dominio es requerido"
        exit 1
    fi
    
    # API Key de Gemini
    read -p "Ingresa tu API Key de Google Gemini: " GEMINI_API_KEY
    if [ -z "$GEMINI_API_KEY" ]; then
        print_warning "Sin API Key de Gemini, la generación de firmware AI no funcionará"
    fi
    
    echo ""
    print_info "Configuración:"
    echo "  - Dominio: $DOMAIN"
    echo "  - Gemini API Key: ${GEMINI_API_KEY:0:10}..."
    echo "  - DB Password: $DB_PASSWORD (generada automáticamente)"
    echo ""
    
    read -p "¿Continuar con la instalación? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" && "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "Instalación cancelada"
        exit 0
    fi
}

#===============================================================================
# Instalación de dependencias
#===============================================================================

install_dependencies() {
    print_step "Actualizando sistema..."
    apt update -qq
    apt upgrade -y -qq
    
    print_step "Instalando dependencias básicas..."
    apt install -y -qq curl wget git unzip apt-transport-https ca-certificates gnupg lsb-release
}

#===============================================================================
# Instalación de Docker
#===============================================================================

install_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker ya está instalado"
        return
    fi
    
    print_step "Instalando Docker..."
    
    # Agregar repositorio oficial de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt update -qq
    apt install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Iniciar Docker
    systemctl start docker
    systemctl enable docker
    
    print_step "Docker instalado correctamente"
}

#===============================================================================
# Instalación de Coolify
#===============================================================================

install_coolify() {
    print_step "Instalando Coolify..."
    
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
    
    print_step "Coolify instalado correctamente"
}

#===============================================================================
# Configuración del proyecto Selcom IoT Hub
#===============================================================================

setup_selcom_project() {
    print_step "Configurando proyecto Selcom IoT Hub..."
    
    PROJECT_DIR="/opt/selcom-iot-hub"
    
    # Crear directorio del proyecto
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Clonar repositorio
    if [ -d ".git" ]; then
        print_info "Repositorio ya existe, actualizando..."
        git pull
    else
        git clone https://github.com/flopezlopezureta/selcom-iot-hub-git.git .
    fi
    
    # Crear archivo .env
    cat > .env << EOF
# Configuración de Base de Datos
DB_HOST=mysql
DB_NAME=selcom_iot
DB_USER=selcom
DB_PASS=$DB_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# Configuración de API
GEMINI_API_KEY=$GEMINI_API_KEY

# Configuración del Dominio
DOMAIN=$DOMAIN
EOF

    print_step "Proyecto configurado en $PROJECT_DIR"
}

#===============================================================================
# Creación de docker-compose.yml
#===============================================================================

create_docker_compose() {
    print_step "Creando configuración de Docker Compose..."
    
    cat > /opt/selcom-iot-hub/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Base de datos MySQL
  mysql:
    image: mysql:8.0
    container_name: selcom-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASS}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./deploy/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Aplicación PHP + React
  app:
    build:
      context: .
      dockerfile: deploy/Dockerfile
    container_name: selcom-app
    restart: unless-stopped
    environment:
      DB_HOST: mysql
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASS: ${DB_PASS}
      GEMINI_API_KEY: ${GEMINI_API_KEY}
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - ./logs:/var/log/apache2

  # phpMyAdmin (opcional, para administrar la BD)
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: selcom-phpmyadmin
    restart: unless-stopped
    environment:
      PMA_HOST: mysql
      PMA_USER: ${DB_USER}
      PMA_PASSWORD: ${DB_PASS}
    ports:
      - "8080:80"
    depends_on:
      - mysql

volumes:
  mysql_data:
EOF

    print_step "docker-compose.yml creado"
}

#===============================================================================
# Creación del Dockerfile
#===============================================================================

create_dockerfile() {
    print_step "Creando Dockerfile..."
    
    mkdir -p /opt/selcom-iot-hub/deploy
    
    cat > /opt/selcom-iot-hub/deploy/Dockerfile << 'EOF'
FROM php:8.2-apache

# Instalar extensiones PHP necesarias
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install mysqli pdo pdo_mysql zip gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Habilitar mod_rewrite para .htaccess
RUN a2enmod rewrite headers

# Configurar Apache para permitir .htaccess
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Crear directorio para la aplicación
WORKDIR /var/www/html

# Copiar archivos de la aplicación
COPY dist/ /var/www/html/
COPY public/api/ /var/www/html/api/
COPY public/.htaccess /var/www/html/.htaccess

# Crear archivo .env para la API
RUN mkdir -p /var/www/html/api

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Exponer puerto 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["apache2-foreground"]
EOF

    print_step "Dockerfile creado"
}

#===============================================================================
# Creación del script de inicialización de BD
#===============================================================================

create_init_sql() {
    print_step "Creando script de inicialización de base de datos..."
    
    cat > /opt/selcom-iot-hub/deploy/init.sql << 'EOF'
-- Selcom IoT Hub - Inicialización de Base de Datos

-- Crear tablas
CREATE TABLE IF NOT EXISTS companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role ENUM('admin', 'operator', 'viewer') DEFAULT 'viewer',
    company_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL
);

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
    status ENUM('online', 'offline', 'maintenance') DEFAULT 'offline',
    last_seen TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    sensor_type VARCHAR(50),
    value DECIMAL(20, 6),
    unit VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_timestamp (device_id, timestamp),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS alarms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    alarm_type VARCHAR(100),
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT NULL,
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS device_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_device_config (device_id, config_key),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Insertar datos iniciales
INSERT INTO companies (name, address, contact_email) VALUES 
('Selcom Demo', 'Santiago, Chile', 'demo@selcom.cl');

-- Usuario admin por defecto (password: admin123)
INSERT INTO users (username, password_hash, email, role, company_id) VALUES 
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@selcom.cl', 'admin', 1);

-- Dispositivo de ejemplo
INSERT INTO devices (device_id, name, type, description, company_id, location, status) VALUES 
('DEMO-001', 'Sensor de Temperatura Demo', 'temperature', 'Dispositivo de demostración', 1, 'Oficina Central', 'online');

SELECT 'Base de datos inicializada correctamente' AS message;
EOF

    print_step "Script SQL creado"
}

#===============================================================================
# Instalación de Cloudflare Tunnel
#===============================================================================

setup_cloudflare_tunnel() {
    print_step "Configurando Cloudflare Tunnel..."
    
    print_warning "Para completar la configuración de Cloudflare Tunnel:"
    echo ""
    echo "1. Ve a: https://dash.cloudflare.com"
    echo "2. Zero Trust → Networks → Tunnels"
    echo "3. Create a tunnel"
    echo "4. Nombre: selcom-tunnel"
    echo "5. Copia el comando de instalación y ejecútalo aquí"
    echo ""
    
    read -p "¿Ya configuraste el tunnel en Cloudflare? (s/n): " cf_ready
    
    if [[ "$cf_ready" == "s" || "$cf_ready" == "S" ]]; then
        read -p "Pega el token del tunnel: " CF_TOKEN
        
        if [ -n "$CF_TOKEN" ]; then
            # Instalar cloudflared
            curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            dpkg -i cloudflared.deb
            rm cloudflared.deb
            
            # Instalar servicio
            cloudflared service install $CF_TOKEN
            
            print_step "Cloudflare Tunnel configurado"
        fi
    else
        print_info "Puedes configurar Cloudflare Tunnel más tarde"
    fi
}

#===============================================================================
# Iniciar servicios
#===============================================================================

start_services() {
    print_step "Construyendo e iniciando servicios..."
    
    cd /opt/selcom-iot-hub
    
    # Construir imágenes
    docker compose build
    
    # Iniciar servicios
    docker compose up -d
    
    print_step "Servicios iniciados"
}

#===============================================================================
# Mostrar resumen final
#===============================================================================

show_summary() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}║          ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!               ║${NC}"
    echo -e "${GREEN}║                                                               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                      INFORMACIÓN DE ACCESO                     ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  🌐 Aplicación Web:"
    echo "     - Local: http://$SERVER_IP"
    echo "     - Dominio: https://$DOMAIN (después de configurar DNS)"
    echo ""
    echo "  🔧 Coolify Panel:"
    echo "     - URL: http://$SERVER_IP:8000"
    echo ""
    echo "  📊 phpMyAdmin:"
    echo "     - URL: http://$SERVER_IP:8080"
    echo ""
    echo "  👤 Credenciales por defecto:"
    echo "     - Usuario: admin"
    echo "     - Contraseña: admin123"
    echo "     - ⚠️  ¡CAMBIA LA CONTRASEÑA INMEDIATAMENTE!"
    echo ""
    echo "  🗄️ Base de datos MySQL:"
    echo "     - Host: localhost:3306"
    echo "     - Database: selcom_iot"
    echo "     - Usuario: selcom"
    echo "     - Contraseña: $DB_PASSWORD"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                      PRÓXIMOS PASOS                            ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1. Accede a http://$SERVER_IP y verifica que funciona"
    echo "  2. Configura Cloudflare Tunnel para acceso externo"
    echo "  3. Cambia la contraseña del usuario admin"
    echo "  4. Configura backups automáticos"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Guardar credenciales en archivo
    cat > /opt/selcom-iot-hub/CREDENCIALES.txt << EOF
═══════════════════════════════════════════════════════════════
         SELCOM IoT Hub - Credenciales de Instalación
═══════════════════════════════════════════════════════════════

Fecha de instalación: $(date)
Servidor: $SERVER_IP
Dominio: $DOMAIN

ACCESOS:
--------
Aplicación Web: http://$SERVER_IP (o https://$DOMAIN)
Coolify Panel: http://$SERVER_IP:8000
phpMyAdmin: http://$SERVER_IP:8080

USUARIO ADMIN:
--------------
Usuario: admin
Contraseña: admin123
⚠️ CAMBIA ESTA CONTRASEÑA INMEDIATAMENTE

BASE DE DATOS MySQL:
--------------------
Host: localhost
Puerto: 3306
Database: selcom_iot
Usuario: selcom
Contraseña: $DB_PASSWORD
Root Password: $MYSQL_ROOT_PASSWORD

API KEYS:
---------
Gemini API Key: $GEMINI_API_KEY

═══════════════════════════════════════════════════════════════
⚠️ GUARDA ESTE ARCHIVO EN UN LUGAR SEGURO Y LUEGO ELIMÍNALO
═══════════════════════════════════════════════════════════════
EOF

    print_info "Las credenciales se guardaron en: /opt/selcom-iot-hub/CREDENCIALES.txt"
    print_warning "¡Guarda este archivo en un lugar seguro y luego elimínalo!"
}

#===============================================================================
# Función principal
#===============================================================================

main() {
    print_banner
    check_root
    check_os
    get_user_input
    install_dependencies
    install_docker
    setup_selcom_project
    create_dockerfile
    create_docker_compose
    create_init_sql
    start_services
    setup_cloudflare_tunnel
    show_summary
}

# Ejecutar
main "$@"
