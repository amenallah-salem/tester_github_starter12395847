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
ENV PATH=$FLUTTER_SDK/bin:$PATH

RUN git clone \
    --branch ${FLUTTER_VERSION} \
    --depth 1 \
    https://github.com/flutter/flutter.git \
    ${FLUTTER_SDK}

RUN flutter doctor

WORKDIR /app

COPY pubspec.yaml ./

RUN flutter pub get

COPY . .

RUN flutter build web --release

# Runtime
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]