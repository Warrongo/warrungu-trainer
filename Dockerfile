# start from CUDA so Triton/Deepspeed just works
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# install python3, pip, build tools & wget(for your run.sh)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-dev \
      python3-distutils \
      python3-pip \
      build-essential \
      git \
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# make python3 the default "python"
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

WORKDIR /app

# copy & install requirements
COPY requirements.txt .
RUN python -m pip install --upgrade pip packaging==23.2 && \
    python -m pip install -r requirements.txt

# copy all your code + config + dataset
COPY . .

# make your launcher executable
RUN chmod +x run.sh

# build-arg for secret, and expose as both old & new env-vars
ARG HF_HUB_TOKEN
ENV HF_HUB_TOKEN=${HF_HUB_TOKEN}
ENV HUGGINGFACE_HUB_TOKEN=${HF_HUB_TOKEN}

ENTRYPOINT ["bash", "run.sh"]
