FROM rust:1.67-alpine AS builder

# Install cairo1 compiler
RUN apk add git musl-dev && \
    git clone https://github.com/starkware-libs/cairo.git

RUN cargo build --release --manifest-path /cairo/crates/cairo-lang-starknet/Cargo.toml
RUN cargo build --release --manifest-path /cairo/crates/cairo-lang-sierra-to-casm/Cargo.toml

# Install cairo-lang
FROM python:3.9.13-alpine3.16 as stage

COPY requirements.txt .

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION

ARG OZ_VERSION

RUN pip wheel --no-cache-dir --no-deps\
    --wheel-dir /wheels\
    -r requirements.txt\
    cairo-lang==$CAIRO_VERSION openzeppelin-cairo-contracts==$OZ_VERSION

FROM python:3.9.13-alpine3.16

RUN apk add --no-cache libgmpxx

COPY --from=stage /wheels /wheels
COPY --from=builder /cairo/corelib /usr/local/bin/corelib
COPY --from=builder /cairo/target/release/starknet-sierra-compile /usr/local/bin/target/release/starknet-sierra-compile
COPY --from=builder /cairo/target/release/starknet-compile /usr/local/bin/target/release/starknet-cairo1-compile

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
