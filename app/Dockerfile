# syntax=docker/dockerfile:1
FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production

COPY app.js ./

EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "app.js"]


