# Base image with CUDA 12.0 + cuDNN + Python 3.10
FROM nvidia/cuda:12.0.0-cudnn8-devel-ubuntu22.04

# ── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    OMP_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    CUDA_LAUNCH_BLOCKING=0 \
    USER=root

WORKDIR /workspace

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3-pip \
        git \
        wget \
        curl \
        ffmpeg \
        libsndfile1 \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Make python3.10 the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python python python /usr/bin/python3.10 1

# ── Python dependencies ───────────────────────────────────────────────────────
COPY requirements.txt requirements_nodeps.txt ./

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements_nodeps.txt --no-deps

# ── (Optional) Flash Attention – comment out if not needed ────────────────────
# Install the wheel that matches Python 3.10 + CUDA 12.0 + PyTorch 2.6
RUN pip install --no-cache-dir \
    https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl \
    || echo "Flash Attention installation skipped (optional)"

# ── Application code ──────────────────────────────────────────────────────────
COPY . /workspace/

# ── PYTHONPATH expected by generate.sh and run.sh ────────────────────────────
ENV PYTHONPATH="/workspace/codeclm/tokenizer/:/workspace:/workspace/codeclm/tokenizer/Flow1dVAE/:/workspace/codeclm/tokenizer/"
ENV TRANSFORMERS_CACHE="/workspace/third_party/hub"

# ── Default: start the Gradio Web UI ─────────────────────────────────────────
# Pass the checkpoint directory as the first argument, e.g.:
#   docker run ... songgeneration:local songgeneration_v2_large
EXPOSE 8081
ENTRYPOINT ["bash", "tools/gradio/run.sh"]
CMD ["songgeneration_v2_large"]
