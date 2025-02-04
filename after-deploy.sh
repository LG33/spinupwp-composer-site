#!/bin/bash

# Function to update or add a variable in .env file
update_env_var() {
    local key=$1
    local value=$2
    
    # Check if variable exists in .env
    if grep -q "^${key}=" .env; then
        # Update existing variable
        sed -i "s|^${key}=.*|${key}=${value}|" .env
        echo "Updated $key in .env"
    else
        # Add new variable
        echo "${key}=${value}" >> .env
        echo "Added $key in .env"
    fi
}

# Check if .env.example exists
if [ ! -f .env.example ]; then
    echo "Error: .env.example file not found"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env

    # Check if any parameters were provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 KEY1=value1 KEY2=value2 ..."
        echo "Example: $0 DB_HOST=localhost DB_PORT=5432"
        exit 1
    fi

    declare -A env

    # Process each parameter
    for param in "$@"; do
        # Check if parameter follows KEY=value format
        if [[ $param =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            env[$key]=$value
            
            # Check if key exists in .env.example
            if grep -q "^${key}=" .env.example; then
                update_env_var "$key" "$value"
            else
                echo "Warning: $key not found in .env.example, skipping..."
            fi
        else
            echo "Warning: Invalid parameter format: $param (should be KEY=value)"
        fi
    done

    echo "Environment variables have been updated successfully!"

    composer config github-oauth.github.com ${env[GITHUB_TOKEN]}
    composer install --no-dev
else
    composer update
fi

cp public/wp-content/mu-plugins/wp-paheko/src/config.dist.php public/wp-content/mu-plugins/wp-paheko/src/config.local.php
ln -s ../../../../../vendor/paheko/paheko-modules public/wp-content/mu-plugins/wp-paheko/src/modules
ln -s ../../../paheko/data public/wp-content/mu-plugins/wp-paheko/src

cd public/wp
if [ -d wp-content ]; then
    rm -r wp-content
elif [ -f wp-content ]; then
    rm wp-content
fi
ln -s ../wp-content
    
wp core install --url=https://${env[DOMAIN]} --title="${env[TITLE]}" --admin_user="${env[EMAIL]}" --admin_password="${env[PASSWORD]}" --admin_email="${env[EMAIL]}" --skip-email --locale=fr_FR
wp plugin activate --all
wp theme install twentytwentyfive --activate