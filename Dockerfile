FROM node:24-bookworm-slim

COPY . /app
WORKDIR /app

RUN set -x \
    && yarn install --network-timeout 360000 \
    && yarn cache clean

ENV VITE_API_URL="http://localhost:8000"
ENTRYPOINT ["yarn"]
CMD ["dev", "--host", "0.0.0.0"]
