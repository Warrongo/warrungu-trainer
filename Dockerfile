# Use a Python base image
FROM python:3.10-slim

# (Optional) If you need system dependencies for bitsandbytes, xformers, etc., install them here:
# RUN apt-get update && \
#     apt-get install -y build-essential git curl && \
#     rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only requirements.txt first (for caching)
COPY requirements.txt .

# Upgrade pip and install all Python dependencies
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy the rest of your repository into the image
COPY . .

# Ensure run.sh is executable
RUN chmod +x run.sh

# Expose no ports (we aren’t serving a web app)
# If you were serving a web app, you might do: EXPOSE 7860

# When the container starts, run your run.sh script
ENTRYPOINT ["bash", "run.sh"]
