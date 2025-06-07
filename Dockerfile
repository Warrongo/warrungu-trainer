# Dockerfile
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 1) Install Python3, pip & build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-dev \
      python3-distutils \
      python3-pip \
      build-essential \
      git \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 2) Make python3 the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

WORKDIR /app

# 3) Copy & install requirements
COPY requirements.txt .
RUN pip install --upgrade pip packaging==23.2 && \
    pip install -r requirements.txt

# 4) Copy your training code + config
COPY . .

# 5) Make your launcher executable
RUN chmod +x run.sh

# 6) Build‐time arg & run‐time env var for HF token:
ARG HF_HUB_TOKEN
ENV HF_HUB_TOKEN=${HF_HUB_TOKEN}

ENTRYPOINT ["bash", "run.sh"]

