# Dockerfile
# Use NVIDIA CUDA base (includes toolkit & compilers)
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 1) Install Python3, pip, curl & build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-dev \
        python3-distutils \
        python3-pip \
        curl \
        build-essential \
        git \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 2) Make python3 the default `python`
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# 3) Set working directory
WORKDIR /app

# 4) Copy & install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip packaging==23.2 && \
    pip install -r requirements.txt

# 5) Copy your training code, configs, and run script
COPY . .

# 6) Ensure your launcher is executable
RUN chmod +x run.sh

# 7) Pass HF token into container at build & runtime
ARG HF_HUB_TOKEN
ENV HF_HUB_TOKEN=${HF_HUB_TOKEN}

# 8) Kick off your training script
ENTRYPOINT ["bash", "run.sh"]
