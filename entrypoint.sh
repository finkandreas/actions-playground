#!/bin/bash -l

set -e

RUN_PATH=$GITHUB_REPOSITORY_ID/$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT

cat <<EOF > /tmp/run.sh
#!/bin/bash -l

set -e

STARTUP_DIR="\$PWD"
echo "STARTUP_DIR=\$STARTUP_DIR"

for var_name in GITHUB_STEP_SUMMARY GITHUB_STATE GITHUB_ENV GITHUB_PATH GITHUB_OUTPUT GITHUB_WORKSPACE HOME GITHUB_EVENT_PATH ; do
    # warp GITHUB_* variables to the changed path of the workspace
    export \$var_name=\${!var_name/#"/github"/"\$SCRATCH/github-actions/run/$RUN_PATH"}
done

# execute user's input script in the github action's run path
cd \$SCRATCH/github-actions/run/$RUN_PATH/workspace
#TODO: Adapt github envvars that point to files/directories in that path

# run user's input script in a separate shell, to avoid side-effects of any user commands to this shell
( set -e ; $INPUT_SCRIPT )

if [[ "${INPUT_STAGE_FROM_COMPUTE_NODE}" == "true" ]] ; then
    cd "\$STARTUP_DIR"
    rm -f repo.tar.gz
    tar -C "\$SCRATCH/github-actions/run/$RUN_PATH" -czf repo.tar.gz .
fi
EOF

cat <<EOF > /tmp/config.sh
#!/bin/bash -l

echo "config stage: SCRATCH=\$SCRATCH"
mkdir -p \$SCRATCH/github-actions/run/$RUN_PATH

if [[ "${INPUT_STAGE_TO_COMPUTE_NODE}" == "true" ]] ; then
    tar -xf repo.tar.gz -C \$SCRATCH/github-actions/run/$RUN_PATH
else
    mkdir -p \$SCRATCH/github-actions/run/$RUN_PATH/workspace
fi
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
if [[ "${INPUT_STAGE_TO_COMPUTE_NODE}" == "true" ]] ; then
    echo "Staging /github directory and will send it to the compute node"
    tar -czf /tmp/repo.tar.gz -C /github .
fi

# start job on compute node and run user script
python3 /usr/local/bin/f7t_submit.py

# extract workspace that was sent back from compute node
if [[ "${INPUT_STAGE_FROM_COMPUTE_NODE}" == "true" ]] ; then
    echo "Stage back /github directory from compute node"
    cd /tmp
    tar -xzf /tmp/repo.tar.gz --no-overwrite-dir -C /github
    cd /github
    chown --reference=/github/workspace --recursive /github/*
fi
