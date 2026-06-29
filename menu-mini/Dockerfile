# menu-mini H5 构建 + Nginx 托管
# 第一阶段：构建
FROM node:20-alpine AS build
WORKDIR /build
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
RUN npm run build:h5

# 第二阶段：Nginx 托管
FROM nginx:alpine
COPY --from=build /build/dist/build/h5 /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
