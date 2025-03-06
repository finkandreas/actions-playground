#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l

$INPUT_SCRIPT
EOF

pwd
ls -alh
ls -alh --recursive /github

chmod +x /tmp/script.sh
/tmp/script.sh


