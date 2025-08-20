FROM ollama/ollama:0.1.27

# Create a non-root user and writable directory for Ollama data
RUN mkdir -p /tmp/ollama && chmod 777 /tmp/ollama

# Set environment variable to use the writable directory
ENV OLLAMA_MODELS=/tmp/ollama
ENV HOME=/tmp
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_KV_CACHE_TYPE=q8_0
ENV OLLAMA_FLASH_ATTENTION=1

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Start Ollama server in background, pull the Llama model, then stop the server
# Using full path to ollama binary to avoid command not found errors
#RUN nohup sh -c "/usr/bin/ollama serve &" && \
#    sleep 10 && \
#    /usr/bin/ollama pull llama3.2:3b && \
#    pkill -f "ollama"

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Perform healthcheck from container's namespace rather than here \
# Health check to ensure container is running properly
#HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#  CMD curl -f http://localhost:11434/api/health || exit 1

# Expose the Ollama API port
EXPOSE 11434

# Use the default entrypoint from the ollama image with the serve command
# Using full path to ollama binary
#CMD ["/usr/bin/ollama", "serve"]

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
