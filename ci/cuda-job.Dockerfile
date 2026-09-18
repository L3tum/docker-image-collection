# Job image for the `cuda` runner label (see the runner host's .github/workflows/ci.yml).
#
# Base = the SAME image the `ubuntu-latest` label already uses
# (docker.gitea.com/runner-images:ubuntu-latest =
# catthehacker/ubuntu:act-24.04 + runner bits), so the job gets everything
# the no-cuda job gets: Node 24 (default; actions/checkout v7 works
# unchanged), git, curl, ca-certificates. The only delta is what that base
# lacks for the GPU job:
#
#   CUDA 13.4 toolkit (nvcc + dev libraries) — installed from NVIDIA's apt
#         repo, the same source the stock nvidia/cuda images install from.
#         Driver side (nvidia-smi, libcuda) is NOT in the image: the nvidia
#         container runtime injects it at job start (--gpus=all at runner
#         level).
#   Rust >= 1.85 — the act base does not ship it (Rust lives in the sibling
#         catthehacker/ubuntu:rust-* images); baked in here via rustup.
#
# The stock nvidia/cuda devel image was rejected as a base because it ships
# NO node/git/curl (its base layer purges curl after keyring install), which
# would force a manual apt bootstrap + git clone step into the workflow in
# place of actions/checkout.
#
# Build + push: handled by .forgejo/workflows/docker.yaml in this repo
# (builds on PRs, pushes on release). On release the image is pushed under
# two tags:
#   cuda-13.4-latest    — stable "current CUDA" tag; point the runner here
#   cuda-13.4-<version> — pins the image to the repo release version, e.g.
#                         cuda-13.4-1.0.0 for release 1.0.0
# Manual equivalent (stable tag):
#
#   docker build -f ci/cuda-job.Dockerfile \
#     -t <registry>/<org>/docker-image-collection/cuda-job:cuda-13.4-latest .
#   docker push <registry>/<org>/docker-image-collection/cuda-job:cuda-13.4-latest
#
# then point the runner's `cuda` label at the pushed image:
#
#   cuda:docker://<registry>/<org>/docker-image-collection/cuda-job:cuda-13.4-latest
#
# (Registry-less alternative on a single box:
#   docker save ... | docker -H tcp://forgejo-runner-dind:2375 load ...
#  This works because container.force_pull defaults to false, so dind reuses
#  the preloaded image. A registry is nicer for rebuilds.)

FROM docker.gitea.com/runner-images:ubuntu-latest@sha256:fd911d7417bfbf0f454530e447da95b58001e1df41bbc5e1a8dd35d432575aae

ENV DEBIAN_FRONTEND=noninteractive

# CUDA 13.4 toolkit from NVIDIA's apt repo. `cuda-toolkit-13-4` = nvcc +
# all dev libraries, installed under /usr/local/cuda (nvcc at
# /usr/local/cuda/bin). If the final image is too big, the lean alternative
# is: cuda-nvcc-13-4 cuda-cudart-dev-13-4 cuda-nvml-dev-13-4
# libcublas-dev-13-4 libnccl-dev cuda-nsight-compute-13-4
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget gnupg \
    && wget -qO cuda-keyring.deb \
         https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring.deb && rm cuda-keyring.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends cuda-toolkit-13-4 \
    && rm -rf /var/lib/apt/lists/*

# CUDA toolkit env: same values the stock nvidia/cuda images set.
ENV CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Rust toolchain in /usr/local/cargo so it is on PATH for every job without
# GITHUB_PATH. Workspace floor: >=1.85 (see ci.yml ensure-rust).
#
# NOTE: the runner's container.options must NOT mount a volume over
# /usr/local/cargo (it would shadow this baked-in toolchain). For a warm
# crate cache use a sub-path mount instead:
#   --volume /cache/cargo-registry:/usr/local/cargo/registry
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh \
    && sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain stable \
    && rm /tmp/rustup-init.sh \
    && cargo --version && rustc --version

# Sanity: JS actions need `node`, checkout needs `git`, the build needs nvcc.
# (nvidia-smi is deliberately NOT checked — it only exists at job runtime,
# once the nvidia runtime injects the driver.)
RUN node --version && git --version && nvcc --version
