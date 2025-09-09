#!/bin/bash
set -euo pipefail

# Variables
APP_DIR="/opt/django_app"
REPO_URL="https://github.com/cognetiks/Technical_DevOps_app.git"
PROJECT_NAME="mysite"   # CHANGE THIS to the actual Django project folder name in the repo
DJANGO_USER="django"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)"
  exit 1
fi

# Install dependencies
apt-get update -y
apt-get install -y python3 python3-venv python3-pip nginx git curl

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
RDS_HOSTNAME=your-rds-endpoint.amazonaws.com
RDS_PORT=5432
EOF
chown $DJANGO_USER:$DJANGO_USER "$APP_DIR/.env"

# Django setup
cat >> "$APP_DIR/$PROJECT_NAME/settings.py" <<EOF

# Production overrides
DEBUG = False
ALLOWED_HOSTS = ['*']
STATIC_ROOT = '$APP_DIR/static'
EOF

sudo -u $DJANGO_USER bash -c "source $APP_DIR/venv/bin/activate && cd $APP_DIR && python manage.py migrate && python manage.py collectstatic --noinput"

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
RuntimeDirectory=gunicorn
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind unix:/run/gunicorn/gunicorn.sock $PROJECT_NAME.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Nginx config
cat > /etc/nginx/sites-available/django_app <<EOF
server {
    listen 80;
    server_name _;

    location /static/ {
        alias $APP_DIR/static/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn/gunicorn.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/django_app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Enable services
systemctl daemon-reload
systemctl enable --now gunicorn
systemctl enable --now nginx

# Verify services
if systemctl is-active --quiet gunicorn && systemctl is-active --quiet nginx; then
    echo "✓ Deployment complete. Access via http://<EC2_PUBLIC_IP>"
else
    echo "✗ Service startup failed. Check: systemctl status gunicorn nginx"
    exit 1
fi
