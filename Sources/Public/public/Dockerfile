FROM swift:5.9
WORKDIR /app
COPY . .
RUN swift build -c release
CMD .build/release/Run serve --env production --hostname 0.0.0.0 --port 8080