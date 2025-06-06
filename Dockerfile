# Use NVIDIA's CUDA toolkit image (includes nvcc, headers, libs)
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 1) Install OS‐level build tools and Python dev headers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \        # gcc, g++, make
      git \                    # if you need to clone repos
      ca-certificates \        # for HTTPS downloads
      python3-dev \            # Python C headers
    && rm -rf /var/lib/apt/lists/*

# 2) Set working directory
WORKDIR /app

# 3) Copy only requirements.txt for cached layer
COPY requirements.txt .

# 4) Upgrade pip and install packaging first
RUN pip install --upgrade pip \
 && pip install packaging==23.2

# 5) Install everything in requirements.txt
RUN pip install -r requirements.txt

# 6) Copy the rest of your code (run.sh, configs, dataset, etc.)
COPY . .

# 7) Ensure run.sh is executable
RUN chmod +x run.sh

# 8) When the container launches, run your training wrapper
ENTRYPOINT ["bash", "run.sh"]
