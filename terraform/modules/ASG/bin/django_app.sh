#!/bin/bash

# Variables
APP_DIR="/opt/django_app"
REPO_NAME="Technical_DevOps_app"
REPO_URL="https://github.com/cognetiks/Technical_DevOps_app.git"

# Error handlers
set -e  # Exit on any error
set -o pipefail  # Exit on pipe failures

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install required packages
echo "Installing Python packages..."
apt-get install -y python3 python3-pip python3-venv nginx git

# Create application user
echo "Creating Django user..."
if ! id -u django >/dev/null 2>&1; then
    useradd -m -s /bin/bash django
    usermod -aG sudo django
    echo "Django user created"
else
    echo "Django user already exists"
fi

# Create application directory
mkdir -p $APP_DIR
chown django:django $APP_DIR

# Switch to django user context
sudo -u django bash << EOF
cd $APP_DIR

# Clone Django project repo
git clone $REPO_URL || {
    echo "Git clone failed"
    exit 1
}
cp -r $APP_DIR/$REPO_NAME/* $APP_DIR/
rm -rf $APP_DIR/$REPO_NAME
cd $APP_DIR


# Create virtual environment and Install requirements.txt
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt || {
    echo "Requirements installation failed"
    exit 1
}


# Update main settings.py for production
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
# Force ALLOWED_HOSTS setting
echo "" >> mysite/settings.py
echo "# Production settings override" >> mysite/settings.py
echo "ALLOWED_HOSTS = ['*']" >> mysite/settings.py
echo "DEBUG = False" >> mysite/settings.py
echo "STATIC_ROOT = '$APP_DIR/static/'" >> mysite/settings.py

# Run migrations
python manage.py migrate
python manage.py collectstatic --noinput

EOF

# Configure Gunicorn service
echo "Configuring services..."
cat > /etc/systemd/system/gunicorn.service << 'SERVICE'
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=django
Group=django
WorkingDirectory=/opt/django_app
ExecStart=/opt/django_app/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/opt/django_app/mysite.sock mysite.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE

# Configure Nginx
cat > /etc/nginx/sites-available/django_app << 'NGINX'
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /opt/django_app;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/opt/django_app/mysite.sock;
    }
}
NGINX

# Enable site
ln -sf /etc/nginx/sites-available/django_app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Start services
echo "Starting services..."
systemctl daemon-reload
systemctl start gunicorn
systemctl enable gunicorn
systemctl restart nginx
systemctl enable nginx

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb || {
    echo "CloudWatch agent download failed"
    exit 1
}
dpkg -i amazon-cloudwatch-agent.deb || {
    echo "CloudWatch agent installation failed"
    exit 1
}
echo "Django app installation completed!"