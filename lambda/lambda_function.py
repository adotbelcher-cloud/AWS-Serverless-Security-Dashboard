import os
import uuid
from datetime import datetime, timezone

import boto3


# Connects to the DynamoDB table provided by Terraform through an environment variable.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])


def lambda_handler(event, context):
    # Defines the fields that must be provided when creating a resource.
    required_fields = [
        "name",
        "type",
        "environment",
        "owner",
        "status",
        "securityReview",
    ]

    # Checks that all required fields are present in the request.
    missing_fields = []

    for field in required_fields:
        if field not in event:
            missing_fields.append(field)

    if missing_fields:
        return {
            "statusCode": 400,
            "body": f"Missing required fields: {', '.join(missing_fields)}",
        }

    # Generates values controlled by the application rather than the client.
    resource_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    # Builds the resource using client-provided and application-generated values.
    item = {
        "id": resource_id,
        "name": event["name"],
        "type": event["type"],
        "environment": event["environment"],
        "owner": event["owner"],
        "status": event["status"],
        "securityReview": event["securityReview"],
        "notes": event.get("notes", ""),
        "createdAt": timestamp,
        "updatedAt": timestamp,
    }

    # Writes the validated resource to DynamoDB.
    table.put_item(Item=item)

    return {
        "statusCode": 201,
        "body": f"Resource created successfully with ID: {resource_id}",
    }