#!/bin/bash

# Check if .env.example exists
if [ ! -f .env.example ]; then
    echo "Error: .env.example file not found"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
fi

update_nginx_conf() {
    local DOMAIN=$1
    local NGINX_CONF="nginx.conf.example"
    local TARGET_DIR="/etc/nginx/sites-available/${DOMAIN}/server"
    local TARGET_FILE="${TARGET_DIR}/admin-paheko.conf"

    # Check if file exists
    if [ ! -f "$NGINX_CONF" ]; then
        echo "Error: $NGINX_CONF not found in current directory"
        exit 1
    fi

    # Check if running with sudo/root privileges
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Please run with sudo privileges"
        exit 1
    fi

    # Create directory if it doesn't exist
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Creating directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi

    # Replace {DOMAIN} with actual domain and copy to target location
    echo "Configuring nginx for domain: $DOMAIN"
    sed "s/{DOMAIN}/${DOMAIN}/g" "$NGINX_CONF" > "$TARGET_FILE"

    # Set proper permissions
    chown root:root "$TARGET_FILE"
    chmod 644 "$TARGET_FILE"

    # Test nginx configuration
    echo "Testing nginx configuration..."
    nginx -t

    if [ $? -eq 0 ]; then
        echo "Nginx configuration test passed"
        echo "Reloading nginx..."
        systemctl reload nginx
        echo "Setup completed successfully!"
        echo "Your nginx configuration is now available at: $TARGET_FILE"
    else
        echo "Error: Nginx configuration test failed"
        echo "Please check your configuration and try again"
        exit 1
    fi
}

# Function to update or add a variable in .env file
update_env_var() {
    local key=$1
    local value=$2
    
    # Check if variable exists in .env
    if grep -q "^${key}=" .env; then
        # Update existing variable
        sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
        # Add new variable
        echo "${key}=${value}" >> .env
    fi
}

# Check if any parameters were provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 KEY1=value1 KEY2=value2 ..."
    echo "Example: $0 DB_HOST=localhost DB_PORT=5432"
    exit 1
fi

# Process each parameter
for param in "$@"; do
    # Check if parameter follows KEY=value format
    if [[ $param =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Check if key exists in .env.example
        if grep -q "^${key}=" .env.example; then
            update_env_var "$key" "$value"
            echo "Updated $key in .env"
        else
            echo "Warning: $key not found in .env.example, skipping..."
        fi

        if [ $key == "DOMAIN" ]; then
            update_nginx_conf "$value"
        fi
    else
        echo "Warning: Invalid parameter format: $param (should be KEY=value)"
    fi
done

echo "Environment variables have been updated successfully!"

apt install make
make -C public/content/mu-plugins/wp-paheko modules
make -C public/content/mu-plugins/wp-paheko plugins