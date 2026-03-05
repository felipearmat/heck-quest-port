# Build image for Heck Quest mod (Beat Saber 1.40.7).
# Includes qpm-rust, CMake, Ninja, NDK, PowerShell — minimal host install (only Docker).
#
# Build (use linux/amd64 on macOS ARM so NDK works; see SETUP.md):
#   docker build -t heck-quest-build .
#   On macOS Apple Silicon: docker build --platform linux/amd64 -t heck-quest-build .
#
# Run full build + qmods from repo root:
#   ./scripts/docker-build.sh   (or pwsh ./scripts/docker-build.ps1)

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base build tools + deps for qpm-rust (Rust keyring crate needs libsecret)
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    ninja-build \
    git \
    unzip \
    wget \
    ca-certificates \
    build-essential \
    pkg-config \
    libssl-dev \
    libsecret-1-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Rust (for building qpm-rust)
ENV PATH="/root/.cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && rustup default stable

# qpm-rust (Quest Package Manager) — required for restore + qmod manifest
RUN cargo install --git https://github.com/RedBrumbler/QuestPackageManager-Rust --locked

# PowerShell (for running build.ps1 / createqmod.ps1 inside container)
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm -rf /var/lib/apt/lists/*

# Android NDK r27 (Linux x86_64 only; on macOS ARM use --platform linux/amd64 when building image)
# If the URL fails, check https://developer.android.com/ndk/downloads
ENV ANDROID_NDK_HOME=/opt/android-ndk
RUN mkdir -p /opt && cd /opt \
    && wget -q "https://dl.google.com/android/repository/android-ndk-r27c-linux.zip" -O ndk.zip \
    && unzip -q ndk.zip && mv android-ndk-r27c android-ndk && rm ndk.zip

WORKDIR /src
