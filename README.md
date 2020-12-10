# Wrapper for bwt

`bwt` is a lightweight wallet descriptor/xpub tracker and query engine for Bitcoin, implemented in Rust.

## Dependencies

- [docker](https://docs.docker.com/get-docker)
- [docker-buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [yq](https://mikefarah.gitbook.io/yq)
- [toml](https://crates.io/crates/toml-cli)
- [appmgr](https://github.com/Start9Labs/appmgr)
- [make](https://www.gnu.org/software/make/)

## Cloning

Clone the project locally. Note the submodule link to the original project(s). 

```
git clone git@github.com:chrisguida/bwt-wrapper.git
cd bwt-wrapper
git submodule update --init
```

## Building

To build the project, run the following commands:

On build machine:
```
<!-- make -->
wget -P ~ https://github.com/shesek/bwt/releases/download/v0.2.0/bwt-0.2.0-arm32v7.tar.gz
tar -C ~ -zxvf ~/bwt-0.2.0-arm32v7.tar.gz
mkdir -p bwt/target/armv7-unknown-linux-musleabihf/release/
cp ~/bwt-0.2.0-arm32v7/bwt bwt/target/armv7-unknown-linux-musleabihf/release/
make configurator/target/armv7-unknown-linux-musleabihf/release/configurator
DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/bwt --platform=linux/arm/v7 -o type=docker,dest=image.tar .
appmgr -vv pack $(pwd) -o bwt.s9pk
appmgr -vv verify bwt.s9pk
```

## Installing (on Embassy)

SSH into an Embassy device.
`scp` the `.s9pk` to any directory from your local machine.
Run the following command to determine successful install:

```
appmgr install bwt.s9pk
```
