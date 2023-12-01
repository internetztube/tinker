#!/bin/bash
# Install
# source /path/to/ecs-ssh.zsh

# AWS ECS ssh
DEFAULT_AWS_REGION="eu-central-1"
DEFAULT_AWS_PROFILE="default"

if [ -z "$AWS_REGION" ]
then
  echo "Note: No AWS_REGION set.  Defaulting to \"$DEFAULT_AWS_REGION\"."
  AWS_REGION=$DEFAULT_AWS_REGION
fi

if [ -z "$AWS_PROFILE" ]
then
    echo "Note: No AWS_PROFILE set. Defaulting to \"$DEFAULT_AWS_PROFILE\"."
    AWS_PROFILE=$DEFAULT_AWS_PROFILE
fi


echo "\nFetching clusters ..."

CLUSTERS=`
  aws ecs list-clusters \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --output json \
    | jq -r ".clusterArns[]"
`
if [ -z "$CLUSTERS" ]
then
  echo ""
  echo "No clusters found! Are you authenticated?"
  return 1
fi

echo "\nWhich cluster?"
select cluster in $CLUSTERS
do

  if [ -z "$cluster" ]
  then
    echo "\nInvalid input."
    return 1
  fi

  echo "\nFetching services ..."
  SERVICES=`
    aws ecs list-services \
      --cluster $cluster \
      --region $AWS_REGION \
      --profile $AWS_PROFILE \
      --output json \
      | jq -r ".serviceArns[]"
  `

  if [ -z "$SERVICES" ]
  then
    echo "No services found.\n"
    return 1
  fi

  echo "\nWhich service?"
  select service in $SERVICES
  do
    if [ -z "$service" ]
    then
      echo "\nInvalid input."
      return 1
    fi

    echo "\nFetching tasks ..."
    TASK_ARNS=`
      aws ecs list-tasks \
        --cluster $cluster \
        --service-name $service \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --output json \
        | jq -r ".taskArns[]"
    `

    if [ -z "$TASK_ARNS" ]
    then
      echo "No tasks found.\n"
      return 1
    fi

    echo "\nWhich task?"
    select taskArn in $TASK_ARNS
    do
      if [ -z "$taskArn" ]
      then
        echo "\nInvalid input."
        return 1
      fi

      echo "\nFetching container ..."
      FIRST_TASK=`
        aws ecs describe-tasks \
          --tasks $taskArn \
          --cluster $cluster \
          --region $AWS_REGION \
          --profile $AWS_PROFILE \
          --output json \
          | jq -r ".tasks[0]"
      `

      if [ -z "$FIRST_TASK" ]
      then
        echo "\nNo tasks with this ARN found. $FIRST_TASK"
        return 1
      fi
      CONTAINER_NAMES=`jq -r ".containers[].name" <<< "$FIRST_TASK"`

      taskDefinitionArn=`jq -r ".taskDefinitionArn" <<< "$FIRST_TASK"`

      taskDefinitionFamily=`
        aws ecs describe-task-definition \
          --task-definition $taskDefinitionArn \
          --region $AWS_REGION \
          --profile $AWS_PROFILE \
          --output json \
          | jq -r ".taskDefinition.family"
      `

      if [ -z "$taskDefinitionFamily" ]
      then
        echo "\nNo task definition family with this ARN found. $taskDefinitionArn"
        return 1
      fi

      if [ -z "$CONTAINER_NAMES" ]
      then
        echo "\nNo containers found. $taskArn"
        return 1
      fi

      echo "\nWhich container?"
      select container in $CONTAINER_NAMES
      do
        if [ -z "$taskArn" ]
        then
          echo "\nInvalid input."
          return 1
        fi

        echo "\n"
        echo "============================================================================================================"
        echo "Connection does not work because of \"The execute command failed because execute command was not enabled when the task was run or the execute command agent isn’t running\"? Run this command:"
        echo "aws ecs update-service --cluster $cluster --task-definition $taskDefinitionFamily --service $service --enable-execute-command --output json --no-cli-pager --region $AWS_REGION --force-new-deployment"
        echo "============================================================================================================"
        echo "Cluster:                $cluster"
        echo "Container:              $container"
        echo "Region:                 $AWS_REGION"
        echo "Task:                   $taskArn"
        echo "Profile:                $AWS_PROFILE"
        echo "Task Definition:        $taskDefinitionArn"
        echo "Task Definition Family: $taskDefinitionFamily"
        echo "============================================================================================================"
        echo "Connecting to Container Instance ..."
        echo ""
        aws ecs execute-command --interactive \
          --command "/bin/sh" \
          --cluster $cluster \
          --container $container \
          --region $AWS_REGION \
          --task $taskArn \
          --profile $AWS_PROFILE
        return
      done
    done
  done
done
