FROM nvidia/cuda:13.4.3-runtime-ubuntu24.04@sha256:f58bd7a0701fae3a2160f22e1d451b77b349bd9ef83dad76f5529aa413c149a8

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