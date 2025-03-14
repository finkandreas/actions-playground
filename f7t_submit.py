import firecrest as fc
import os
import subprocess

client_id = os.environ.get("INPUT_FIRECREST-CLIENT-ID", "")
client_secret = os.environ.get("INPUT_FIRECREST-CLIENT-SECRET", "")
if client_id == "" or client_secret == "":
    print("The client-id or client-secret is empty. Please provide the firecrest credentials")
    exit(1)

url = os.environ['INPUT_FIRECREST-URL']
auth_url = os.environ['INPUT_FIRECREST-TOKEN-URL']

machine = os.environ['INPUT_FIRECREST-SYSTEM']

allocation_name = f'ci-gha-{os.environ["GITHUB_RUN_ID"]}'
glr_addr = 'cicd-ext-mw.cscs.ch'

client_exec = ['/opt/glr-f7t/client', f'--addr={glr_addr}', f'--path=glr_f7t/wss/glr', f'--job-id={allocation_name}']

jobscript_tmpl = f'''#!/bin/bash -l
{{{{ SBATCH_LINES }}}}
#SBATCH --job-name={allocation_name}


[[ ! -v SCRATCH ]] && echo "SCRATCH variable is not set, this is an error" && exit 1
ARCH=$(uname -m)
HELPERS_DIR="$SCRATCH/github-actions/bin/$ARCH"
mkdir -p "$HELPERS_DIR"
export PATH=$HELPERS_DIR:$PATH

for bin in glr_client skopeo empty ; do
    if ! file "$HELPERS_DIR/$bin" | grep -q "ELF 64-bit" ; then
        echo "The file $HELPERS_DIR/$bin does not seem to be a binary. Force re-download"
        rm "$HELPERS_DIR/$bin"
    fi
    curl -z "$HELPERS_DIR/$bin" -o "$HELPERS_DIR/$bin" https://{glr_addr}/glr_f7t/assets/$ARCH/$bin
    chmod +x "$HELPERS_DIR/$bin"
done

mkdir -p $SCRATCH/github-actions/logs

if [[ -v http_proxy ]] ; then
    PROXIES=( "http_proxy=$http_proxy" "https_proxy=$https_proxy" "no_proxy=$no_proxy" )
fi

# exec, so signals at SLURM timeout are sent to glr_client (env is exec-ing too)
exec env -i SCRATCH=$SCRATCH \\
       LD_LIBRARY_PATH=$LD_LIBRARY_PATH \\
       HOME=$HOME \\
       "${{PROXIES[@]}}" \\
       PATH=$PATH \\
       SLURM_JOB_ID=$SLURM_JOB_ID \\
       glr_client --addr {glr_addr} --path /glr_f7t/wss/cn --job-id {allocation_name} --logfile $SCRATCH/github-actions/logs/{os.environ["GITHUB_RUN_ID"]}.log
'''

