FROM public.ecr.aws/amazoncorretto/amazoncorretto:21

# Install dependencies and CA certificates
RUN yum update -y && \
#   yum install -y tar gzip wget ca-certificates openssl && \
    yum install -y tar gzip wget && \
    yum clean all

# Update CA certificates
#RUN update-ca-trust force-enable

# Create directory for Ollama
RUN mkdir -p /usr/local/bin

# Download Ollama binary directly with insecure flag to bypass initial certificate issues
RUN wget --no-check-certificate --timeout=60 --tries=10 --retry-connrefused --waitretry=30 \
    -O /usr/local/bin/ollama https://github.com/ollama/ollama/releases/latest/download/ollama-linux-arm64 || \
    wget --no-check-certificate --timeout=60 --tries=10 --retry-connrefused --waitretry=30 \
    -O /usr/local/bin/ollama https://github.com/ollama/ollama/releases/download/v0.1.27/ollama-linux-arm64

# Make the binary executable
RUN chmod +x /usr/local/bin/ollama

# Expose Ollama's default port
EXPOSE 11434

# Copy your custom CA certificate
#COPY apple.pem /etc/pki/ca-trust/source/anchors/apple.pem

# Update the trust store
#RUN update-ca-trust extract

# Set environment variables
ENV OLLAMA_HOST=0.0.0.0
ENV SSL_CERT_DIR=/etc/ssl/certs
ENV OLLAMA_SKIP_CERT_VERIFY=true

# Default command to start Ollama
CMD ["ollama", "serve"]