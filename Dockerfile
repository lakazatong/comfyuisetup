FROM python:3.12-slim-bookworm

RUN pip install --root-user-action=ignore pip-tools wheel

RUN apt-get update && apt-get install -y --no-install-recommends \
    git dos2unix \
    build-essential ffmpeg \
    libgl1 libglx-mesa0 libglib2.0-0 \
    fonts-dejavu-core fontconfig \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /requirements.txt
COPY entrypoint.sh /entrypoint.sh
COPY setup.sh /setup.sh

RUN dos2unix /entrypoint.sh
RUN dos2unix /setup.sh
RUN chmod +x /entrypoint.sh /setup.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
