.PHONY: build run test clean

GITHUB_USERNAME ?= by3nrique
IMAGE_NAME := ghcr.io/$(GITHUB_USERNAME)/zotero-serverless:latest
CONTAINER_NAME := zotero-webdav-instance
PORT := 8080

build:
	docker build -t $(IMAGE_NAME) ./docker

push: build
	docker push $(IMAGE_NAME)


run:
	docker run -d --name $(CONTAINER_NAME) \
		-p $(PORT):80 \
		-e WEBDAV_USERNAME=zotero \
		-e WEBDAV_PASSWORD=ZoteroPass! \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

test:
	chmod +x tests/test_docker.sh
	./tests/test_docker.sh

logs:
	docker logs -f $(CONTAINER_NAME)
