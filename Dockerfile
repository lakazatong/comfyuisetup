FROM python:3.12-slim-bookworm

# pip 26 has issues as of 07 Feb 2026
# See https://github.com/scikit-learn/scikit-learn/issues/33174
RUN pip install --root-user-action=ignore --upgrade pip \
    && pip install --root-user-action=ignore uv

RUN pip install --root-user-action=ignore uv

RUN apt-get update && apt-get install -y --no-install-recommends \
    git dos2unix \
    build-essential ffmpeg \
    libgl1 libglx-mesa0 libglib2.0-0 \
    fonts-dejavu-core fontconfig \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY setup.sh /setup.sh

RUN dos2unix /entrypoint.sh
RUN dos2unix /setup.sh

RUN chmod +x /entrypoint.sh /setup.sh

EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
