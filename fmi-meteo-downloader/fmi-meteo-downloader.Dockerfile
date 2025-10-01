# syntax=docker/dockerfile:1
FROM python:3.11.1

RUN pip3 install python-dateutil requests

COPY src /project/src/

WORKDIR /project

CMD ["python3", "-u", "/project/src/main.py"]
