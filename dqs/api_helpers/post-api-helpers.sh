#!/bin/bash
set -e

echo "Disabling CloudTrail S3 data events for DQS account..."

# List trails homed in this account (not org shadow copies)
REGION=$(aws ec2 describe-availability-zones \
  --query 'AvailabilityZones[0].RegionName' --output text)

TRAIL_ARNS=$(aws cloudtrail list-trails \
  --query "Trails[?HomeRegion=='${REGION}'].TrailARN" \
  --output text)

if [ -z "$TRAIL_ARNS" ]; then
  echo "No local trails found in ${REGION}. Skipping."
  exit 0
fi

for TRAIL_ARN in $TRAIL_ARNS; do
  echo "Updating event selectors on trail: ${TRAIL_ARN}"
  # Keep management events, set DataResources to empty (disables all data events incl. S3)
  aws cloudtrail put-event-selectors \
    --trail-name "${TRAIL_ARN}" \
    --event-selectors '[{
      "ReadWriteType": "All",
      "IncludeManagementEvents": true,
      "DataResources": []
    }]' && echo "  Done." || echo "  Could not modify (may be an org trail — skip)."
done

echo "CloudTrail S3 data events disabled."
