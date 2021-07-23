QUEUE_FILE=jobs.queue
LOG_FILE=jobs.log

JOB_NAME=""
SCRIPT_PATH=""

BACKOFF_SECS=20
touch $QUEUE_FILE
touch $LOG_FILE
exec {QUEUE_FD}<>$QUEUE_FILE
exec {LOG_FD}<>$LOG_FILE


trap 'rm -f "$QUEUE_FILE"' EXIT

# I used flock command to guarantee concurrent enqueue-dequeue
dequeue () {
  JOB_NAME=$(head -n 1 $QUEUE_FILE | awk '{print $1}')
  SCRIPT_PATH=$(head -n 1 $QUEUE_FILE | awk '{print $2}')
  echo "dequeue $JOB_NAME"

  flock -x $QUEUE_FD
  tail -n +2 $QUEUE_FILE > tmp
  cat tmp > $QUEUE_FILE
  flock -u $QUEUE_FD

  rm tmp

  flock -x $LOG_FD
  echo "$(date)| Job $JOB_NAME is dequeued" >> $LOG_FILE
  flock -u $LOG_FD
}

run_job() {
  echo "run $SCRIPT_PATH"
  $SCRIPT_PATH
  flock -x $LOG_FD
  echo "$(date)| Job $JOB_NAME is finished" >> $LOG_FILE
  flock -u $LOG_FD
}

while true
do
  if [ $(wc -l $QUEUE_FILE | awk '{print $1}') -eq 0 ]
  then
    echo "No job is currently scheduled. Backoff $BACKOFF_SECS s"
    sleep $BACKOFF_SECS
  else
    dequeue
    run_job
  fi
done
