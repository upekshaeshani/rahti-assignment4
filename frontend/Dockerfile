# syntax=docker/dockerfile:1

FROM nginx:1.27-alpine

COPY frontend/nginx.conf /etc/nginx/nginx.conf
COPY frontend/index.html /usr/share/nginx/html/index.html

EXPOSE 8080