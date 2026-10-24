# ==============================================================
# Multi-stage Security-Hardened Dockerfile for Healthcare System
# DevSecOps Best Practice: Runs as unprivileged non-root user (node)
# ==============================================================

# Build Stage
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Copy dependency manifests
COPY package*.json ./

# Install dependencies (only production deps needed)
RUN npm ci --only=production && npm cache clean --force

# Runtime Stage
FROM node:20-alpine

# Security hardening: Install ca-certificates and security updates
RUN apk update && apk upgrade && apk add --no-cache wget ca-certificates

WORKDIR /usr/src/app

# Set production environment
ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=1.0.0 \
    DEPLOYMENT_COLOR=blue

# Copy dependencies from builder stage
COPY --from=builder --chown=node:node /usr/src/app/node_modules ./node_modules
COPY --chown=node:node package*.json ./

# Copy source code and test files
COPY --chown=node:node src/ ./src/
COPY --chown=node:node test/ ./test/

# Enforce DevSecOps: Switch to non-root user 'node' (UID: 1000)
USER node

# Healthcheck probe
HEALTHCHECK --interval=20s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/healthz || exit 1

EXPOSE 3000

# Start server
CMD ["node", "src/server.js"]
