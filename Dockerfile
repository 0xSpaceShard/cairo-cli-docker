FROM python:3.9.13-alpine3.16 as builder

COPY requirements.txt .

RUN apk add gmp-dev g++ gcc

ARG CAIRO_VERSION

RUN pip wheel --no-cache-dir --no-deps\
    --wheel-dir /wheels\
    -r requirements.txt\
    cairo-lang==$CAIRO_VERSION openzeppelin-cairo-contracts==0.4.0b

FROM python:3.9.13-alpine3.16

RUN apk add --no-cache libgmpxx

COPY --from=builder /wheels /wheels

RUN pip install --no-cache /wheels/*

RUN rm -rf /wheels
