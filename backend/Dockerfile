FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/opt/hf-cache

WORKDIR /code

# 1. PyTorch
RUN pip install --no-cache-dir \
    torch==2.15.0 torchvision==0.29.2 \
    --index-url https://download.pytorch.org/whl/cpu

# 2. app dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. bake the clip weights into the image
RUN python -c "import open_clip; open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')" \
    && chmod -R a+rX /opt/hf-cache

# dont try to download at runtime
ENV HF_HUB_OFFLINE=1

# 4. code
COPY app ./app

RUN useradd --create-home appuser
USER appuser

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]