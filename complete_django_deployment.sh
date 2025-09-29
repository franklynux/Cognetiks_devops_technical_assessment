#!/bin/bash
set -euo pipefail

# Variables
APP_DIR="/opt/django_app"
REPO_URL="https://github.com/franklynux/Cognetiks_devops_technical_assessment.git"
PROJECT_NAME="mysite"
DJANGO_USER="django"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)"
  exit 1
fi

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip nginx git curl

# Create user if missing
if ! id -u $DJANGO_USER >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash $DJANGO_USER
fi

# Clone fresh copy
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo chown $DJANGO_USER:$DJANGO_USER "$APP_DIR"

sudo -u $DJANGO_USER git clone "$REPO_URL" "$APP_DIR"

# Python environment setup
sudo -u $DJANGO_USER python3 -m venv "$APP_DIR/venv"
sudo -u $DJANGO_USER bash -c "source $APP_DIR/venv/bin/activate && pip install --upgrade pip && pip install -r $APP_DIR/requirements.txt"

# Create .env file with database credentials
sudo tee "$APP_DIR/.env" > /dev/null <<EOF
RDS_DB_NAME=postgresDB
RDS_USERNAME=postgres
RDS_PASSWORD=Admin123!
RDS_HOSTNAME=your-db-host.amazonaws.com
RDS_PORT=5432
EOF
sudo chown $DJANGO_USER:$DJANGO_USER "$APP_DIR/.env"

# Django setup
sudo tee -a "$APP_DIR/$PROJECT_NAME/settings.py" > /dev/null <<EOF

# Production overrides
DEBUG = False
ALLOWED_HOSTS = ['*']
STATIC_ROOT = '$APP_DIR/static'
EOF

sudo -u $DJANGO_USER bash -c "source $APP_DIR/venv/bin/activate && cd $APP_DIR && python manage.py migrate && python manage.py collectstatic --noinput"

# Set permissions
sudo chown -R $DJANGO_USER:www-data "$APP_DIR"
sudo find "$APP_DIR" -type d -exec chmod 750 {} \;
sudo find "$APP_DIR" -type f -exec chmod 640 {} \;
if [ -d "$APP_DIR/static" ]; then
    sudo chmod -R 755 "$APP_DIR/static"
fi
sudo find "$APP_DIR/venv/bin" -type f -exec chmod 755 {} \;

# Create Gunicorn service
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=Gunicorn Django Service
After=network.target

[Service]
User=$DJANGO_USER
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 $PROJECT_NAME.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Create Nginx config
sudo tee /etc/nginx/sites-available/django_app > /dev/null <<EOF
server {
    listen 80 default_server;
    server_name _;

    location /static/ {
        alias $APP_DIR/static/;
    }

    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:8000;
    }
}
EOF

# Remove default nginx sites
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default
sudo rm -f /var/www/html/index.nginx-debian.html /var/www/html/index.html || true

# Enable Django app
sudo ln -sf /etc/nginx/sites-available/django_app /etc/nginx/sites-enabled/django_app

# Test nginx config
sudo nginx -t

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn
sudo systemctl enable --now nginx

# Verify deployment
echo "Checking services..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

if sudo systemctl is-active --quiet gunicorn && sudo systemctl is-active --quiet nginx; then
    echo "✓ Deployment complete. Access via http://your-server-ip"
else
    echo "✗ Service startup failed. Check logs:"
    echo "sudo journalctl -u gunicorn -f"
    echo "sudo journalctl -u nginx -f"
    exit 1
fi