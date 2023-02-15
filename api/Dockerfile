
FROM node:12.18.1

WORKDIR /app

EXPOSE ${PORT:-80}

COPY ["package.json", "./"]

RUN npm install

COPY . .

CMD ["npm", "start"]

