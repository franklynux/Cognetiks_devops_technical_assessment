#!/bin/bash
# Production deployment script for Django app on EC2 with Gunicorn (systemd) and Nginx
# Usage: sudo ./deploy_production.sh

set -e

# Variables (update as needed)
PROJECT_NAME="Cognetiks_devops_technical_assessment"
PROJECT_DIR="/home/ubuntu/$PROJECT_NAME"
USER="ubuntu"
ENV_FILE="$PROJECT_DIR/.env"
VENV_DIR="$PROJECT_DIR/venv"
GUNICORN_SOCK="$PROJECT_DIR/gunicorn.sock"
DJANGO_WSGI_MODULE="mysite.wsgi:application"
STATIC_DIR="$PROJECT_DIR/static"

# 1. Install dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git nginx

# 2. Clone repo if not present
if [ ! -d "$PROJECT_DIR" ]; then
    git clone https://github.com/franklynux/Cognetiks_devops_technical_assessment.git "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"

# 3. Set up Python virtual environment
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt
grep gunicorn requirements.txt || pip install gunicorn


# 4. Ensure .env is present or generate it interactively
if [ ! -f "$ENV_FILE" ]; then
    echo ".env file not found. Let's create it."
    read -p "Enter RDS_DB_NAME: " rds_db_name
    read -p "Enter RDS_USERNAME: " rds_username
    read -s -p "Enter RDS_PASSWORD: " rds_password; echo
    read -p "Enter RDS_HOSTNAME: " rds_hostname
    read -p "Enter RDS_PORT [5432]: " rds_port
    rds_port=${rds_port:-5432}
    cat > "$ENV_FILE" <<EOF
RDS_DB_NAME=$rds_db_name
RDS_USERNAME=$rds_username
RDS_PASSWORD=$rds_password
RDS_HOSTNAME=$rds_hostname
RDS_PORT=$rds_port
EOF
    echo ".env file created at $ENV_FILE."
fi

# 5. Django migrations and collectstatic
python manage.py migrate
python manage.py collectstatic --noinput

# 6. Create systemd service for Gunicorn
SERVICE_FILE="/etc/systemd/system/gunicorn.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=gunicorn daemon for Django project
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/gunicorn $DJANGO_WSGI_MODULE --bind unix:$GUNICORN_SOCK

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

# 7. Configure Nginx
NGINX_CONF="/etc/nginx/sites-available/django_project"
sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        alias $STATIC_DIR/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$GUNICORN_SOCK;
    }
}
EOF

sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/django_project
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# 8. Open firewall for Nginx (optional, for Ubuntu UFW)
sudo ufw allow 'Nginx Full' || true

echo "\nDeployment complete! Your Django app should be running on port 80."
