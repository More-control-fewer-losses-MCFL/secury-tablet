FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY pyproject.toml README.md ./
RUN python -c "import subprocess,sys,tomllib; subprocess.check_call([sys.executable,'-m','pip','install',*tomllib.load(open('pyproject.toml','rb'))['project']['dependencies']])" \
    && useradd --create-home --uid 10001 secury
COPY src ./src
RUN pip install --no-deps .
COPY alembic.ini ./
COPY migrations ./migrations
COPY scripts/seed_demo.py ./scripts/seed_demo.py
USER secury
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "armario_tablets.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--root-path", "/api", "--no-access-log"]
