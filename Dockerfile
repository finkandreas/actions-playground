FROM finkandreas/f7t-gha:latest

COPY entrypoint.sh /entrypoint.sh
COPY f7t_submit.py /usr/local/bin/f7t_submit.py

ENTRYPOINT ["/entrypoint.sh"]
