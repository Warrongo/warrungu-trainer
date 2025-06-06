# Use NVIDIA's CUDA toolkit image (includes nvcc, headers, libs)
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# Install system build tools and Python C headers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      ca-certificates \
      python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only requirements.txt to leverage Docker layer caching
COPY requirements.txt .

# Upgrade pip and pin packaging
RUN pip install --upgrade pip && \
    pip install packaging==23.2

# Install Python dependencies
RUN pip install -r requirements.txt

# Copy the rest of the application
COPY . .

# Ensure the training script is executable
RUN chmod +x run.sh

# When the container starts, kick off the training
ENTRYPOINT ["bash", "run.sh"]
