FROM nvidia/cuda:13.5.0-runtime-ubuntu24.04@sha256:ba4d4e8475ced890fb26f9661daf8dae7cce9827613682eb8b8379c5ecd94eba

ARG BASALT_VERSION=v0.5.7
ENV PATH=/opt/basalt-${BASALT_VERSION}-linux-x64/bin:$PATH
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["basalt", "serve", "--config", "/app/basalt_config.json"]

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/jesdga95/basalt/releases/download/${BASALT_VERSION}/basalt-${BASALT_VERSION}-linux-x64.tar.gz" \
    | tar xz -C /opt \
    && pip3 install --no-cache-dir --break-system-packages -r \
        "/opt/basalt-${BASALT_VERSION}-linux-x64/requirements.txt"