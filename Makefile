ASSETS :=  $(shell find ./assets/compat)
VERSION := $(shell yq e ".version" manifest.yaml)
BWT_SRC := $(shell find ./bwt/src) bwt/Cargo.toml bwt/Cargo.lock
CONFIGURATOR_SRC := $(shell find ./configurator/src) configurator/Cargo.toml configurator/Cargo.lock

.DELETE_ON_ERROR:

all: verify

verify: bwt.s9pk

install:
	embassy-cli package install bwt

bwt.s9pk: manifest.yaml $(ASSETS) image.tar instructions.md
	embassy-sdk pack
	embassy-sdk verify bwt.s9pk

instructions.md: README.md
	cp README.md instructions.md

image.tar: Dockerfile docker_entrypoint.sh bwt/target/aarch64-unknown-linux-musl/release/bwt configurator/target/aarch64-unknown-linux-musl/release/configurator
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/bwt/main:$(VERSION) --platform=linux/arm64/v8 -o type=docker,dest=image.tar .

bwt/target/aarch64-unknown-linux-musl/release/bwt: $(BWT_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/bwt:/home/rust/src start9/rust-musl-cross:aarch64-musl cargo +beta build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/bwt:/home/rust/src start9/rust-musl-cross:aarch64-musl musl-strip target/aarch64-unknown-linux-musl/release/bwt

configurator/target/aarch64-unknown-linux-musl/release/configurator: $(CONFIGURATOR_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:aarch64-musl cargo +beta build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:aarch64-musl musl-strip target/aarch64-unknown-linux-musl/release/configurator

# manifest.yaml: bwt/Cargo.toml
# 	yq w -i manifest.yaml version $(VERSION)
