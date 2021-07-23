QUEUE_FILE=jobs.queue
LOG_FILE=jobs.log

JOB_NAME=$1
SCRIPT_PATH=$2

touch $QUEUE_FILE
touch $LOG_FILE
exec {QUEUE_FD}<>$QUEUE_FILE
exec {LOG_FD}<>$LOG_FILE

flock -x $QUEUE_FD
echo "$JOB_NAME $SCRIPT_PATH" >> $QUEUE_FILE
flock -u $QUEUE_FD

flock -x $LOG_FD
echo "$(date)| Job $JOB_NAME is enqueued" >> $LOG_FILE
flock -u $LOG_FD
