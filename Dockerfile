FROM golang:1.22-alpine AS builder

WORKDIR /build

ENV CGO_ENABLED=0

COPY . .

RUN go mod tidy \
  && go build

FROM alpine:3.19

ARG COMMIT_DATE
ARG COMMIT
ARG VERSION
ARG TREE_STATE

LABEL maintainer="janfuhrer"

RUN addgroup -S app \
    && adduser -S -G app app

WORKDIR /home/app

COPY --from=builder /build/podsalsa .
COPY ./ui ./ui
RUN chown -R app:app ./

USER app

CMD ["./podsalsa"]
