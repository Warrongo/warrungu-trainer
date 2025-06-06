FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# Install system build tools, git, pip, etc.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        python3-dev \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Upgrade pip & lock packaging
RUN pip3 install --upgrade pip packaging==23.2

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Copy your code and make the entrypoint executable
COPY . .
RUN chmod +x run.sh

ENTRYPOINT ["bash", "run.sh"]
