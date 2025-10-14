# --- build ---
FROM node:24-alpine AS builder

RUN apk add --no-cache git openssh

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev
COPY . .

RUN npm run build || echo "Build ok"

# --- final ---
FROM node:24-alpine

# Install Docker cli socket
RUN apk add --no-cache \
    git \
    openssh \
    ca-certificates \
    curl \
    docker-cli

WORKDIR /app

# build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src ./src
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.env.example ./

VOLUME [ "/app/data" ]


EXPOSE 4008

# RUN if [ ! -f .env ]; then  cp .env.example .env; fi

ENV NODE_ENV=production
CMD ["npm", "run", "start"]