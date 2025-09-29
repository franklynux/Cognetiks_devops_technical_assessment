#!/bin/bash
set -euo pipefail

# Variables
APP_DIR="/opt/django_app"
REPO_URL="https://github.com/franklynux/Cognetiks_devops_technical_assessment.git"
PROJECT_NAME="mysite"
DJANGO_USER="django"

# Install dependencies first
apt-get update -y
apt-get install -y python3 python3-venv python3-pip nginx git curl awscli

echo "Fetching RDS endpoint from AWS SSM Parameter Store"
RDS_ENDPOINT=$(aws ssm get-parameter --name "/DjangoApp/rds_endpoint" --query "Parameter.Value" --output text --region us-east-1)

# Extract RDS hostname and port number separately
POSTGRES_HOST=$(echo $RDS_ENDPOINT | cut -d':' -f1)
POSTGRES_PORT=$(echo $RDS_ENDPOINT | cut -d':' -f2)
echo "RDS Host: $POSTGRES_HOST, Port: $POSTGRES_PORT"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)"
  exit 1
fi



# Create user if missing
if ! id -u $DJANGO_USER >/dev/null 2>&1; then
  useradd -m -s /bin/bash $DJANGO_USER
fi

# Clone fresh copy
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
chown $DJANGO_USER:$DJANGO_USER "$APP_DIR"

sudo -u $DJANGO_USER git clone "$REPO_URL" "$APP_DIR"

# Python environment setup
sudo -u $DJANGO_USER python3 -m venv "$APP_DIR/venv"
sudo -u $DJANGO_USER bash -c "source $APP_DIR/venv/bin/activate && pip install --upgrade pip && pip install -r $APP_DIR/requirements.txt"

# Create .env file with database credentials
cat > "$APP_DIR/.env" <<EOF
RDS_DB_NAME=postgresDB
RDS_USERNAME=postgres
RDS_PASSWORD=Admin123!
RDS_HOSTNAME=$POSTGRES_HOST
RDS_PORT=$POSTGRES_PORT
EOF
chown $DJANGO_USER:$DJANGO_USER "$APP_DIR/.env"

# Django setup
cat >> "$APP_DIR/$PROJECT_NAME/settings.py" <<EOF

# Production overrides
DEBUG = False
ALLOWED_HOSTS = ['*']
STATIC_ROOT = '$APP_DIR/static'

# Disable CSRF for health checks
CSRF_TRUSTED_ORIGINS = ['http://*', 'https://*']
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
EOF

sudo -u $DJANGO_USER bash -c "source $APP_DIR/venv/bin/activate && cd $APP_DIR && python manage.py migrate && python manage.py collectstatic --noinput"

# Ensure permissions allow Nginx (www-data) to read static files and the app user owns files
sudo chown -R $DJANGO_USER:www-data "$APP_DIR"
sudo find "$APP_DIR" -type d -exec chmod 750 {} \;
sudo find "$APP_DIR" -type f -exec chmod 640 {} \;
# Make static files world-readable so Nginx can serve them
if [ -d "$APP_DIR/static" ]; then
    sudo chmod -R 755 "$APP_DIR/static"
fi

# set executable permissions for venv/bin
sudo find "$APP_DIR/venv/bin" -type f -exec chmod 755 {} \;

# Gunicorn service
cat > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=Gunicorn Django Service
After=network.target

[Service]
User=$DJANGO_USER
Group=www-data
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 $PROJECT_NAME.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Nginx config
cat > /etc/nginx/sites-available/django_app <<EOF
server {
    listen 80 default_server;
    server_name _;

    location /static/ {
        alias $APP_DIR/static/;
    }

    # Health check endpoint for ALB
    location = /health/ {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'OK';
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

# Remove default nginx site
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default

# Remove default index pages that can still serve the welcome page
sudo rm -f /var/www/html/index.nginx-debian.html /var/www/html/index.html || true

# Enable Django app
sudo ln -sf /etc/nginx/sites-available/django_app /etc/nginx/sites-enabled/django_app

# Test nginx config
sudo nginx -t

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn
sudo systemctl enable --now nginx
sudo systemctl reload nginx

# Verify services
if systemctl is-active --quiet gunicorn && systemctl is-active --quiet nginx; then
    echo "✓ Deployment complete. Access via http://<LB_dns_name>"
else
    echo "✗ Service startup failed. Check: systemctl status gunicorn nginx"
    exit 1
fi
