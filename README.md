# 🚀 AMQP Sidecar

![Elixir](https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

**AMQP Sidecar** is a lightweight, configurable Elixir application designed to act as a sidecar for consuming and publishing messages via AMQP (e.g., RabbitMQ). It integrates seamlessly with Kubernetes and supports dynamic configuration for exchanges, queues, and routing keys.

---

## 🌟 Features

- **📥 Consume Messages**: Dynamically subscribe to AMQP exchanges and queues based on configuration.
- **📤 Publish Messages**: Publish messages to AMQP exchanges with optional headers.
- **⚙️ Configurable**: Define exchanges, queues, routing keys, and endpoints in a `broker.json` file.
- **🐳 Kubernetes-Friendly**: Designed to run as a sidecar in Kubernetes with configuration mounted as a ConfigMap.
- **🚀 HTTP API**: Expose an HTTP API for publishing messages and health checks.
- **🧩 Extensible**: Easily extendable to support custom message processing and forwarding logic.

---

## 🛠️ Installation

### Prerequisites

- **Elixir** (1.12 or later)
- **RabbitMQ** (3.8 or later)
- **Kubernetes** (optional, for running as a sidecar)

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/alesima/amqp_sidecar.git
   cd amqp_sidecar
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Configure the application:
   - Update the `broker.json` file with your AMQP and endpoint configurations.
   - Example:
     ```json
     {
       "rules": [
         {
           "exchange": "test_exchange",
           "exchangeType": "topic",
           "queue": "test_queue",
           "routingKeys": ["test.*"],
           "endpointUri": "http://test-endpoint"
         }
       ]
     }
     ```

4. Run the application:
   ```bash
   mix run --no-halt
   ```

---

## 🚦 Usage

### Consuming Messages

The sidecar automatically consumes messages from the configured exchanges and queues. Messages are forwarded to the specified `endpointUri`.

### Publishing Messages

Use the HTTP API to publish messages:

```bash
curl -X POST http://localhost:4000/publish \
  -H "Content-Type: application/json" \
  -d '{
    "exchange": "test_exchange",
    "routingKey": "test.key",
    "message": "Hello, world!",
    "headers": {
      "x-delay": 5000
    }
  }'
```

### Health Check

Check the health of the sidecar:

```bash
curl -X POST http://localhost:4000/health
```

---

## 🐳 Running in Kubernetes

1. Build the Docker image:
   ```bash
   docker build -t amqp_sidecar:latest .
   ```

2. Deploy to Kubernetes:
   - Create a ConfigMap for `broker.json`:
     ```yaml
     apiVersion: v1
     kind: ConfigMap
     metadata:
       name: amqp-sidecar-config
     data:
       broker.json: |
         {
           "rules": [
             {
               "exchange": "test_exchange",
               "exchangeType": "topic",
               "queue": "test_queue",
               "routingKeys": ["test.*"],
               "endpointUri": "http://test-endpoint"
             }
           ]
         }
     ```
   - Deploy the sidecar:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: amqp-sidecar
     spec:
       replicas: 1
       template:
         spec:
           containers:
             - name: amqp-sidecar
               image: amqp_sidecar:latest
               volumeMounts:
                 - name: config-volume
                   mountPath: /app/config
           volumes:
             - name: config-volume
               configMap:
                 name: amqp-sidecar-config
     ```

---

## 🧪 Testing

Run the test suite:

```bash
mix test
```

---

## 📂 Project Structure

```
amqp_sidecar/
├── config/               # Configuration files
├── lib/                  # Application code
│   ├── amqp_sidecar/     # Core modules
│   ├── web/              # HTTP API and routes
├── test/                 # Tests
├── Dockerfile            # Dockerfile for containerization
├── mix.exs               # Project dependencies
└── README.md             # This file
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

---

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Elixir** for being an awesome language.
- **RabbitMQ** for reliable message queuing.
- **Kubernetes** for making sidecar patterns easy.

---

Made with ❤️ by [Alex Silva](https://github.com/alesima)
