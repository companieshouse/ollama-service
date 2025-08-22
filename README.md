# Ollama-service
A docker containerized application that provides an endpoint to run Ollama requests

## Overview

This runs the Ollama server in a Docker container and exposes an endpoint to interact with it. 
This is based on the Ollama base image and currently loads the llama3.2:3b model. This could be changed to use a different model as required.

The application deploys to the `rand-pocs-cidev-cluster` ECS cluster 
as the `cidev-ollama-service` service.

## Key Features
- Uses and `entrypoint.sh` script to start the Ollama server and load the model.
- Defines the Ollama server settings via environment variables in the Dockerfile.
- Exposes the Ollama server port (11434) via the Dockerfile.

## Usage
- Provides an endpoint to interact with the Ollama server: `https://pocs.rand.aws.chdev.org`  
- For example within springboot applications, setting the `spring.ai.ollama.base-url=https://pocs.rand.aws.chdev.org` 
property to this endpoint.

## Endpoints
- **Ollama endpoint:** https://pocs.rand.aws.chdev.org

## Building
To build the project locally, use the following command:
- `docker build -t ollama-service .`

or via `concourse`:
- build using the `ollama-service` ci-pipeline: https://ci-platform.companieshouse.gov.uk/teams/team-development/pipelines/ollama-service

## Running
- On a rebuild via `concourse`, the application will be deployed to the `rand-pocs-cidev-cluster` ECS cluster as the `cidev-ollama-service` service.
