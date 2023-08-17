FROM debian:11-slim AS build
ARG POETRY_VERSION=1.5.1

# hadolint ignore=SC1072
RUN apt-get update && \
  apt-get install --no-install-suggests --no-install-recommends --yes python3 python3-pip gcc libpython3-dev git && \  
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  pip install "poetry==${POETRY_VERSION}"

# Copy just the pyproject.toml and poetry.lock files to install dependencies
COPY pyproject.toml poetry.lock /

# Set up the virtualenv
RUN poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true

# Clone the repo and add it as a dependency
RUN --mount=type=secret,id=GIT_TOKEN git clone https://$(cat /run/secrets/GIT_TOKEN):x-oauth-basic@github.com/EreminAnton/test_app_for_docker_python_poetry.git 
RUN poetry add file:/test_app_for_docker_python_poetry


# Install other project dependencies
RUN poetry install

# Copy the rest of the project over and build the app
FROM gcr.io/distroless/python3-debian11 AS runtime
COPY --from=build /.venv /.venv
WORKDIR /app
COPY ./app ./app
EXPOSE 80

ENTRYPOINT ["/.venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
