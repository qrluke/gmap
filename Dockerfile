FROM python:3.9.10-slim-buster

RUN adduser sanic -system -group

RUN mkdir sanic
WORKDIR /sanic

USER sanic

COPY requirements.txt .

RUN pip3 install -r requirements.txt

USER root
RUN rm requirements.txt
USER sanic

COPY server.py .

ENV DELAY=250

EXPOSE 40001

ENTRYPOINT python3 server.py $DELAY
