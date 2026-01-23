#!/bin/sh
# Approved executable script for Nomad jobs
# This script is stored in the GCS artifacts bucket

echo "==================================="
echo "Approved Artifact Execution"
echo "==================================="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "==================================="
echo "Script executed successfully!"
exit 0
