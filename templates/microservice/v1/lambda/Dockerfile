{% if values.language == 'nodejs' %}
FROM node:22-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY src ./src

ENV NODE_ENV=development
EXPOSE 8080
CMD ["npm", "start"]
{% else %}
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY src ./src

EXPOSE 8080
CMD ["python", "src/app.py"]
{% endif %}
