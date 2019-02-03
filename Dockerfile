FROM python:3-slim
RUN pip install --upgrade pip
ADD requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt
ADD ./app /home/app/
WORKDIR /home/app/
ENTRYPOINT ["python3", "app.py"]
