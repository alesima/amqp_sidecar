# Define phony targets
.PHONY: help test build run

# Default target, shows help
help:
    @echo "Usage: make [target]"
    @echo ""
    @echo "Targets:"
    @echo "  help    Show this help message"
    @echo "  test    Run the tests"
    @echo "  build   Build the Docker image"
    @echo "  run     Run the Docker container"

# Run tests
test:
    @echo "Running tests..."
    @mix local.hex --force
    @mix local.rebar --force
    @mix deps.get
    @mix test

# Build Docker image
build:
    @echo "Building Docker image..."
    @docker build -t amqp_sidecar:latest .

# Run Docker container
run:
    @echo "Running Docker container..."
    @docker run -p 4000:4000 amqp_sidecar:latest