ASSETS := $(shell yq r manifest.yaml assets.*.src)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION_TAG := $(shell git --git-dir=bwt/.git describe --abbrev=0)
VERSION := $(VERSION_TAG:v%=%)
VERSION_SIMPLE := $(VERSION:%-%=%)
BWT_SRC := $(shell find ./bwt/src) bwt/Cargo.toml bwt/Cargo.lock
CONFIGURATOR_SRC := $(shell find ./configurator/src) configurator/Cargo.toml configurator/Cargo.lock

.DELETE_ON_ERROR:

all: bwt.s9pk

install: bwt.s9pk
	appmgr install bwt.s9pk

bwt.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md $(ASSET_PATHS)
	appmgr -vv pack $(shell pwd) -o bwt.s9pk
	appmgr -vv verify bwt.s9pk

instructions.md: README.md
	cp README.md instructions.md

image.tar: Dockerfile docker_entrypoint.sh bwt/target/armv7-unknown-linux-musleabihf/release/bwt
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/bwt --platform=linux/arm/v7 -o type=docker,dest=image.tar .

bwt/target/armv7-unknown-linux-musleabihf/release/bwt: $(BWT_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/bwt:/home/rust/src start9/rust-musl-cross:armv7-musleabihf cargo +beta build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/bwt:/home/rust/src start9/rust-musl-cross:armv7-musleabihf musl-strip target/armv7-unknown-linux-musleabihf/release/bwt

configurator/target/armv7-unknown-linux-musleabihf/release/configurator: $(CONFIGURATOR_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:armv7-musleabihf cargo +beta build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:armv7-musleabihf musl-strip target/armv7-unknown-linux-musleabihf/release/configurator

manifest.yaml: bwt/Cargo.toml
	yq w -i manifest.yaml version $(VERSION)
