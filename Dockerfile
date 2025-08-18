# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Copia package.json e package-lock.json
COPY package*.json ./

# Instala todas as dependências (incluindo dev)
RUN npm install

# Copia o restante do código
COPY . .

# Build do projeto
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

# Instala serve para rodar o build
RUN npm install -g serve

# Copia apenas o build do stage anterior
COPY --from=builder /app/dist ./dist

EXPOSE 5000

# Comando para rodar a versão de produção
CMD ["serve", "-s", "dist", "-l", "5000"]
