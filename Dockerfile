# Etapa 1 — build da aplicação
FROM node:20-alpine AS builder
WORKDIR /app

# Copia package.json e lockfile
COPY package*.json ./
COPY pnpm-lock.yaml* ./

# Instala pnpm e dependências
RUN npm install -g pnpm
RUN pnpm install

# Copia código e faz build
COPY . .
RUN pnpm build

# Etapa 2 — servidor Nginx
FROM nginx:alpine

# Copia arquivos estáticos para a pasta do Nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Copia configuração customizada do Nginx para suportar React Router
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe porta 8080
EXPOSE 8080

# Inicia o Nginx no foreground
CMD ["nginx", "-g", "daemon off;"]
