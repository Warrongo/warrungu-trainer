# 1) CUDA base image with toolkit & compilers
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 2) Install Python, pip, build tools, git, certs
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

# 3) Make sure pip is the default python installer
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# 4) Set working directory
WORKDIR /app

# 5) Copy requirements & install
COPY requirements.txt .
RUN pip install --upgrade pip packaging==23.2 && \
    pip install -r requirements.txt

# 6) Copy your code
COPY . .

# 7) Make your entrypoint script executable
RUN chmod +x run.sh

# 8) Pass your HF token into the container at runtime
ARG HF_HUB_TOKEN
ENV HF_HUB_TOKEN=${HF_HUB_TOKEN}

# 9) Launch training
ENTRYPOINT ["bash", "run.sh"]
