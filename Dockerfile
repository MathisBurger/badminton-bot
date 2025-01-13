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

FROM busybox:1.35.0-uclibc as busybox

FROM gcr.io/distroless/cc-debian12
ARG ARCH=x86_64

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

# Install Firefox (Headless)
RUN wget -q https://ftp.mozilla.org/pub/firefox/releases/latest/linux-x86_64/en-US/firefox-*.tar.bz2 && \
    tar -xjf firefox-*.tar.bz2 && \
    mv firefox /opt/firefox && \
    ln -s /opt/firefox/firefox /usr/local/bin/firefox && \
    rm firefox-*.tar.bz2

# Install Geckodriver
RUN FIREFOX_VERSION=$(firefox --version | awk '{print $3}') && \
    GECKODRIVER_VERSION=$(curl -s https://github.com/mozilla/geckodriver/releases/latest | \
    grep -oP 'tag/v\K([0-9.]+)' | head -n 1) && \
    wget -q https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz && \
    tar -xvzf geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz && \
    mv geckodriver /usr/local/bin/ && \
    rm geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz

# Use Busybox for basic utilities
COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh

# Copy necessary libraries from build stage
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libpq.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libgssapi_krb5.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libldap_r-2.4.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libkrb5.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libk5crypto.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libkrb5support.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/liblber-2.4.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libsasl2.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libgnutls.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libp11-kit.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libidn2.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libunistring.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libtasn1.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libnettle.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libhogweed.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libgmp.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /usr/lib/${ARCH}-linux-gnu/libffi.so* /usr/lib/${ARCH}-linux-gnu/
COPY --from=build /lib/${ARCH}-linux-gnu/libcom_err.so* /lib/${ARCH}-linux-gnu/
COPY --from=build /lib/${ARCH}-linux-gnu/libkeyutils.so* /lib/${ARCH}-linux-gnu/
COPY --from=build /lib/${ARCH}-linux-gnu/libldap* /lib/${ARCH}-linux-gnu/
COPY --from=build /lib/${ARCH}-linux-gnu/liblber* /lib/${ARCH}-linux-gnu/

# Set working directory and copy application binary
WORKDIR /app
COPY --from=build /badminton_bot/target/release/badminton_bot /app/badminton_bot

# Run geckodriver and badminton_bot on startup
CMD geckodriver --headless --log trace & ./badminton_bot
