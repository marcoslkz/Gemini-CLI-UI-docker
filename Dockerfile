# --- Etapa de build ---
FROM node:24-alpine AS builder

# Instala ferramentas necessárias para compilar dependências nativas
RUN apk add --no-cache \
    git \
    openssh \
    python3 \
    make \
    g++

WORKDIR /app

# Copia apenas os manifests (para melhor cache das camadas)
COPY package*.json ./

# Instala dependências (inclui módulos nativos)
RUN npm install --omit=dev

# Copia o restante do código-fonte
COPY . .

# Compila se houver build script (frontend ou bundler)
RUN npm run build || echo "Nenhum build necessário"

# --- Etapa final ---
FROM node:24-alpine

# Instala dependências básicas de runtime e Docker CLI
RUN apk add --no-cache \
    git \
    openssh \
    ca-certificates \
    curl \
    docker-cli \
    python3 \
    make \
    g++

WORKDIR /app

# Copia artefatos da build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.env.example ./

# Cria diretório persistente para o banco SQLite e configs
VOLUME [ "/app/data" ]

# Porta padrão usada pela aplicação
EXPOSE 4008

# Garante que o .env exista
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Define ambiente padrão
ENV NODE_ENV=production

# Comando de inicialização
CMD ["npm", "run", "start"]
