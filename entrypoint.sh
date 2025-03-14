#!/bin/bash -l

cat <<EOF > /tmp/run.sh
#!/bin/bash -l

$INPUT_SCRIPT
EOF

cat <<EOF > /tmp/config.sh
#!/bin/bash -l
echo "not doing anything in config stage"
EOF

cat <<EOF > /tmp/cleanup.sh
#!/bin/bash -l
echo "not doing anything in cleanup stage"
EOF

#pwd
#ls -alh
#env
#ls -alh /opt/glr-f7t/client

python3 /usr/local/bin/f7t_submit.py

#chmod +x /tmp/script.sh
#/tmp/script.sh
