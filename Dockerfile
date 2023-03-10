FROM ubuntu:kinetic as builder

ARG ODYSSEY_VERSION=1.3
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /tmp/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    git
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc \
    gdb \
    libpam0g-dev \
    libssl-dev \
    postgresql-server-dev-14 \
    valgrind \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# hadolint ignore=DL3003
RUN git clone --branch ${ODYSSEY_VERSION} --depth 1 http://github.com/yandex/odyssey.git \
    && cd odyssey \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make
WORKDIR /tmp/odyssey
RUN grep -v -E '^(#.*|)$' odyssey.conf > build/sources/odyssey-slim.conf


FROM ubuntu:kinetic
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN groupadd -r odyssey && useradd -r -g odyssey odyssey
COPY --from=builder /tmp/odyssey/build/sources/odyssey /usr/local/bin/
COPY --from=builder /tmp/odyssey/build/sources/odyssey-slim.conf /etc/odyssey/odyssey.conf
COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh
# USER odyssey
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 5432
CMD ["odyssey"]
