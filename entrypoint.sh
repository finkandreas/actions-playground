#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l
set -x
$INPUT_SCRIPT
EOF
chmod +x /tmp/script.sh
/tmp/script.sh |& tee -a $GITHUB_OUTPUT
