#!/bin/bash
set -x

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
VERSION=${2:-latest}
namespace=kibana
kibana=kibana
export VERSION

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose -p ${namespace} config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose -p ${namespace} config"
else
  echo "[FAILED] docker-compose -p ${namespace} config"
  ret=1
fi
echo "Check kibana installed"
docker-compose -p ${namespace} run --name "test-kibana" --rm $kibana ls -l /opt/
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] kibana installed"
else
  echo "[FAILED] kibana installed"
  ret=1
fi

# test a small nginx config
echo "Check kibana running"

# setup test
echo "# setup env test:"
test_compose=docker-compose.yml
kibana=kibana
test_config=kibana-test.sh
docker-compose -p ${namespace} -f $test_compose up -d --no-build $kibana
docker-compose -p ${namespace} -f $test_compose ps $kibana
container=$(docker-compose -p ${namespace}  -f $test_compose ps -q $kibana)
echo docker cp $test_config ${container}:/opt
docker cp $test_config ${container}:/opt

# run test
echo "# run test:"
docker-compose -p ${namespace}  -f $test_compose exec -T $kibana /bin/bash -c "/opt/$test_config"
test_result=$?

# teardown
echo "# teardown:"
docker-compose -p ${namespace}  -f $test_compose stop
docker-compose -p ${namespace}  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] kibana url check [$test_config]"
else
  echo "[FAILED] kibana url check [$test_config]"
  ret=1
fi

exit $ret
