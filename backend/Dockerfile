FROM python:3.8-alpine

WORKDIR /app
COPY Pipfile* /app/
RUN pip install pipenv \
    && pipenv lock -r > requirements.txt \
    && pip install -r requirements.txt \
    && pipenv --rm \
    && pip uninstall pipenv -y
COPY . /app

CMD gunicorn -w 3 -b :5000 app:app
