#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l

ls -alh $SCRATCH/
$INPUT_SCRIPT
EOF

pwd
ls -alh
env
which client

python3 /usr/local/bin/f7t_submit.py

#chmod +x /tmp/script.sh
#/tmp/script.sh
