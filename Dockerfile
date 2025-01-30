# Use an official Elixir runtime as a parent image
FROM elixir:1.13-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base

# Set working directory
WORKDIR /app

# Copy the source code into the container
COPY . .

# Get dependencies
RUN mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get

# Compile the project
RUN mix compile

# Build a release
RUN MIX_ENV=prod mix release

# Start a new stage from a smaller image for the final image
FROM alpine:3.14 AS app

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++

# Set working directory
WORKDIR /app

# Copy the release from the previous stage
COPY --from=build /app/_build/prod/rel/amqp_sidecar ./

# Expose the port the app runs on
EXPOSE 4000

# Set the default command to run when starting the container
CMD ["bin/amqp_sidecar", "start"]