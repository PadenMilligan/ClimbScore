# Production image. Railway builds this automatically and tells the app which port to use through $PORT.
FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Shared libraries that OpenCV and MediaPipe load when they are imported.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 libsm6 libxext6 libxrender1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependencies first, so code changes don't reinstall them.
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY climb_analyzer/ ./climb_analyzer/

# Run as an unprivileged user that can write only to the data folder.
RUN useradd --create-home --uid 10001 app \
    && mkdir -p /app/climb_analyzer/data \
    && chown app:app /app/climb_analyzer/data
USER app

WORKDIR /app/climb_analyzer
EXPOSE 8080

# Settings are in climb_analyzer/gunicorn.conf.py.
CMD ["gunicorn", "app:app"]
