FROM nginx:1.27-alpine

COPY frontend/nginx.conf /etc/nginx/nginx.conf
COPY frontend/index.html /usr/share/nginx/html/index.html
COPY frontend/docs/week5-assignment.pdf /usr/share/nginx/html/docs/week5-assignment.pdf

EXPOSE 8080