# ===============================
# BUILD STAGE
# ===============================
FROM node:22 AS builder

WORKDIR /juice-shop

# 1. Копируем манифесты
COPY package*.json ./

# 2. Устанавливаем зависимости (dev + prod)
RUN npm install --unsafe-perm

# 3. Копируем исходники
COPY . .

# 4. Сборка
RUN npm run build

# 5. Удаляем dev deps
RUN npm prune --omit=dev

# 6. Очистка
RUN rm -rf frontend/node_modules \
           frontend/.angular \
           frontend/src/assets \
           data/chatbot/botDefaultTrainingData.json || true \
    && rm -f ftp/legal.md || true \
    && rm -f i18n/*.json || true

# 7. Права
RUN mkdir logs \
 && chown -R 65532:0 logs ftp frontend/dist data i18n \
 && chmod -R g=u logs ftp frontend/dist data i18n


# ===============================
# RUNTIME STAGE
# ===============================
FROM gcr.io/distroless/nodejs22-debian12

WORKDIR /juice-shop

COPY --from=builder --chown=65532:0 /juice-shop .

USER 65532

EXPOSE 3000
CMD ["/juice-shop/build/app.js"]
