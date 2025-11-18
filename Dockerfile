# Intentionally using an older Node.js version for demonstration purposes
FROM node:14.17.0-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including vulnerable ones)
RUN npm install --production

# Copy application files
COPY app.js ./
COPY public ./public

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run as non-root user for security (even in demo)
USER node

CMD ["node", "app.js"]
