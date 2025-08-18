# Smart Templates Plugin

## Quick Start

1. **Clone the Repository:**
```bash
git clone https://github.com/LerianStudio/plugins-docker-compose.git
```

2. **Go to the plugin directory:**
```bash
cd plugins/plugin-smart-templates
```
3. **Run the Docker Compose File**
```bash
docker compose --env-file infra.env --env-file manager.env --env-file worker.env up
```

5. **Access the API:**
Visit `http://localhost:4004` to interact with the Manager API.
Visit `http://localhost:4005` to interact with the Worker API.

6. [Visit our Documentation](https://docs.lerian.studio/docs/smart-templates)