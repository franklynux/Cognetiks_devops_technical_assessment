#!/bin/bash

# Check if required files exist
echo "Checking required files..."
ls -la /opt/django_app/.env
ls -la /opt/django_app/venv/bin/gunicorn
ls -la /opt/django_app/mysite/wsgi.py

# Create Gunicorn service file without EnvironmentFile
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=Gunicorn Django Service
After=network.target

[Service]
User=django
Group=www-data
WorkingDirectory=/opt/django_app
ExecStart=/opt/django_app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 mysite.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload and start
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
sudo systemctl status gunicorn