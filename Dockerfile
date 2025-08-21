# Etapa 1 — build da aplicação React
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

# Instala envsubst (para substituir ${PORT})
RUN apk add --no-cache bash gettext

# Copia arquivos estáticos
COPY --from=builder /app/dist /usr/share/nginx/html

# Copia template do Nginx
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Usa envsubst para criar o arquivo final de configuração na inicialização
CMD ["/bin/bash", "-c", "envsubst < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]
