## NestJS Blog API

A production ready REST API built with NestJS, PostgreSQL, Docker, Terraform, and GitHub Actions. The project demonstrates Infrastructure as Code (IaC), containerization, automated deployments, and AWS cloud infrastructure.

## Features

- CRUD operations for blog articles
- PostgreSQL database
- Dockerized application
- Infrastructure managed with Terraform
- CI pipeline using GitHub Actions
- CD pipeline deploying to AWS EC2 via AWS Systems Manager (SSM)
- Amazon RDS for PostgreSQL
- Security Groups managed with Terraform

## Tech Stack

### Backend

- Nestjs
- Typescript
- TypeORM
- PostgreSQL

### Devops

- Docker
- Docker compose
- Terraform
- Github Actions
- AWS EC2
- AWS RDS
- AWS Systems Manager(SSM)
- AWS IAM
- AWS Security Groups

## Architecture

![Screenshot of my infra architecture.](/assets/nestjs-blog-api-infra.jpg)

## Infrastructure

Terraform provisions the following AWS resources:

- EC2 Instance
- RDS PostgreSQL
- IAM Role
- IAM Instance Profile
- Security Groups
- Key Pair
- Default VPC resources

## CI/CD

### Continuous Integration

On every push:

- Builds the Docker image
- Pushes the image to Docker Hub

### Continuous Deployment

- Infrastructure changes inside the `terraform/` directory trigger the Terraform workflow.
- Application changes trigger the CI workflow, which deploys the latest Docker image to EC2 using AWS Systems Manager (SSM).

## Running Locally

```
git clone <https://github.com/Lex043/nestjs-blog-api>
cd nestjs-blog-api
npm install
```

### Create .env file

DB_HOST=localhost
DB_PORT=5432
DB_USER=
DB_PASS=
DB_NAME=

### Start the application

```
npm run start:dev
```

## Docker

### Build the image

```
docker build -t nestjs-blog-api .
```

### Run with Docker Compose

```
docker compose up -d
```
