# Build stage
FROM elixir:1.17-otp-27-alpine AS builder

RUN apk add --no-cache build-base git

WORKDIR /app

ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application code
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile app
COPY config/runtime.exs config/
RUN mix compile

# Build release
RUN mix release

# Runtime stage
FROM alpine:3.19 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
USER app

COPY --from=builder --chown=app:app /app/_build/prod/rel/credit_app ./

ENV PHX_SERVER=true

EXPOSE 4000

CMD ["bin/credit_app", "start"]
