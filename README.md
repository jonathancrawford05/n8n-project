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
- Optimized configuration addressing n8n v1.116+ deprecations
- Host volume mounting for easy file access

## Configuration

This setup includes optimizations for n8n v1.116.2+ addressing all deprecation warnings:

- **Task Runners**: Enabled for improved execution performance
- **SQLite Connection Pooling**: Configured for better concurrent operations
- **Security Hardening**: File permissions and Git security settings
- **AI Workflow Optimization**: Extended timeouts and memory allocation

## Quick Start

### Build the Docker Image

```bash
docker build -t n8n-with-poppler .
```

### Run n8n with Full Configuration

```bash
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e DB_SQLITE_POOL_SIZE=4 \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -e N8N_GIT_NODE_DISABLE_BARE_REPOS=true \
  -e N8N_DEFAULT_BINARY_DATA_MODE=filesystem \
  -e EXECUTIONS_PROCESS_MAX_TIMEOUT=3600 \
  -e GENERIC_TIMEZONE=America/Toronto \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.n8n:/home/node/.n8n \
  -v ~/Downloads/n8n-outputs:/outputs \
  -v ~/Documents/n8n-files:/documents \
  -v /tmp/n8n-temp:/tmp \
  n8n-with-poppler
```

### Docker Compose (Recommended)

Use the provided `docker-compose.yml`:

```bash
# Create required directories
mkdir -p ~/Downloads/n8n-outputs ~/Documents/n8n-files /tmp/n8n-temp

# Copy .env.example to .env and adjust settings if needed
cp .env.example .env

# Start n8n
docker-compose up -d
```

The docker-compose setup includes:
- All deprecation fixes
- Health checks
- Binary data volume mounting
- Host-accessible output directories
- Environment file support

### Environment Variables

See `.env.example` for all available configuration options. Key settings:

| Variable | Default | Description |
|----------|---------|-------------|
| `N8N_RUNNERS_ENABLED` | true | Enable task runners for better performance |
| `DB_SQLITE_POOL_SIZE` | 4 | SQLite connection pool size |
| `N8N_BLOCK_ENV_ACCESS_IN_NODE` | false | Allow/block environment variable access in code nodes |
| `EXECUTIONS_PROCESS_MAX_TIMEOUT` | 3600 | Max execution time (1 hour for AI workflows) |

## File Access and Volume Mounts

This setup includes convenient volume mounts that allow n8n workflows to write files directly to accessible locations on your host machine:

### Volume Mappings

| Container Path | Host Path | Purpose |
|----------------|-----------|---------|
| `/outputs` | `~/Downloads/n8n-outputs` | Workflow outputs, easily accessible |
| `/documents` | `~/Documents/n8n-files` | Document storage and processing |
| `/tmp` | `/tmp/n8n-temp` | Temporary files |
| `/home/node/.n8n` | `~/.n8n` | n8n data persistence |

### Using Volume Mounts in Workflows

#### In Write Files Nodes
Instead of writing to container-only paths, use the mounted directories:

```javascript
// Write to Downloads folder (easily accessible)
/outputs/processed-report.pdf

// Write to Documents folder
/documents/{{ $now.toFormat('yyyy-MM-dd') }}-analysis.pdf

// Temporary processing
/tmp/working-file.pdf
```

#### Example: Email Attachment Processing
1. Gmail Trigger receives email with PDF
2. Write Files node saves to: `/outputs/{{ $json.attachment_0.fileName }}`
3. File appears in: `~/Downloads/n8n-outputs/` on your Mac

#### Example: Report Generation
1. Generate PDF report in workflow
2. Write to: `/documents/reports/{{ $now.toFormat('yyyy-MM') }}/report.pdf`
3. Access from: `~/Documents/n8n-files/reports/2024-11/report.pdf`

### Creating Output Directories

Before first use, create the directories:

```bash
mkdir -p ~/Downloads/n8n-outputs
mkdir -p ~/Documents/n8n-files
mkdir -p /tmp/n8n-temp
```

### Best Practices

1. **Use `/outputs`** for files users need to access immediately
2. **Use `/documents`** for long-term storage and organization
3. **Use `/tmp`** for intermediate processing files
4. **Organize with subdirectories**: `/outputs/invoices/2024/`
5. **Include timestamps** in filenames to avoid overwrites

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
pdftotext /outputs/input.pdf - | head -n 100

# Pass output to Ollama for summarization
# Save summary to /outputs/summary.txt
```

### 2. Smart Email Processing with File Output

- Gmail trigger receives emails with attachments
- Save attachments to `/outputs/email-attachments/`
- Analyze with Ollama for categorization
- Generate report and save to `/documents/email-reports/`

### 3. Document Processing Pipeline

- Read PDFs from `/documents/inbox/`
- Process with poppler tools
- Analyze with Ollama
- Save results to `/outputs/processed/`

## Using Poppler in n8n Workflows

Use the Execute Command node in n8n to run poppler commands:

```bash
# Extract text from PDF
pdftotext /tmp/input.pdf /outputs/extracted-text.txt

# Get PDF info
pdfinfo /documents/document.pdf > /outputs/pdf-metadata.txt

# Convert PDF to images
pdftoppm -png /tmp/document.pdf /outputs/page

# Extract specific pages
pdfseparate -f 1 -l 5 /documents/input.pdf /outputs/page-%d.pdf
```

## Troubleshooting

### File Access Issues

1. **Verify volume mounts are working**:
   ```bash
   # Check from within container
   docker exec n8n ls -la /outputs
   docker exec n8n ls -la /documents
   ```

2. **Test write permissions**:
   ```bash
   docker exec n8n touch /outputs/test.txt
   # Check if file appears in ~/Downloads/n8n-outputs/
   ```

3. **File not appearing in expected location**:
   - Ensure directories exist on host
   - Check Docker volume mount syntax
   - Verify no typos in file paths

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
- Use absolute paths or mounted directories
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

## Monitoring and Logs

View container logs:
```bash
docker logs -f n8n
```

Check container health:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Monitor file operations:
```bash
# Watch for new files in output directory
ls -la ~/Downloads/n8n-outputs/
```

## Updating

To update to the latest n8n version:

1. Pull the latest base image: `docker pull n8nio/n8n:latest`
2. Rebuild: `docker build -t n8n-with-poppler .`
3. Stop old container: `docker stop n8n && docker rm n8n`
4. Run the new container with the same volume mount

## Migration Notes

### From Versions < 1.116.2

If upgrading from older versions, the following environment variables are now recommended:
- Add `N8N_RUNNERS_ENABLED=true`
- Add `DB_SQLITE_POOL_SIZE=4`
- Review code nodes if setting `N8N_BLOCK_ENV_ACCESS_IN_NODE=true`

## Security Considerations

- Ollama binds to `0.0.0.0` only for local Docker access
- Consider firewall rules if running on a server
- Use environment variables for sensitive configurations
- Regularly update both n8n and Ollama
- File permissions are enforced with `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS`
- Be cautious with file paths in workflows to prevent unauthorized access

## License

This project extends the official n8n Docker image. See [n8n's license](https://github.com/n8n-io/n8n/blob/master/LICENSE.md) for more information.
