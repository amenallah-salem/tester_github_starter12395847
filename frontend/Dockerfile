FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk wget \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK
ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_SDK=/opt/flutter
RUN git clone --branch $FLUTTER_VERSION --depth 1 \
    https://github.com/flutter/flutter.git $FLUTTER_SDK \
    && chmod -R 755 $FLUTTER_SDK
ENV PATH=$FLUTTER_SDK/bin:$PATH

# Android SDK
ENV ANDROID_SDK=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_SDK
RUN mkdir -p $ANDROID_SDK/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
       -O /tmp/cmdtools.zip \
    && unzip -q /tmp/cmdtools.zip -d $ANDROID_SDK/cmdline-tools \
    && mv $ANDROID_SDK/cmdline-tools/cmdline-tools $ANDROID_SDK/cmdline-tools/latest \
    && rm /tmp/cmdtools.zip

ENV PATH=$ANDROID_SDK/cmdline-tools/latest/bin:$ANDROID_SDK/platform-tools:$PATH
RUN yes | sdkmanager --licenses > /dev/null 2>&1 \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

WORKDIR /app
COPY pubspec.yaml .
RUN flutter precache --no-android --no-ios --no-web || true
RUN flutter pub get
COPY . .
RUN flutter build web --release

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
