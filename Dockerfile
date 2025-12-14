# ===============================
# BUILD STAGE
# ===============================
FROM node:22 AS builder

WORKDIR /juice-shop

COPY . .

# 2. Установка зависимостей
# postinstall использует frontend/, поэтому он уже должен быть
RUN npm install --unsafe-perm

# 3. Удаляем dev зависимости
RUN npm prune --omit=dev

# 4. Очистка мусора
RUN rm -rf frontend/node_modules \
           frontend/.angular \
           frontend/src/assets || true \
 && rm -f ftp/legal.md || true \
 && rm -f data/chatbot/botDefaultTrainingData.json || true \
 && rm -f i18n/*.json || true

# 5. Права
RUN mkdir -p logs \
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
