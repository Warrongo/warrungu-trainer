# Stage 1: CUDA + build tools
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      ca-certificates \
      python3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# install pip and packaging
RUN python3 -m ensurepip --upgrade && \
    python3 -m pip install --upgrade pip packaging==23.2

# Copy & install Python deps
COPY requirements.txt .
RUN python3 -m pip install -r requirements.txt

# Copy code & make entrypoint
COPY . .
RUN chmod +x run.sh

ENTRYPOINT ["bash", "run.sh"]
