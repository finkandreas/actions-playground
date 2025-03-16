#!/bin/bash -l

RUN_PATH=$GITHUB_REPOSITORY_ID/$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT

cat <<EOF > /tmp/run.sh
#!/bin/bash -l

set -e

STARTUP_DIR="\$PWD"
echo "STARTUP_DIR=\$STARTUP_DIR"

# execute user's input script in the github action's run path
cd \$SCRATCH/github-actions/run/$RUN_PATH/workspace
#TODO: Adapt github envvars that point to files/directories in that path
$INPUT_SCRIPT

set +x
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

# pack workspace to send to compute node
tar -czf /tmp/repo.tar.gz -C /github .
ls -alh /tmp/repo.tar.gz

# start job on compute node and run user script
python3 /usr/local/bin/f7t_submit.py

# extract workspace that was sent back from compute node
ls -alh /tmp/repo.tar.gz
tar -vxzf /tmp/repo.tar.gz -C /github
