#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l

$INPUT_SCRIPT
EOF

pwd
ls -alh

chmod +x /tmp/script.sh
/tmp/script.sh


