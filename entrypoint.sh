#!/bin/bash -l

RUN_PATH=$GITHUB_REPOSITORY_ID/$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT

cat <<EOF > /tmp/run.sh
#!/bin/bash -l

$INPUT_SCRIPT
EOF

cat <<EOF > /tmp/config.sh
#!/bin/bash -l

echo "config stage: SCRATCH=\$SCRATCH"
mkdir -p \$SCRATCH/github-actions/run/$RUN_PATH
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
ls -alh /tmp/repo.tar.gz

python3 /usr/local/bin/f7t_submit.py

#chmod +x /tmp/script.sh
#/tmp/script.sh
