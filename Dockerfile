# Use alpine:latest as the base image
FROM alpine:latest

# Install rsync and bash
RUN apk add --no-cache rsync bash

# Create necessary directories for /local and /remote
RUN mkdir -p /local /remote

# Copy the entrypoint.sh script into the image at /entrypoint.sh
COPY entrypoint.sh /entrypoint.sh

# Ensure /entrypoint.sh has execute permissions
RUN chmod +x /entrypoint.sh

# Set entrypoint.sh as the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Define environment variables
ENV LOCAL_SOURCE_PATH=/local
ENV REMOTE_SOURCE_PATH=/remote
ENV SYNC_INTERVAL=60
ENV RSYNC_OPTIONS="-avz --delete"
