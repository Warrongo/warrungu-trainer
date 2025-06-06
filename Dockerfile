FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# Install system dependencies + pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \    # gcc, g++, make
      git \                # for cloning repos (if needed)
      ca-certificates \    # HTTPS certs
      python3-dev \        # Python C headers
      python3-pip &&       # brings in pip3
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Upgrade pip & lock packaging
RUN pip3 install --upgrade pip packaging==23.2

# Install Python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Copy app code
COPY . .

# Make the entrypoint executable
RUN chmod +x run.sh

ENTRYPOINT ["bash", "run.sh"]
