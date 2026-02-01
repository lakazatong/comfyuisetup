FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    git dos2unix \
    libgl1 libglx-mesa0 libglib2.0-0 \
    fonts-dejavu-core fontconfig \
    build-essential \
    && pip install pip-tools \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.sh /requirements.sh
COPY setup.sh /setup.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
