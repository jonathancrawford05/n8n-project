# n8n with PDF Processing Support

This repository contains a custom n8n Docker image with poppler-utils installed for enhanced PDF processing capabilities.

## Features

- Base n8n image with all standard features
- Poppler-utils for PDF manipulation:
  - `pdftotext` - Extract text from PDFs
  - `pdfinfo` - Get PDF metadata
  - `pdftoppm` - Convert PDF pages to images
  - `pdfunite` - Merge PDFs
  - `pdfseparate` - Split PDFs

## Quick Start

### Build the Docker Image

```bash
docker build -t n8n-with-poppler .
```

### Run n8n with Poppler

```bash
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  -v ~/.n8n:/home/node/.n8n \
  n8n-with-poppler
```

### Docker Compose (Optional)

Create a `docker-compose.yml` file:

```yaml
version: '3'

services:
  n8n:
    build: .
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_SECURE_COOKIE=false
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
    volumes:
      - ~/.n8n:/home/node/.n8n
```

Then run: `docker-compose up -d`

## Using Poppler in n8n Workflows

Use the Execute Command node in n8n to run poppler commands:

```bash
# Extract text from PDF
pdftotext /tmp/input.pdf /tmp/output.txt

# Get PDF info
pdfinfo /tmp/document.pdf

# Convert PDF to images
pdftoppm -png /tmp/document.pdf /tmp/page
```

## Data Persistence

All n8n data (workflows, credentials, execution history) is stored in the `~/.n8n` directory on your host machine. This data persists between container restarts and rebuilds.

## Updating

To update to the latest n8n version:

1. Pull the latest base image: `docker pull n8nio/n8n:latest`
2. Rebuild: `docker build -t n8n-with-poppler .`
3. Stop old container: `docker stop n8n && docker rm n8n`
4. Run the new container with the same volume mount

## License

This project extends the official n8n Docker image. See [n8n's license](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) for more information.
