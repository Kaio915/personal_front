# Dockerfile para Flutter Web
# Stage 1: Build da aplicação Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de configuração do projeto
COPY pubspec.yaml pubspec.lock ./

# Baixa as dependências
RUN flutter pub get

# Copia todo o código fonte
COPY . .

# Build da aplicação web para produção
RUN flutter build web --release

# Stage 2: Servidor Nginx para servir os arquivos estáticos
FROM nginx:alpine

# Copia os arquivos buildados do stage anterior
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copia configuração customizada do Nginx (se existir)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta 80
EXPOSE 80

# Inicia o Nginx
CMD ["nginx", "-g", "daemon off;"]