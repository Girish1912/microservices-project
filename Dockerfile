# Copyright 2020 Google LLC
# Licensed under the Apache License, Version 2.0

FROM python:3.11-slim AS base

FROM base AS builder

# Install required packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# Download the gRPC health probe
ENV GRPC_HEALTH_PROBE_VERSION=v0.4.18

RUN wget -qO /bin/grpc_health_probe \
    https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 \
    && chmod +x /bin/grpc_health_probe

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS without-grpc-health-probe-bin

ENV PYTHONUNBUFFERED=1
ENV ENABLE_PROFILER=1

WORKDIR /email_server

# Copy Python 3.11 packages from the builder
COPY --from=builder /usr/local/lib/python3.11/ /usr/local/lib/python3.11/

# Add the application
COPY . .

EXPOSE 8080

ENTRYPOINT ["python", "email_server.py"]

FROM without-grpc-health-probe-bin

COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
