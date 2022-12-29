FROM golang:1.18-buster as builder
WORKDIR /app
COPY go.mod go.sum main.go ./
RUN go build -o server

FROM debian:buster-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/server /app/server
CMD ["/app/server"]
