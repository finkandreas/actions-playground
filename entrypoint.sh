#!/bin/bash -l

cat <<EOF > /tmp/script.sh
#!/bin/bash -l

set -x

$INPUT_SCRIPT
EOF

echo "input_script="
cat /tmp/script.sh
echo "---- end of input_script -----"

chmod +x /tmp/script.sh
/tmp/script.sh
