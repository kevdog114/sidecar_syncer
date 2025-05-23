# Rsync Sidecar Docker Image

This Docker image provides an rsync sidecar container designed to synchronize files between a remote source (typically a bind mount) and a local persistent volume. Its primary functions are:

1.  **Initial Sync**: On startup, it syncs files *from* a specified remote source *to* a local directory.
2.  **Periodic Sync**: After the initial sync, it periodically syncs files *from* the local directory *back to* the remote source.

This is useful for scenarios where an application needs fast local access to files but also needs to persist changes back to a more permanent or shared location.

## Features

*   Lightweight image based on Alpine Linux.
*   Initial sync from remote to local.
*   Periodic sync from local back to remote.
*   Configurable sync interval.
*   Configurable rsync options.
*   Graceful shutdown handling.

## Configuration

The sidecar container is configured using environment variables:

| Variable             | Description                                                                                                | Default          |
| -------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------- |
| `LOCAL_SOURCE_PATH`  | Path inside the container for the local volume where files are synced to and from.                         | `/local`         |
| `REMOTE_SOURCE_PATH` | Path inside the container for the remote source (e.g., a bind mount) from which files are initially synced. | `/remote`        |
| `SYNC_INTERVAL`      | Interval in seconds for syncing from `LOCAL_SOURCE_PATH` back to `REMOTE_SOURCE_PATH`.                       | `60`             |
| `RSYNC_OPTIONS`      | Options for the rsync command (used for both initial and periodic syncs).                                  | `-avz --delete`  |
| `UID`                | User ID to run rsync as. Useful if permissions are an issue.                                                | `0` (root)       |
| `GID`                | Group ID to run rsync as. Useful if permissions are an issue.                                               | `0` (root)       |

**Note on `RSYNC_OPTIONS`**: The `--delete` option in the default `-avz --delete` means that files deleted in the source will also be deleted in the destination. Adjust these options carefully based on your needs.

**Note on `UID`/`GID`**: The `entrypoint.sh` script uses `su-exec` to run rsync with these IDs. If you are running Docker on a system that uses user namespaces, or if the permissions on your bind mounts and volumes are strict, you might need to set `UID` and `GID` to match the owner of the files on the host or volume.

## Usage with Docker Compose

Here's an example of how to use the rsync sidecar in a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  my-app:
    image: your-app-image:latest
    volumes:
      - app-data:/app/data # Application uses this volume for its data
    # ... other app configurations

  rsync-sidecar:
    image: your-dockerhub-username/rsync-sidecar:latest # Replace with your image name
    restart: always
    environment:
      - SYNC_INTERVAL=300 # Sync every 5 minutes
      - RSYNC_OPTIONS=-avz --delete --log-file=/var/log/rsync.log # Example: custom options with logging
      - LOCAL_SOURCE_PATH=/data/local_cache # Must match a volume mount
      - REMOTE_SOURCE_PATH=/data/remote_source # Must match a bind mount
      # - UID=1000 # Optional: Set if you need rsync to run as a specific user
      # - GID=1000 # Optional: Set if you need rsync to run as a specific group
    volumes:
      - app-data:/data/local_cache # Shared volume with the application (maps to LOCAL_SOURCE_PATH)
      - ./my-remote-data:/data/remote_source # Bind mount from host (maps to REMOTE_SOURCE_PATH)
    depends_on:
      - my-app # Optional: ensure app starts first, though sidecar logic is independent

volumes:
  app-data: # Define the shared volume
```

**Explanation:**

1.  **`my-app` service**: This is your main application container. It mounts a named volume `app-data` to `/app/data` (or any path it uses).
2.  **`rsync-sidecar` service**:
    *   Uses the rsync sidecar image (replace `your-dockerhub-username/rsync-sidecar:latest` with the actual image name you push to Docker Hub or build locally).
    *   **`environment`**:
        *   `SYNC_INTERVAL` is set to 300 seconds (5 minutes).
        *   `RSYNC_OPTIONS` can be customized.
        *   `LOCAL_SOURCE_PATH` is set to `/data/local_cache`. This path *inside the sidecar container* will use the `app-data` volume.
        *   `REMOTE_SOURCE_PATH` is set to `/data/remote_source`. This path *inside the sidecar container* will use the `./my-remote-data` bind mount.
    *   **`volumes`**:
        *   `app-data:/data/local_cache`: Mounts the **same named volume** (`app-data`) that `my-app` uses to the path defined by `LOCAL_SOURCE_PATH`. This allows the sidecar to access the application's data.
        *   `./my-remote-data:/data/remote_source`: Bind mounts a directory from your Docker host (e.g., `./my-remote-data`) to the path defined by `REMOTE_SOURCE_PATH`. This is where files will be initially copied from and later synced back to.
    *   **`restart: always`**: Ensures the sidecar restarts if it crashes.
    *   **`depends_on`**: Optional, can help with startup order but doesn't strictly make the sidecar dependent on the app's health.

**Workflow:**

1.  On startup, the `rsync-sidecar` copies everything from `./my-remote-data` (via `/data/remote_source`) into the `app-data` volume (via `/data/local_cache`). Your application (`my-app`) can then read this data from `app-data`.
2.  Periodically (every `SYNC_INTERVAL` seconds), the `rsync-sidecar` copies everything from the `app-data` volume (changes made by `my-app`) back to `./my-remote-data` on the host.

## Building Locally

To build the image yourself:

```bash
docker build -t your-username/rsync-sidecar:latest .
```

Remember to replace `your-username/rsync-sidecar:latest` with your desired image name and tag.

## GitHub Actions

This repository includes a GitHub Action workflow in `.github/workflows/docker-publish.yml` that automatically builds and pushes the Docker image to Docker Hub under the name `your-dockerhub-username/rsync-sidecar` (you'll need to update this in the workflow file and configure `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets in your repository settings).

The image is tagged with:
* `latest`
* Git branch name (e.g., `main`)
* Git tag (e.g., `v1.0.0`, `v1.0.0-beta`) if a version tag is pushed.

---

This README provides a comprehensive guide to using and configuring the rsync sidecar.
