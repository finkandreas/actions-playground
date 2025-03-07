#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l

$INPUT_SCRIPT
EOF

pwd
ls -alh
env

python3 /usr/local/bin/f7t_submit.py

#chmod +x /tmp/script.sh
#/tmp/script.sh
