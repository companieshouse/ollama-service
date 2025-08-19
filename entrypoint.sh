#!/bin/bash

# Start Ollama server in the background
/usr/bin/ollama serve &

# Wait for server to be ready
sleep 10

# Pull the model
/usr/bin/ollama pull llama3.2:3b

# Stop background server
pkill -f "ollama"
sleep 2

# Start Ollama normally
exec /usr/bin/ollama serve
