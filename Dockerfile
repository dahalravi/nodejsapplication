FROM node:10-alpine   // If local repo available, update the local update with the image so it does to use public image and as base_xxx name and use the same local repo

RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app

COPY package*.json ./

USER node

RUN npm install

COPY --chown=node:node . .

EXPOSE 8080

CMD [ "node", "app.js" ]
