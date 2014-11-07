#!/bin/bash
#
# Get some settings from /root/.marsrc
if [ -e  /root/.marsrc ]; then
    .  /root/.marsrc
else
    echo "Missing defines "
    exit 1
fi
# Set time-stamp for log file
ts=$(date '+%Y%m%d_%H%M')
# Get host IP
localIP=$(facter ipaddress)

cd $VL_CHANNEL_ROOT/brlm/$VL_PROCESS_ID
# install mars tree
tar xvzf mars.tgz

sed -i -e "/marsVersion/  s/SNAPSHOT-mars/${BUILD_NUMBER}/" gradle.properties
. gradle.properties
echo "mars version = $marsVersion"
echo "time-stamp = $ts"

GRADLE_ARGS="--quiet"

runflyway() {
  FLYWAY_ARGS="-Pflyway.initOnMigrate=true -Pflyway.url=jdbc:mysql://localhost:3306/${DB} -Pflyway.user=$flyway_user -Pflyway.password=$flyway_password"
  LOG_ARGS="-Pflyway.initOnMigrate=true -Pflyway.url=jdbc:mysql://localhost:3306/${DB}"
  GRADLE_CMD="./gradlew ${GRADLE_ARGS} ${FLYWAY_ARGS}"
  LOG_CMD="./gradlew ${GRADLE_ARGS} ${LOG_ARGS}"
  echo ${LOG_CMD} flywayRepair  flywayMigrate flywayInfo 2>&1 | /usr/bin/tee $LOG_FILE
  ${GRADLE_CMD} flywayRepair flywayMigrate flywayInfo 2>&1 | /usr/bin/tee $LOG_FILE
  ret=$?
  echo Exit status for $DB is $ret
}


# run flywaydb command
pushd common
  LOG_FILE=/home/ec2-user/marsdb_${marsVersion}_${ts}.log
  DB=mars
  runflyway
popd

if [ $ret != 0 ] ; then
  exit $ret
fi

pushd pin
  LOG_FILE=/home/ec2-user/pindb_${marsVersion}_${ts}.log
  DB=pin
  runflyway
popd

if [ $ret != 0 ] ; then
  exit $ret
fi
exit $ret
