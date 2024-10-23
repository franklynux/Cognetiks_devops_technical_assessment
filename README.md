# Django Technical DevOps App

This is a Django project used for demonstrating DevOps and cloud infrastructure skills. It includes both a local SQLite database for development and a PostgreSQL database (Amazon RDS) for production environments. The project is configured to automatically switch to RDS when the necessary environment variables are provided.

## Features

- Django web application.
- Automatically switches between SQLite (development) and PostgreSQL (production) based on environment variables.
- Production-ready configuration for integration with Amazon RDS.

## Setup and Installation

### 1. Clone the Repository

```bash
git clone https://github.com/cognetiks/Technical_DevOps_app.git
cd Technical_DevOps_app
```
### 2. Install Dependencies

Make sure you have Python 3.8+ and pip installed. Then, create a virtual environment and install the required packages:

```bash
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
pip install -r requirements.txt
```

### 3. Environment Variables

For the project to work in production with an Amazon RDS instance, you need to set the following environment variables:

- `RDS_DB_NAME` – Your RDS database name.
- `RDS_USERNAME` – Your RDS username.
- `RDS_PASSWORD` – Your RDS password.
- `RDS_HOSTNAME` – The endpoint of your RDS instance.
- `RDS_PORT` – The port your RDS instance uses (default for PostgreSQL is 5432).

In development, if these environment variables are not set, the project will default to using SQLite.

### 4. Configure Environment Variables for Production

For production deployment with RDS, export the required environment variables. Example configuration:

```bash
export RDS_DB_NAME=mydbname
export RDS_USERNAME=mydbuser
export RDS_PASSWORD=mypassword
export RDS_HOSTNAME=mydbinstance.123456789012.us-east-1.rds.amazonaws.com
export RDS_PORT=5432
```

Alternatively, you can add these to a .env file or your deployment tool (e.g., Docker, AWS Elastic Beanstalk).

### 5. Run Database Migrations

Apply migrations to set up your database schema:

```bash
python manage.py migrate
```

### 6. Run the Application

To start the Django development server:

```bash
python manage.py runserver
```

For production, you'll need to configure a web server like NGINX or Gunicorn.

## Local Development Setup

For local development, the app will default to using an SQLite database. No special configuration is needed unless you wish to connect to PostgreSQL locally.

### Running Local Server

To run the server locally:

```bash
python manage.py runserver
```

### Production Deployment
When deploying to production (e.g., on AWS or any other cloud provider), ensure the required environment variables are set. The app will automatically connect to the PostgreSQL RDS instance once the variables are correctly configured.

### Contributing
Feel free to fork the repository and submit pull requests for improvements or bug fixes.