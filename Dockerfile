# ubuntu LTS version
FROM ubuntu:22.04 AS builder-image

# avoid stuck build due to user prompt
ARG DEBIAN_FRONTEND=noninteractive
ARG VENV_PATH=/home/iasyc/venv

RUN apt update && apt install --no-install-recommends -y python3.10 python3.10-dev python3.10-venv python3-pip python3-wheel build-essential && \
    apt clean && rm -rf /var/lib/apt/lists/*

# create and activate virtual environment
# using final folder name to avoid path issues with packages
RUN python3.10 -m venv /home/iasyc/venv
ENV PATH="$VENV_PATH/bin:$PATH"

# install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir wheel
RUN pip install --no-cache-dir -r requirements.txt

# runner image
FROM ubuntu:22.04 AS runner-image

# Arguments and environment variables for the runner image
ARG VENV_PATH=/home/iasyc/venv
ARG WORK_DIR=/home/iasyc/extraccion_pdf
ENV PATH="$VENV_PATH/bin:$PATH"

# Install runtime dependencies
RUN apt update && apt install --no-install-recommends -y python3.10 python3.10-venv && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Create a group and user, set permissions so that the root group has access
RUN groupadd -g 1000 iasyc && useradd -m -u 1000 -g iasyc iasyc
# Copy the virtual environment over from the builder stage
COPY --from=builder-image --chown=1000:0 $VENV_PATH $VENV_PATH

RUN mkdir -p $WORK_DIR && \
    chown -R 1000:0 $WORK_DIR && chmod -R g=u $WORK_DIR $VENV_PATH


# Switch to the non-root user
USER 1000

# Set the working directory
WORKDIR $WORK_DIR

# Copy the application files to the container with correct ownership
COPY --chown=1000:0 . .

# Navigate to the directory containing the API
WORKDIR "$WORK_DIR/api"

# launch api
CMD ["/home/iasyc/venv/bin/uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--log-config", "./logging.conf"]
