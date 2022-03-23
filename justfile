# Entry point repository sub-commands, help, and general starting tasks
set shell         := ["bash", "-c"]
set dotenv-load   := true
export DOCKER_TAG := env_var_or_default("DOCKER_TAG", `if [ "${GITHUB_ACTIONS}" = "true" ]; then echo "${GITHUB_SHA}"; else echo "$(git rev-parse --short=8 HEAD)"; fi`)
DOCKER_USERNAME   := env_var_or_default("DOCKER_USERNAME", "")
DOCKER_PASSWORD   := env_var_or_default("DOCKER_PASSWORD", "")

@_help:
    printf "\n"
    just --list --unsorted --list-heading $'⚡ Repository commands: (docs for needed env vars https://github.com/metapages/postgres-cloud-backup-restore)\n'
    printf "\n"

# Bump the version and push a git tag (triggers pushing new docker image) [major, minor, patch]
publish inc="patch":
    #!/usr/bin/env deno run --unstable --allow-all
    import * as semver from "https://deno.land/x/semver@v1.4.0/mod.ts";
    import { exec, OutputMode } from "https://deno.land/x/exec@0.0.5/mod.ts";
    //let response = await exec('git ls-remote --tags origin', {output: OutputMode.Capture});
    let response = await exec('git tag', {output: OutputMode.Capture});
    if (response.status.code !== 0) {
        console.log(response);
        throw new Error("Failed to list tags");
    }
    let tags = response.output
        .split("\n")
        .map(line => line.trim())
        .filter(line => line.length > 0)
        .filter(line => semver.valid(line));
    tags.sort(semver.compare);
    let current = tags.length > 0 ? tags[tags.length - 1] : "0.0.0";
    let next = semver.inc(current, "{{inc}}");
    response = await exec(`git tag v${next}`, {output: OutputMode.StdOut});
    if (response.status.code !== 0) {
        console.log(response.output);
        throw new Error("Failed to create tag");
    }
    response = await exec(`git push origin v${next}`, {output: OutputMode.StdOut});
    if (response.status.code !== 0) {
        console.log(response.output);
        throw new Error("Failed to push tag");
    }
    console.log(`Version v${semver.clean(current)} -> v${semver.clean(next)} (tag pushed to git origin)`);



# Push (versioned from git tag) (both arm64/amd64) images to the registry.
push: (_ensure "DOCKER_USERNAME") (_ensure "DOCKER_PASSWORD")
    #!/usr/bin/env bash
    set -euo pipefail
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    echo {{DOCKER_PASSWORD}} | docker login -u {{DOCKER_USERNAME}} --password-stdin
    # Excellent blog: https://netfuture.ch/2020/05/multi-arch-docker-image-easy/
    # Guide: https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408
    # buildkit is required for multi-architecture builds
    # I saw this 👇 here 👉 https://github.com/marthoc/docker-deconz/blob/master/.travis.yml and https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408
    echo -e "👀 Build failures on linux: rerun: docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
    if [ "$(docker buildx ls | grep multi-builder)" = "" ]; then
        echo -e " 🏗️ buildkit builder 'multi-builder' does not exist, creating"
        docker buildx create --name multi-builder
    else
        echo -e " 🏗️ buildkit builder already exists"
    fi
    docker buildx use multi-builder
    COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_TAG=$DOCKER_TAG docker buildx bake --push --set '*.platform=linux/amd64,linux/arm64' -f docker-compose.yml

# Run tests (inside the core container)
@test: _build
    just test/test

# Develop inside the core container, networked to a mock S3 storage API
dev:
    docker-compose run --entrypoint "bash" db-remote-clone

# Build docker image
_build:
    docker-compose -f docker-compose.yml build

@_ensure envvar:
    if [ "${{envvar}}" = "" ]; then echo "💥 Missing env var: {{envvar}}"; exit 1; fi
