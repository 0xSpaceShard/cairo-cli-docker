FROM rust:1.67-alpine AS compiler-builder

ARG CAIRO_COMPILER_TARGET_TAG
ARG SCARB_VERSION

RUN apk add git musl-dev curl

# Install scarb
# doesn't work with /bin/sh and bash is not available by default
ARG SHELL=/bin/ash
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | $SHELL -s -- -v $SCARB_VERSION

# Install cairo1 compiler
RUN git clone -b $CAIRO_COMPILER_TARGET_TAG https://github.com/starkware-libs/cairo.git

RUN cargo build --release --manifest-path /cairo/crates/cairo-lang-starknet/Cargo.toml
RUN cargo build --release --manifest-path /cairo/crates/cairo-lang-sierra-to-casm/Cargo.toml

# Install cairo-lang
FROM python:3.9.13-alpine3.16 as cairo-lang

COPY requirements.txt .

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION
ARG OZ_VERSION

RUN pip wheel --no-cache-dir --no-deps\
    --wheel-dir /wheels\
    -r requirements.txt\
    cairo-lang==$CAIRO_VERSION openzeppelin-cairo-contracts==$OZ_VERSION

# Final image
FROM python:3.9.13-alpine3.16

ARG SCARB_VERSION

RUN apk add --no-cache libgmpxx

COPY --from=cairo-lang /wheels /wheels

COPY --from=compiler-builder /cairo/corelib /usr/local/bin/corelib
COPY --from=compiler-builder /cairo/target/release/starknet-sierra-compile /usr/local/bin/target/release/starknet-sierra-compile
COPY --from=compiler-builder /cairo/target/release/starknet-compile /usr/local/bin/target/release/starknet-compile
COPY --from=compiler-builder /root/.local/share/scarb-install/${SCARB_VERSION}/bin/scarb /usr/local/bin/scarb

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
