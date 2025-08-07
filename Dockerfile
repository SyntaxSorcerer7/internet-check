FROM python:3.12-alpine

WORKDIR /app

# Zeitzone auf UTC setzen für konsistente Zeitstempel
ENV TZ=UTC
RUN apk add --no-cache tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Flask & Requests schlank installieren
RUN pip install --no-cache-dir flask requests

# Dateien kopieren
COPY monitor.py .
COPY templates/ templates/

# ─────────────────────────  Laufzeit  ────────────────────────────────
EXPOSE 8000
CMD ["python", "monitor.py"]
