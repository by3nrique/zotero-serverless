#!/bin/bash
set -e

# Configuration
IMAGE_NAME="zotero-webdav-test"
CONTAINER_NAME="zotero-test-container"
PORT=8888
USERNAME="testuser"
PASSWORD="testpassword"
TEST_FILE="test_artifact.txt"
TEST_CONTENT="Zotero WebDAV Test Content $(date)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    log_info "Cleaning up..."
    docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true
    rm -f $TEST_FILE
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# 1. Build Image
log_info "Building Docker image..."
docker build -t $IMAGE_NAME ./docker > /dev/null

# 2. Run Container
log_info "Starting container..."
docker run -d --name $CONTAINER_NAME \
  -p $PORT:80 \
  -e WEBDAV_USERNAME=$USERNAME \
  -e WEBDAV_PASSWORD=$PASSWORD \
  $IMAGE_NAME > /dev/null

log_info "Waiting for Nginx to initialize..."
BASE_URL="http://localhost:$PORT"

# Health check loop (wait up to 10s)
for i in {1..10}; do
    # Check if we can connect (even if we get 401)
    if curl -s -o /dev/null "$BASE_URL"; then
        break
    fi
    sleep 1
done

# Check if container is still running
if ! docker ps | grep -q $CONTAINER_NAME; then
    log_error "Container died unexpectedly. Logs:"
    docker logs $CONTAINER_NAME
    exit 1
fi

# 3. Test: Authentication Required
log_info "Test 1: Verifying Authentication is Required..."
# Disable set -e temporarily for curl command to handle connection errors gracefully
set +e
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
CURL_EXIT=$?
set -e

if [ $CURL_EXIT -ne 0 ]; then
    log_error "Failed to connect to server (Curl exit code: $CURL_EXIT)"
    exit 1
fi

if [ "$HTTP_CODE" -eq 401 ]; then
    log_info "[PASS] Auth required (401) - Passed"
else
    log_error "[FAIL] Auth check failed. Expected 401, got $HTTP_CODE"
    exit 1
fi

# 4. Test: Upload File (PUT)
log_info "Test 2: Uploading file (PUT)..."
echo "$TEST_CONTENT" > $TEST_FILE
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$USERNAME:$PASSWORD" -T $TEST_FILE "$BASE_URL/$TEST_FILE")

if [[ "$HTTP_CODE" -eq 201 || "$HTTP_CODE" -eq 204 ]]; then
    log_info "[PASS] File upload ($HTTP_CODE) - Passed"
else
    log_error "[FAIL] File upload failed. Expected 201 or 204, got $HTTP_CODE"
    docker logs $CONTAINER_NAME
    exit 1
fi

# 5. Test: Download File (GET)
log_info "Test 3: Downloading file (GET)..."
DOWNLOADED_CONTENT=$(curl -s -u "$USERNAME:$PASSWORD" "$BASE_URL/$TEST_FILE")

if [ "$DOWNLOADED_CONTENT" == "$TEST_CONTENT" ]; then
    log_info "[PASS] Content verification - Passed"
else
    log_error "[FAIL] Content mismatch."
    echo "Expected: $TEST_CONTENT"
    echo "Got: $DOWNLOADED_CONTENT"
    exit 1
fi

# 6. Test: Delete File (DELETE)
log_info "Test 4: Deleting file (DELETE)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$USERNAME:$PASSWORD" -X DELETE "$BASE_URL/$TEST_FILE")

if [ "$HTTP_CODE" -eq 204 ]; then
    log_info "[PASS] File deletion (204) - Passed"
else
    log_error "[FAIL] File deletion failed. Expected 204, got $HTTP_CODE"
    exit 1
fi

# 7. Test: Verify Deletion
log_info "Test 5: Verifying deletion..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$USERNAME:$PASSWORD" "$BASE_URL/$TEST_FILE")

if [ "$HTTP_CODE" -eq 404 ]; then
    log_info "[PASS] File gone (404) - Passed"
else
    log_error "[FAIL] File still exists or error. Expected 404, got $HTTP_CODE"
    exit 1
fi

# 8. Test: Default Credentials
log_info "Test 6: Verifying Default Credentials..."
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true

log_info "Starting container with defaults..."
docker run -d --name $CONTAINER_NAME -p $PORT:80 $IMAGE_NAME > /dev/null
sleep 3 # Wait for startup

DEFAULT_USER="zotero"
DEFAULT_PASS="ZoteroPass!"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$DEFAULT_USER:$DEFAULT_PASS" "$BASE_URL/")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 404 ]; then
    # 404 is acceptable for root / if no index exists, but 200 is better if autoindex is on.
    # Actually, WebDAV root might return 200 OK for PROPFIND or similar, but GET on empty dir might be 403 or 200 depending on config.
    # Let's just check we are NOT 401.
    log_info "[PASS] Default auth accepted ($HTTP_CODE) - Passed"
elif [ "$HTTP_CODE" -eq 401 ]; then
    log_error "[FAIL] Default credentials rejected (401)."
    exit 1
else
    log_info "[PASS] Default auth accepted ($HTTP_CODE) - Passed"
fi

log_info "[SUCCESS] All tests passed successfully!"
