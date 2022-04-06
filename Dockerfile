FROM python:3.7.12-alpine3.15 as builder

COPY requirements.txt .

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION

RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt cairo-lang==$CAIRO_VERSION


FROM python:3.7.12-alpine3.15

COPY --from=builder /wheels /wheels

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
