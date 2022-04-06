FROM python:3.7.12-alpine3.15 as builder

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels ecdsa fastecdsa sympy cairo-lang==$CAIRO_VERSION


FROM python:3.7.12-alpine3.15

RUN apk add --no-cache libgmpxx g++ gcc

COPY --from=builder /wheels /wheels

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
