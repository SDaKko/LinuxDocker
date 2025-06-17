# Этап сборки и тестирования
FROM python:3.10-alpine as builder

# Устанавливаем зависимости для сборки
RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    python3-dev

# Создаем и активируем виртуальное окружение
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Копируем зависимости отдельно для кэширования
COPY pyproject.toml .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -e .[test]

# Копируем остальной код
COPY . .

# Запускаем тесты
RUN pytest tests/

# Финальный образ
FROM python:3.10-alpine

# Устанавливаем только runtime зависимости
RUN apk add --no-cache libpq

# Копируем виртуальное окружение из builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем только необходимый код (без тестов)
WORKDIR /app
COPY --from=builder /app/src ./src

# Оптимизация Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1

# Порт приложения
EXPOSE 8041

# Команда запуска (без --reload для production)
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8041"]
