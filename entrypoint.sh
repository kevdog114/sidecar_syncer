#!/bin/bash

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Trap SIGTERM and SIGINT signals to allow graceful shutdown
trap 'log "Received SIGTERM/SIGINT. Exiting gracefully."; exit 0' SIGTERM SIGINT

# Initial sync from remote to local
log "Performing initial sync from $REMOTE_SOURCE_PATH to $LOCAL_SOURCE_PATH..."
rsync $RSYNC_OPTIONS "$REMOTE_SOURCE_PATH/" "$LOCAL_SOURCE_PATH/"
log "Initial sync complete."

# Continuous sync loop from local to remote
while true; do
  log "Performing periodic sync from $LOCAL_SOURCE_PATH to $REMOTE_SOURCE_PATH..."
  rsync $RSYNC_OPTIONS "$LOCAL_SOURCE_PATH/" "$REMOTE_SOURCE_PATH/"
  log "Periodic sync complete. Waiting for $SYNC_INTERVAL seconds..."
  sleep $SYNC_INTERVAL &
  wait $! # Wait for sleep to complete or be interrupted
done
