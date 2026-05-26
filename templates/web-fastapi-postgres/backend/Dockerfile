FROM python:3.11-slim

WORKDIR /app

# context: ./backend — rutas relativas a backend/
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
