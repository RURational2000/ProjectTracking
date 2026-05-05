FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Disable SSL verification for curl globally
RUN git config --global http.sslVerify false

# Install Flutter from zip
RUN mkdir -p /opt && cd /opt && \
    curl -k -L -o flutter.zip "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz" && \
    tar -xf flutter.zip && \
    rm flutter.zip && \
    /opt/flutter/bin/flutter config --no-analytics

ENV PATH="/opt/flutter/bin:$PATH"

WORKDIR /workspace
COPY . .

RUN flutter pub get
CMD ["flutter", "test"]
