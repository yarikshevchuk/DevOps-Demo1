# Application Nodes

This module describes the deployment of the Spring Boot application
on two application virtual machines.

## Application configuration

Before starting the application, configure the database connection.

The Spring Boot configuration is located at:

`src/main/resources/application.yml`

The database credentials must not be stored directly in `application.yml`.
They should be configured in a similar way:
url: ${DB_URL}
username: ${DB_USERNAME}
password: ${DB_PASSWORD}


The application uses the following environment variables:

- `DB_URL` — PostgreSQL database URL
- `DB_USERNAME` — PostgreSQL username
- `DB_PASSWORD` — PostgreSQL password

And the data should be stored in separate file cinema.env, that is automaticly creating when setup_app.sh is running. 

## Application Nodes

VM1:
- IP: ...
- Application port: 8080

VM2:
- IP: ...
- Application port: 8080

## Requirements
- Ubuntu
- Java 21
- Maven
- PostgreSQL connectivity

## Configuration

The application reads database configuration from environment variables:

DB_URL
DB_USERNAME
DB_PASSWORD

Database credentials are not stored in GitHub.

## Build

mvn clean package -DskipTests

## Systemd

The application is managed by systemd using cinema.service.
