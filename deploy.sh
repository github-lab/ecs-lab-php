#!/bin/bash
#Constants

REGION="cn-north-1"
TG_ARN="arn:aws-cn:elasticloadbalancing:cn-north-1:761602622223:targetgroup/ecslabphp-tg/cda96cf0d98bdcc1"
REPOSITORY_NAME="ecs-lab-php"
CLUSTER="ecs-cluster"
FAMILY=`sed -n 's/.*"family": "\(.*\)",/\1/p' taskdef.json`
FAMILY=${FAMILY:0:10}
NAME=`sed -n 's/.*"name": "\(.*\)",/\1/p' taskdef.json`
NAME=${NAME:0:10}
SERVICE_NAME=${NAME}-service

#Store the repositoryUri as a variable
REPOSITORY_URI=`aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${REGION} | jq .repositories[].repositoryUri | tr -d '"'`


#Replace the build number and respository URI placeholders with the constants above
sed -e "s;%BUILD_NUMBER%;${BUILD_NUMBER};g" -e "s;%REPOSITORY_URI%;${REPOSITORY_URI};g" taskdef.json > ${NAME}-v_${BUILD_NUMBER}.json

#Register the task definition in the repository
aws ecs register-task-definition --family ${FAMILY} --cli-input-json file://${WORKSPACE}/${NAME}-v_${BUILD_NUMBER}.json --region ${REGION}

SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .failures[]`
#Get latest revision
REVISION=`aws ecs describe-task-definition --task-definition ${NAME} --region ${REGION} | jq .taskDefinition.revision`

echo $SERVICE
echo $REVISION


#Create or update service
if [ "$SERVICES" == "" ]; then
  echo "entered existing service"
  DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .services[].desiredCount`
  if [ ${DESIRED_COUNT} = "0" ]; then
    DESIRED_COUNT="1"
  fi
  sed -e "s;%CLUSTER%;${CLUSTER};g" -e "s;%SERVICE_NAME%;${SERVICE_NAME};g" -e "s;%FAMILY%;${FAMILY};g" -e "s;%REVISION%;${REVISION};g" updateservicedef.json > update-${SERVICE_NAME}-v_${BUILD_NUMBER}.json
  aws ecs update-service --cli-input-json file://${WORKSPACE}/update-${SERVICE_NAME}-v_${BUILD_NUMBER}.json --region ${REGION}
else
  echo "entered new service"
  sed -e "s;%CLUSTER%;${CLUSTER};g" -e "s;%SERVICE_NAME%;${SERVICE_NAME};g" -e "s;%TG_ARN%;${TG_ARN};g" -e "s;%FAMILY%;${FAMILY};g" servicedef.json > ${SERVICE_NAME}-v_${BUILD_NUMBER}.json
  aws ecs create-service --cli-input-json file://${WORKSPACE}/${SERVICE_NAME}-v_${BUILD_NUMBER}.json --region ${REGION}
fi