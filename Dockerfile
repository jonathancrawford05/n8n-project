FROM n8nio/n8n:latest

# Install poppler-utils for PDF handling
USER root
RUN apk add --no-cache \
    poppler-utils

# Switch back to the node user
USER node

# The rest is handled by the base image
