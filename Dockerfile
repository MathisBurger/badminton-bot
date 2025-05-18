# -------- Stage 1: Install dependencies and build the app --------
FROM oven/bun:1.1.12 AS builder

# Set working directory
WORKDIR /app

# Copy bun config and dependencies
COPY bun.lockb package.json tsconfig.json ./

# Install deps (cached layer if no changes)
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# -------- Stage 2: Final image with Playwright --------
FROM mcr.microsoft.com/playwright:v1.44.0-jammy

# Set working directory
WORKDIR /app

# Copy built app and node_modules from builder
COPY --from=builder /app /app

# Install Bun in the Playwright base image
RUN apt-get update && apt-get install -y unzip curl && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://bun.sh/install | bash && \
    ln -s /root/.bun/bin/bun /usr/local/bin/bun

# Default command
CMD ["bun", "run", "index.ts"]
