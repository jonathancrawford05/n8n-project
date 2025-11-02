# n8n with PDF Processing and Local LLM Support

This repository contains a custom n8n Docker image with poppler-utils installed for enhanced PDF processing capabilities and configuration for local LLM integration via Ollama.

## Features

- Base n8n image with all standard features
- Poppler-utils for PDF manipulation:
  - `pdftotext` - Extract text from PDFs
  - `pdfinfo` - Get PDF metadata
  - `pdftoppm` - Convert PDF pages to images
  - `pdfunite` - Merge PDFs
  - `pdfseparate` - Split PDFs
- Ollama integration support for local LLM workflows

## Quick Start

### Build the Docker Image

```bash
docker build -t n8n-with-poppler .
```

### Run n8n with Poppler and Ollama Support

```bash
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.n8n:/home/node/.n8n \
  n8n-with-poppler
```

Note: The `--add-host=host.docker.internal:host-gateway` flag enables communication with services running on your host machine (like Ollama).

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
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ~/.n8n:/home/node/.n8n
```

Then run: `docker-compose up -d`

## Ollama Integration

This n8n setup can connect to a locally running Ollama instance for LLM capabilities.

### Prerequisites

1. **Install Ollama** on your host machine: https://ollama.ai
2. **Configure Ollama** to accept connections from Docker:
   ```bash
   # Add to your shell profile (.zshrc, .bash_profile, etc.)
   export OLLAMA_HOST=0.0.0.0
   
   # Restart Ollama
   ollama serve
   ```
3. **Pull desired models**:
   ```bash
   ollama pull llama3.2
   ollama pull mistral
   ollama pull codellama
   ```

### Connecting n8n to Ollama

1. In n8n, add an **Ollama Chat Model** node or **HTTP Request** node
2. Create Ollama credentials with:
   - **Base URL**: `http://host.docker.internal:11434`
3. Test the connection

### Example Ollama API Usage

For HTTP Request nodes:
```json
{
  "method": "POST",
  "url": "http://host.docker.internal:11434/api/generate",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "model": "llama3.2",
    "prompt": "Your prompt here",
    "stream": false
  }
}
```

### Available Ollama Endpoints

- `GET /api/tags` - List available models
- `POST /api/generate` - Generate text
- `POST /api/chat` - Chat completions
- `POST /api/embeddings` - Generate embeddings

## Example Workflows

### 1. PDF Summarization with AI

Combine poppler and Ollama to extract and summarize PDF content:

```bash
# In Execute Command node
pdftotext input.pdf - | head -n 100

# Pass output to Ollama for summarization
```

### 2. Smart Email Processing

- Use Gmail trigger to receive emails
- Analyze with Ollama for categorization and priority
- Apply labels and organize automatically

### 3. Document Q&A System

- Extract text from PDFs using poppler
- Store in vector database
- Query with natural language using Ollama

## Using Poppler in n8n Workflows

Use the Execute Command node in n8n to run poppler commands:

```bash
# Extract text from PDF
pdftotext /tmp/input.pdf /tmp/output.txt

# Get PDF info
pdfinfo /tmp/document.pdf

# Convert PDF to images
pdftoppm -png /tmp/document.pdf /tmp/page

# Extract specific pages
pdfseparate -f 1 -l 5 /tmp/input.pdf /tmp/page-%d.pdf
```

## Troubleshooting

### Ollama Connection Issues

1. **Verify Ollama is running**:
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. **Test from within n8n container**:
   ```bash
   docker exec -it n8n /bin/sh -c "apk add --no-cache curl"
   docker exec n8n curl http://host.docker.internal:11434/api/tags
   ```

3. **Alternative host addresses** (if host.docker.internal doesn't work):
   - Find Docker bridge IP: `docker network inspect bridge | grep Gateway`
   - Use the gateway IP (typically `172.17.0.1`)

### PDF Processing Issues

- Ensure PDF files are accessible within the container
- Use absolute paths or copy files to `/tmp` directory
- Check file permissions

### Performance Optimization

- For large PDFs, process in chunks
- Use appropriate Ollama models based on task complexity:
  - `phi` - Fast, lightweight tasks
  - `llama3.2` - Balanced performance
  - `mistral` - Complex reasoning
- Set appropriate temperature values:
  - 0.1-0.3 for factual tasks
  - 0.7-0.9 for creative tasks

## Data Persistence

All n8n data (workflows, credentials, execution history) is stored in the `~/.n8n` directory on your host machine. This data persists between container restarts and rebuilds.

## Updating

To update to the latest n8n version:

1. Pull the latest base image: `docker pull n8nio/n8n:latest`
2. Rebuild: `docker build -t n8n-with-poppler .`
3. Stop old container: `docker stop n8n && docker rm n8n`
4. Run the new container with the same volume mount

## Security Considerations

- Ollama binds to `0.0.0.0` only for local Docker access
- Consider firewall rules if running on a server
- Use environment variables for sensitive configurations
- Regularly update both n8n and Ollama

## License

This project extends the official n8n Docker image. See [n8n's license](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) for more information.
