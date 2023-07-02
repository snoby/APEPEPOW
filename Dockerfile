# Multistage docker build, requires docker 17.05

# builder stage
FROM ubuntu:20.04 as builder

RUN set -ex && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes install \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        libtool \
        pkg-config \
        gperf

WORKDIR /src
COPY . .

RUN chmod 764  ./contrib/depends/config.guess
RUN chmod 764  ./contrib/depends//config.sub

ARG NPROC
RUN set -ex && \
    git submodule init && git submodule update && \
    rm -rf build && \
    if [ -z "$NPROC" ] ; \
    then make -j$(nproc) depends target=x86_64-linux-gnu ; \
    else make -j$NPROC depends target=x86_64-linux-gnu ; \
    fi

# runtime stage
FROM ubuntu:20.04

RUN set -ex && \
    apt-get update && \
    apt-get --no-install-recommends --yes install ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt
COPY --from=builder /src/build/x86_64-linux-gnu/release/bin /usr/local/bin/

# Create apepepow user
RUN adduser --system --group --disabled-password apepepow && \
	mkdir -p /wallet /data/ /home/apepepow/.bitapepepow && \
	chown -R apepepow:apepepow /home/apepepow/.bitapepepow && \
	chown -R apepepow:apepepow /wallet && \
	chown -R apepepow:apepepow /data

# Contains the blockchain
VOLUME /home/apepepow/.bitapepepow

# Generate your wallet via accessing the container and run:
# cd /wallet
# apepepow-wallet-cli
VOLUME /wallet
VOLUME /data

EXPOSE 6363
EXPOSE 6464

# switch to user apepepow
USER apepepow

ENTRYPOINT ["apepepowd"]
CMD [ "--non-interactive", "--confirm-external-bind"]

