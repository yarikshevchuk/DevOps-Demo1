# Application Nodes

This module describes the deployment of the Spring Boot application
on two application virtual machines.

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
