# Stage 1: Build
FROM elixir:1.17.3-otp-25-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Copy mix.exs and mix.lock to cache dependencies
COPY mix.exs mix.lock ./

# Fetch and compile dependencies
RUN mix deps.get --only prod && \
  mix deps.compile

# Copy the rest of the application code
COPY . .

# Compile the application
RUN mix compile

# Build the release
RUN MIX_ENV=prod mix release

# Stage 2: Runtime
FROM alpine:3 AS app

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++ bash

# Set working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/amqp_sidecar ./

# Expose the port the app runs on
EXPOSE 4000

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=4000

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget -qO- http://localhost:4000/health || exit 1

# Set the default command to run when starting the container
CMD ["bin/amqp_sidecar", "start"]