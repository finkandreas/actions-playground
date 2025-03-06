#!/bin/sh -l

echo "#!/bin/sh -l" > /tmp/script.sh
echo "$1" >> /tmp/script.sh
chmod +x /tmp/script.sh
/tmp/script.sh |& tee -a $GITHUB_OUTPUT

#echo "Hello $1"
#time=$(date)
#echo "time=$time" >> $GITHUB_OUTPUT
