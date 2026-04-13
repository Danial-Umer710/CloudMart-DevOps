FROM python:3.9-slim

# Install system dependencies for mysql
RUN apt-get update && apt-get install -y default-libmysqlclient-dev build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .
# Force Python to flush logs immediately
ENV PYTHONUNBUFFERED=1

CMD ["python", "app.py"]
