# Define phony targets
.PHONY: help test build up down

# Default target, shows help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help    Show this help message"
	@echo "  test    Run the tests"
	@echo "  build   Build the Docker image"
	@echo "  up      Start the Docker containers"
	@echo "  down    Stop and remove the Docker containers"

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
	@docker build --progress=plain -t amqp_sidecar:latest .

# Start Docker containers
up:
	@echo "Starting Docker containers..."
	@docker-compose up -d

# Stop and remove Docker containers
down:
	@echo "Stopping and removing Docker containers..."
	@docker-compose down