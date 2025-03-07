FROM python3:latest

RUN pip install pyfirecrest

COPY entrypoint.sh /entrypoint.sh
COPY f7t_submit.py /usr/local/bin/f7t_submit.py

ENTRYPOINT ["/entrypoint.sh"]
