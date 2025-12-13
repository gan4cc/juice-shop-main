# ===============================
# BUILD STAGE
# ===============================
FROM node:22-alpine AS builder

WORKDIR /juice-shop

# 1. Копируем только манифесты (кеш Docker)
COPY package*.json ./

# 2. Ставим ВСЕ зависимости (dev + prod)
RUN npm ci --unsafe-perm

# 3. Копируем исходники
COPY . .

# 4. Сборка Juice Shop
RUN npm run build

# 5. Удаляем dev-зависимости ПОСЛЕ сборки
RUN npm prune --omit=dev

# 6. Очистка лишнего (как у тебя, но безопасно)
RUN rm -rf frontend/node_modules \
           frontend/.angular \
           frontend/src/assets \
           data/chatbot/botDefaultTrainingData.json || true \
    && rm -f ftp/legal.md || true \
    && rm -f i18n/*.json || true

# 7. Папка логов и права
RUN mkdir logs \
 && chown -R 65532:0 logs ftp frontend/dist data i18n \
 && chmod -R g=u logs ftp frontend/dist data i18n

# 8. SBOM (опционально, но ок)
ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION \
 && npm run sbom


# ===============================
# RUNTIME STAGE
# ===============================
FROM gcr.io/distroless/nodejs22-debian12

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
      org.opencontainers.image.title="OWASP Juice Shop" \
      org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
      org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
      org.opencontainers.image.vendor="Open Worldwide Application Security Project" \
      org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="18.0.0" \
      org.opencontainers.image.url="https://owasp-juice.shop" \
      org.opencontainers.image.source="https://github.com/juice-shop/juice-shop" \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE

WORKDIR /juice-shop

# Копируем ТОЛЬКО готовый результат
COPY --from=builder --chown=65532:0 /juice-shop .

USER 65532

EXPOSE 3000

CMD ["/juice-shop/build/app.js"]
