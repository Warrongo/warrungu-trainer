# 1) Start from CUDA + dev toolchain
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 2) Install system build tools + pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \        # gcc, g++, make
      git \                    # repo cloning if needed
      ca-certificates \        # for HTTPS downloads
      python3-dev \            # headers for any C extensions
      python3-pip &&           # brings in pip
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3) Upgrade pip & lock packaging early
RUN pip3 install --upgrade pip packaging==23.2

# 4) Copy & install Python requirements
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# 5) Copy your code
COPY . .

# 6) Make your entrypoint executable
RUN chmod +x run.sh

# 7) Launch via your training wrapper
ENTRYPOINT ["bash", "run.sh"]
