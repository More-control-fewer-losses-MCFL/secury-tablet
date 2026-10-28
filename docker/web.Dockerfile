FROM debian:bookworm-slim AS flutter
ARG FLUTTER_VERSION=3.47.8
ARG FLUTTER_SHA256=baf7dcc5a3dbba60fe863bf493a6cf203195621f7786eaa5a1bba02cd0d87dd2
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN curl --fail --location --retry 3 \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum --check \
    && tar -xf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}" CI=true
WORKDIR /build
COPY frontend_flutter/pubspec.yaml frontend_flutter/pubspec.lock ./
RUN flutter config --no-analytics && flutter pub get
COPY frontend_flutter/ ./
RUN flutter build web --release --no-pub --dart-define=API_BASE_URL=/api

FROM nginx:1.28-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=flutter /build/build/web /usr/share/nginx/html
EXPOSE 80
