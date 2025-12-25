# Integration Tests

This directory contains automated tests to verify the integrity of the WebDAV Docker image. These are primarily for development and maintenance of the image itself.

## Overview

The `test_docker.sh` script runs a local instance of the container and performs a series of HTTP requests to validate:

1.  **Security**: Ensures unauthorized access is blocked (HTTP 401).
2.  **Functionality**: Verifies that files can be uploaded (PUT), downloaded (GET), and deleted (DELETE) correctly.
3.  **Persistence**: Confirms that file operations are actually reflected on the server.

## Running Tests

If you wish to verify the image locally before deployment, you can run:

```bash
make test
```

This requires Docker and `curl` to be installed on your machine.
