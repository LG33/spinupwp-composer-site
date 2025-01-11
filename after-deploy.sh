#!/bin/bash

# Check if .env.example exists
if [ ! -f .env.example ]; then
    echo "Error: .env.example file not found"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
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

            #if [ $key == "DOMAIN" ]; then
            #    update_nginx_conf "$value"
            #fi
            
            # Check if key is GITHUB_TOKEN and set it as a composer config
            if [ $key == "GITHUB_TOKEN" ]; then
                composer config github-oauth.github.com $value
            # Check if key exists in .env.example
            elif grep -q "^${key}=" .env.example; then
                update_env_var "$key" "$value"
                echo "Updated $key in .env"
            else
                echo "Warning: $key not found in .env.example, skipping..."
            fi
        else
            echo "Warning: Invalid parameter format: $param (should be KEY=value)"
        fi
    done

    echo "Environment variables have been updated successfully!"

    composer install

    apt install make
    cd public/content/mu-plugins/wp-paheko && \
        make modules && \
        make plugins

    cd public/wp && \
        rm -r wp-content && \
        ln -s ../content content
else
    composer update
fi

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