slurm_opts = {
        #'SLURM_ACCOUNT': '--account',
        'SLURM_ACCTG_FREQ': '--acctg-freq',
        'SLURM_CLUSTERS': '--clusters',
        'SLURM_CONSTRAINT': '--constraint',
        'SRUN_CONTAINER': '--container',
        'SURN_CONTAINER_ID': '--container-id',
        'SLURM_CORE_SPEC': '--core-spec',
        'SLURM_CPUS_PER_GPU': '--cpus-per-gpu',
        'SLURM_CPUS_PER_TASK': '--cpus-per-task',
        'SLURM_DELAY_BOOT': '--delay-boot',
        'SLURM_DISTRIBUTION': '--distribution',
        'SRUN_ERROR': '--error',
        'SLURM_EXCLUSIVE': '--exclusive',
        'SLURM_EXPORT_ENV': '--export',
        'SLURM_GPU_BIND': '--gpu-bind',
        'SLURM_GPU_FREQ': '--gpu-freq',
        'SLURM_GPUS': '--gpus',
        'SLURM_GPUS_PER_NODE': '--gpus-per-node',
        'SLURM_GPUS_PER_TASK': '--gpus-per-task',
        'SLURM_GRES': '--gres',
        'SLURM_GRES_FLAGS': '--gres-flags',
        'SLURM_HINT': '--hint',
        'SRUN_INPUT': '--input',
        'SLURM_JOB_NAME': '--job-name',
        'SLURM_JOB_NUM_NODES': '--nodes',
        'SLURM_NNODES': '--nodes',
        'SLURM_NTASKS': '--ntasks',
        'SLURM_MEM_BIND': '--mem-bind',
        'SLURM_MEM_PER_CPU': '--mem-per-cpu',
        'SLURM_MEM_PER_GPU': '--mem-per-gpu',
        'SLURM_MEM_PER_NODE': '--mem',
        'SLURM_NETWORK': '--network',
        'SLURM_NO_KILL': '--no-kill',
        'SLURM_OPEN_MODE': '--open-mode',
        'SRUN_OUTPUT': '--output',
        'SLURM_PARTITION': '--partition',
        'SLURM_POWER': '--power',
        'SLURM_PROFILE': '--profile',
        'SLURM_QOS': '--qos',
        'SLURM_REQ_SWITCH': '--switches',
        'SLURM_RESERVATION': '--reservation',
        'SLURM_SIGNAL': '--signal',
        'SLURM_THREAD_SPEC': '--thread-spec',
        'SLURM_THREADS_PER_CORE': '--threads-per-core',
        'SLURM_TIMELIMIT': '--time',
        'SLURM_WAIT4SWITCH': '--switches',
        'SLURM_WCKEY': '--wckey',
}
slurm_opts_no_args = {
        'SLURM_DEBUG': '-vv',
        'SLURM_OVERCOMMIT': '--overcommit',
        'SLURM_SPREAD_JOB': '--spread-job',
        'SLURM_USE_MIN_NODES': '--use-min-nodes',
}

sbatch_lines = [f'#SBATCH {v}={os.environ[k]}' for k,v in slurm_opts.items() if k in os.environ and os.environ[k] != ""]
# if value is an empty string, pass the option without a value
sbatch_lines += [f'#SBATCH {v}' for k,v in slurm_opts.items() if k in os.environ and os.environ[k] == ""]
# add SBATCH options that are not allowed to have any value
sbatch_lines += [f'#SBATCH {v}' for k,v in slurm_opts_no_args.items() if k in os.environ]
slurm_account = os.environ.get('SLURM_ACCOUNT', '')
if slurm_account:
    sbatch_lines.append(f'#SBATCH --account={slurm_account}')
elif 'SLURM_ACCOUNT' not in os.environ:
    raise RuntimeError("No account has been specified. You can set a default account on the CI setup page, or override with the variable SLURM_ACCOUNT")
jobscript = jobscript_tmpl.replace("{{ SBATCH_LINES }}", '\n'.join(sbatch_lines))

client_proc_env = {'SYSTEM_FAILURE_EXIT_CODE': '1', 'BUILD_FAILURE_EXIT_CODE': '2', **{f'CUSTOM_ENV_'+k:v for k,v in os.environ.items()}}
worker_proc = subprocess.Popen(client_exec + ['--stage=config', '--exec', '/tmp/config.sh'], env=client_proc_env)

client =  fc.v1.Firecrest(firecrest_url=url, authorization=fc.ClientCredentialsAuth(client_id, client_secret, auth_url, min_token_validity=60))
jobSubmit = client.submit(machine, script_str=jobscript)
print(f"Submitted job successfully to SLURM queue. Waiting for job to start. jobid={jobSubmit['jobid']} directory={os.path.dirname(jobSubmit['job_file'])}", flush=True)

retcode = worker_proc.wait()
assert retcode == 0, f'Failed running config stage, retcode={retcode}'

worker_proc = subprocess.Popen(client_exec + ['--stage=run', '--exec', '/tmp/run.sh'], env=client_proc_env)
retcode = worker_proc.wait()
assert retcode == 0, f'Failed running run stage, retcode={retcode}'

worker_proc = subprocess.Popen(client_exec + ['--stage=cleanup', '--exec', '/tmp/cleanup.sh', '--disconnect-cn'], env=client_proc_env)
retcode = worker_proc.wait()
assert retcode == 0, f'Failed running cleanup stage, retcode={retcode}'
