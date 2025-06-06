# Use NVIDIA's CUDA toolkit image (includes nvcc, headers, libs)
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# Install OS‐level build tools and Python dev headers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \      # gcc, g++, make
      git \                  # if you need to clone repos
      ca-certificates \      # for HTTPS downloads
      python3-dev &&         # Python C headers
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only requirements.txt for caching
COPY requirements.txt .

# Upgrade pip and pin packaging
RUN pip install --upgrade pip && \
    pip install packaging==23.2

# Install Python deps
RUN pip install -r requirements.txt

# Copy rest of the app
COPY . .

# Make run.sh executable
RUN chmod +x run.sh

# Launch training
ENTRYPOINT ["bash", "run.sh"]
