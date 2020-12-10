FROM debian:buster-slim

RUN apt update
RUN apt install tini

ADD ./bwt/target/armv7-unknown-linux-musleabihf/release/bwt /usr/local/bin/bwt
ADD ./configurator/target/armv7-unknown-linux-musleabihf/release/configurator /usr/local/bin/configurator
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
