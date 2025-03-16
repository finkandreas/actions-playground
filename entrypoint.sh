#!/bin/bash -l

RUN_PATH=$GITHUB_REPOSITORY_ID/$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT

cat <<EOF > /tmp/run.sh
#!/bin/bash -l

STARTUP_DIR="$\PWD"

# execute user's input script in the github action's run path
cd \$SCRATCH/github-actions/run/$RUN_PATH/workspace
#TODO: Adapt github envvars that point to files/directories in that path
$INPUT_SCRIPT

cd "\$STARTUP_DIR"
rm -f repo.tar.gz
tar -C "\$SCRATCH/github-actions/run/$RUN_PATH" -czf repo.tar.gz .
EOF

cat <<EOF > /tmp/config.sh
#!/bin/bash -l

echo "config stage: SCRATCH=\$SCRATCH"
mkdir -p \$SCRATCH/github-actions/run/$RUN_PATH

tar -xf repo.tar.gz -C \$SCRATCH/github-actions/run/$RUN_PATH
EOF

cat <<EOF > /tmp/cleanup.sh
#!/bin/bash -l
echo "not doing anything in cleanup stage"
EOF

#pwd
#ls -alh
#env
#ls -alh /opt/glr-f7t/client
#cat $GITHUB_EVENT_PATH

env --chdir=/github tar -czf /tmp/repo.tar.gz .

python3 /usr/local/bin/f7t_submit.py

#chmod +x /tmp/script.sh
#/tmp/script.sh
