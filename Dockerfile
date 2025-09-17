FROM ollama/ollama:0.11.5

# Create a non-root user and writable directory for Ollama data
RUN mkdir -p /tmp/ollama && chmod 777 /tmp/ollama

# Set environment variable to use the writable directory
ENV OLLAMA_MODELS=/tmp/ollama
ENV HOME=/tmp
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_KV_CACHE_TYPE=q8_0
ENV OLLAMA_FLASH_ATTENTION=1
ENV OLLAMA_LLM_LIBRARY=cpu_avx2
# Max context length (8192 for Llama 3.2 3B) - but use 12288 to allow for larger models
ENV OLLAMA_CTX=12288
ENV OLLAMA_MAX_LOADED_MODELS=3
# 5-minute request timeout
ENV OLLAMA_REQUEST_TIMEOUT=300s
# Model loading timeout
ENV OLLAMA_LOAD_TIMEOUT=300s
# Keep model in memory longer
ENV OLLAMA_KEEP_ALIVE=10m
ENV OLLAMA_MAX_QUEUE=2048
ENV OLLAMA_NUM_PARALLEL=4
ENV OLLAMA_MAX_VRAM=8000000000
ENV OLLAMA_DEBUG=1

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Perform healthcheck from container's namespace rather than here \
# Health check to ensure container is running properly
#HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#  CMD curl -f http://localhost:11434/api/version || exit 1

# Expose the Ollama API port
EXPOSE 11434

# Use the default entrypoint from the ollama image with the serve command
# Using full path to ollama binary
#CMD ["/usr/bin/ollama", "serve"]

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
