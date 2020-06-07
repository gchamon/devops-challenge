FROM python:3.8-alpine

COPY . /app
WORKDIR /app
RUN pip install pipenv \
    && pipenv lock -r > requirements.txt \
    && pip install -r requirements.txt \
    && pipenv --rm \
    && pip uninstall pipenv -y

CMD gunicorn -w 3 -b :5000 app:app
