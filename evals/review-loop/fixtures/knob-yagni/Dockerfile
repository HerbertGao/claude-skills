FROM node:22-alpine

WORKDIR /app

ENV DATA_DIR=/var/lib/mailsift \
    CONFIG_DIR=/etc/mailsift \
    BATCH_SIZE=200 \
    LOG_LEVEL=info

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

RUN mkdir -p "$DATA_DIR" && touch "$DATA_DIR/noise_senders.overlay"

EXPOSE 8080
CMD ["node", "src/index.js"]
