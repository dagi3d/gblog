FROM denoland/deno:alpine AS build
RUN apk add sqlx nodejs pnpm git
COPY --from=ghcr.io/gleam-lang/gleam:v1.18.1-erlang-alpine /bin/gleam /bin/gleam
COPY . /app/
WORKDIR /app
RUN /bin/gleam build --target javascript
ENV DATABASE_URL=sqlite://blog.db
RUN sqlx database create
RUN sqlx migrate run
RUN deno install
ENV CI=true
RUN pnpm run build:assets


FROM denoland/deno:alpine
RUN apk add bash
COPY --from=build /app/build /app/build/
COPY --from=build /app/node_modules /app/node_modules/
COPY --from=build /app/pnpm* /app/
COPY --from=build /app/package.json /app/
COPY --from=build /app/templates /app/templates/
COPY --from=build /app/public /app/public/
COPY --from=build /app/blog.db /app/
COPY *.mjs /app/
COPY entrypoint.sh /app/
COPY gleam.toml /app/
WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["deno", "-A", "entry.mjs", "start"]
