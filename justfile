# Entry point repository sub-commands, help, and general starting tasks

set shell       := ["bash", "-c"]
set dotenv-load := true

@_help:
    printf "\n"
    just --list --unsorted --list-heading $'⚡ Repository commands:\n'
    printf "\n"

# Push (versioned from git tag) image to the registry
publish:
    echo "Publish (versioned) docker images somewhere (docker hub?)"

# Develop inside the core container, networked to a mock S3 storage API
dev:
    docker-compose run --entrypoint "bash" db-remote-clone

# Run tests (inside the core container)
@test: build
    just test/test

@build:
    docker-compose build
