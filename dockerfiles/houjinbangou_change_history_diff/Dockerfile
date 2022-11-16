FROM golang:bullseye AS build
WORKDIR /go-src
COPY go.mod go.sum main.go ./
RUN go build -o /go-app

FROM gcr.io/distroless/base-debian11
COPY --from=build /go-app /
ENTRYPOINT ["/go-app"]
