#!/bin/bash

# Start Ollama server in the background
/usr/bin/ollama serve &

# Wait for server to be ready
sleep 10

# Pull the model
#if ! /usr/bin/ollama pull llama3.2:3b; then
#  echo "Model pull failed"
#  exit 1
#fi

if ! /usr/bin/ollama pull mistral:7b-instruct; then
  echo "Model pull failed"
  exit 1
fi

# Stop background server
pkill -f "ollama"
sleep 2

# Start Ollama normally
exec /usr/bin/ollama serve
