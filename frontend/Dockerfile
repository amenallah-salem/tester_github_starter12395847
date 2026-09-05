FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Flutter
ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_SDK=/opt/flutter
ENV PATH=$FLUTTER_SDK/bin:$PATH FLUTTER_WEB_USE_SKIA=true

ENV DART_VM_OPTIONS="--no-causal-async-stacks"

RUN git clone \
    --branch ${FLUTTER_VERSION} \
    --depth 1 \
    https://github.com/flutter/flutter.git \
    ${FLUTTER_SDK}

# Create a non-root user for Flutter operations and ensure ownership
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder \
    && chown -R builder:builder ${FLUTTER_SDK} \
    && mkdir -p /app && chown -R builder:builder /app

# Switch to non-root user for Flutter commands (avoids Flutter's root warning)
USER builder

WORKDIR /app

COPY --chown=builder:builder pubspec.yaml ./

RUN flutter pub get

COPY --chown=builder:builder . .

RUN dart run build_runner build --delete-conflicting-outputs

RUN flutter build web --release

# Revert to root for the final runtime image stage (COPY from builder does not need root here)

# Runtime
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]