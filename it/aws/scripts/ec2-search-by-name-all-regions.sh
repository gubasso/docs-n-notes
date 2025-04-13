#!/bin/bash

PROFILE="$1"
SEARCH_TERM="$2"

if [[ -z "$PROFILE" || -z "$SEARCH_TERM" ]]; then
  echo "Usage: $0 <AWS_PROFILE> <SEARCH_TERM>"
  exit 1
fi

REGIONS=$(aws ec2 describe-regions \
  --profile "$PROFILE" \
  --query "Regions[].RegionName" \
  --output text)

for REGION in $REGIONS; do
  echo "Searching in region: $REGION"

  aws ec2 describe-instances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=*$SEARCH_TERM*" \
    --query "Reservations[].Instances[].{ \
               InstanceID: InstanceId, \
               Name: Tags[?Key=='Name']|[0].Value, \
               State: State.Name, \
               Type: InstanceType \
             }" \
    --output table \
    --no-cli-pager
done
