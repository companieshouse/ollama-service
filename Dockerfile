FROM ollama/ollama:0.1.27

# Create a non-root user and writable directory for Ollama data
RUN mkdir -p /data/ollama && chmod 777 /data/ollama

# Set environment variable to use the writable directory
ENV OLLAMA_MODELS=/data/ollama
ENV HOME=/data

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Start Ollama server in background, pull the Llama model, then stop the server
RUN nohup sh -c "/bin/ollama serve &" && \
    sleep 10 && \
    /bin/ollama pull llama2 && \
    pkill -f "/bin/ollama"

# Health check to ensure container is running properly
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:11434/api/health || exit 1

# Expose the Ollama API port
EXPOSE 11434

# Use the default entrypoint from the ollama image with the serve command
CMD ["/bin/ollama", "serve"]