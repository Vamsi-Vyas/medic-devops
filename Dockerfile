
# ==============================================================
# Multi-stage Security-Hardened Dockerfile
# Healthcare System - DevSecOps
# ==============================================================

# =========================
# 1. BUILD STAGE
# =========================
FROM node:20-alpine AS builder

# Update npm for dependency installation
RUN npm install -g npm@11

WORKDIR /usr/src/app

# Copy dependency manifests
COPY package*.json ./

# Install production dependencies
RUN npm ci --omit=dev --no-audit --no-fund \
    && npm cache clean --force

# =========================
# 2. RUNTIME STAGE
# =========================
FROM node:20-alpine

# Install security updates and required packages
RUN apk update \
    && apk upgrade \
    && apk add --no-cache wget ca-certificates

# Remove npm and npx because they are not needed at runtime
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx \
    /root/.npm

WORKDIR /usr/src/app

# Production environment
ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=1.0.0 \
    DEPLOYMENT_COLOR=blue

# Copy production dependencies from builder
COPY --from=builder --chown=node:node /usr/src/app/node_modules ./node_modules

# Copy application manifests
COPY --chown=node:node package*.json ./

# Copy application source and tests
COPY --chown=node:node src/ ./src/
COPY --chown=node:node test/ ./test/

# Run as non-root user
USER node

# Container health check
HEALTHCHECK --interval=20s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/healthz || exit 1

# Expose application port
EXPOSE 3000

# Start application
CMD ["node", "src/server.js"]
