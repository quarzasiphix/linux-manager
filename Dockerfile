FROM python:3.9-slim

WORKDIR /app

# copy & install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# now copy the rest of your code
COPY . .

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"] 