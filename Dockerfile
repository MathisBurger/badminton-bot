FROM rust:latest AS build
RUN USER=root cargo new --bin badminton_bot
WORKDIR ./badminton_bot
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
RUN cargo build --release
RUN rm src/*.rs

COPY . .
RUN rm ./target/release/deps/badminton_bot*
RUN cargo build --release

FROM debian:bullseye-slim AS final

# Install dependencies for Firefox, Geckodriver, and necessary tools
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    libdbus-1-3 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libasound2 \
    libgtk-3-0 \
    libgbm1 \
    libgdk-pixbuf-2.0-0 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libappindicator3-1 \
    libnspr4 \
    libnss3 \
    && apt-get clean

RUN FIREFOX_VERSION="111.0" && \
    wget -q "https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2" && \
    tar -xjf "firefox-${FIREFOX_VERSION}.tar.bz2" && \
    mv firefox /opt/firefox && \
    ln -s /opt/firefox/firefox /usr/local/bin/firefox && \
    rm "firefox-${FIREFOX_VERSION}.tar.bz2"

# Install Geckodriver - Download the compatible version for Firefox
RUN GECKODRIVER_VERSION=$(curl -s https://github.com/mozilla/geckodriver/releases/latest | grep -oP 'tag/v\K([0-9.]+)' | head -n 1) && \
    wget -q "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" && \
    tar -xvzf "geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" && \
    mv geckodriver /usr/local/bin/ && \
    rm "geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz"

# Use Busybox for basic utilities
COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh

# Set working directory and copy application binary
WORKDIR /app
COPY --from=build /badminton_bot/target/release/badminton_bot /app/badminton_bot

# Run geckodriver and badminton_bot on startup
CMD geckodriver --headless --log trace & ./badminton_bot
