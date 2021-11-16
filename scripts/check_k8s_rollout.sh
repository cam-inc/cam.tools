#!/bin/sh
#
# e.g.)  ./check_k8s_rollout.sh -e env -n local-test-container-service -c test-container -w 120
# e.g.)  ./check_k8s_rollout.sh -e env -n local-test-container-service -c test-container -w 120 -r StatefulSets
#
export LANG=C

_description="podのrolloutの状態を確認するシェルです"

################
usage() {
  cat <<_EOT_
Usage:
Description:
  $_description
Options:
  -e env e.g.) "local"
  -n namespace e.g.) "default"
  -c 対象コンテナ e.g.) "nginx"
  -w 待ち時間 e.g.) "120"
  -r workload resource (optional) | Deployments | ReplicaSet | StatefulSets | DaemonSet | Default is Deployments.
_EOT_
  exit 2
}

[ $# -eq 0 ] && usage
while getopts "he:n:c:w:r:" opt; do
    case $opt in
        e) _env=$OPTARG;;
        n) _namespace=$OPTARG;;
        c) _container=$OPTARG;;
        w) _waittime=$OPTARG;;
        r) _resource=$OPTARG;;
        h) usage;;
    esac
done

[ "x$_env" = "x" ] && echo "[ERROR]: -e option not found." && exit 2
[ "x$_namespace" = "x" ] && echo "[ERROR]: -n option not found." && exit 2
[ "x$_container" = "x" ] && echo "[ERROR]: -c option not found." && exit 2
[ "x$_waittime" = "x" ] && echo "[ERROR]: -w option not found." && exit 2
_resources="Deployments ReplicaSet StatefulSets DaemonSet"
_check_result=1
if [ "x$_resource" = "x" ]; then
  _resource=Deployments
else
  for r in $_resources; do
    [ "x$r" = "x$_resource" ] && _check_result=0
  done
  [ $_check_result = 1 ] && echo "[ERROR]: -r option are $_resources." && exit 2
fi

echo "[INFO]: Description  : $_description"
echo "[INFO]: Infomation:"
echo "[INFO]: env                    : $_env"
echo "[INFO]: namespace              : $_namespace"
echo "[INFO]: container              : $_container"
echo "[INFO]: waittime               : $_waittime"
echo "[INFO]: resource               : $_resource"

echo "[INFO]: ===> Start!!"

start_time=`date +%s`
while true ; do
  kubectl rollout status $_resource \
    --namespace=$_namespace \
    $_container \
    --timeout=1s

  if [ $? -eq 0 ]; then
    kubectl get pods -l app=$_container \
    --namespace=$_namespace
    echo "The deploy has succeeded."
    break
  fi

  end_time=`date +%s`
  duration=`expr $end_time - $start_time`
  echo "Duration = $duration"

  if [ $duration -ge $_waittime ]; then
    echo "The deploy timed out. Check pod"
    exit 1
    break
  else
    kubectl get pods -l app=$_container \
      --namespace=$_namespace
  fi
done;

echo "[INFO]: <==== finish!!!"
