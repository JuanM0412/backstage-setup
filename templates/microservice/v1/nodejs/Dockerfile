FROM node:22-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src

ENV NODE_ENV=production
EXPOSE 8080
CMD ["sh", "-c", "if [ -n \"$NEW_RELIC_LICENSE_KEY\" ]; then exec node -r newrelic src/app.js; else exec npm start; fi"]