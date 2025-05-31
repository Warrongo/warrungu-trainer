# Use a lightweight Python base
FROM python:3.10-slim

# 1) Set working directory
WORKDIR /app

# 2) Copy only requirements.txt for cached layer
COPY requirements.txt .

# 3) Upgrade pip and install packaging first so mamba-ssm can import it during build
RUN pip install --upgrade pip \
    && pip install packaging==23.2

# 4) Now install everything in requirements.txt (including mamba-ssm)
RUN pip install -r requirements.txt

# 5) Copy the rest of your code (run.sh, axolotl_config.yml, dataset, etc.)
COPY . .

# 6) Make sure run.sh is executable
RUN chmod +x run.sh

# 7) When the container launches, run your training wrapper
ENTRYPOINT ["bash", "run.sh"]
