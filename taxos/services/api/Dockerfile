# Build the TaxOS API as a self-contained AOT binary.
FROM dart:stable AS build
WORKDIR /src
# Build from the monorepo root: docker build -f services/api/Dockerfile .
# A trimmed workspace keeps the Flutter packages out of the server image.
RUN printf 'name: taxos_workspace\nenvironment:\n  sdk: ^3.6.0\nworkspace:\n  - packages/tax_engine\n  - services/api\n' > pubspec.yaml
COPY packages/tax_engine ./packages/tax_engine
COPY services/api ./services/api
RUN mkdir -p /app && cd services/api && dart pub get && dart compile exe bin/server.dart -o /app/server

# Minimal runtime: the AOT binary plus the shared libraries the dart image
# ships under /runtime for exactly this purpose (needs a scratch base).
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/server"]
