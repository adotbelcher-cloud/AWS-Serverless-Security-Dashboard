import os
import uuid
from datetime import datetime, timezone

import boto3


# Connects to the DynamoDB table provided by Terraform through an environment variable.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

# Defines the supported values used when validating resource data.
ALLOWED_ENVIRONMENTS = [
    "development",
    "staging",
    "production",
]

ALLOWED_STATUSES = [
    "active",
    "inactive",
    "decommissioned",
]

ALLOWED_SECURITY_REVIEWS = [
    "pending",
    "in-progress",
    "complete",
]


def lambda_handler(event, context):
    # Determines which operation the Lambda function should perform.
    action = event.get("action", "create")

    # Returns all resources currently stored in DynamoDB.
    if action == "list":
        response = table.scan()

        return {
            "statusCode": 200,
            "body": response["Items"],
        }

    # Returns a specific resource from DynamoDB based on the provided resource ID.
    if action == "get":
        resource_id = event.get("id")

        if not resource_id:
            return {
                "statusCode": 400,
                "body": "Resource ID is required.",
            }

        response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in response:
            return {
                "statusCode": 404,
                "body": "Resource not found.",
            }

        return {
            "statusCode": 200,
            "body": response["Item"],
        }

    # Updates an existing resource in DynamoDB based on the provided resource ID and updated fields.
    if action == "update":
        resource_id = event.get("id")

        if not resource_id:
            return {
                "statusCode": 400,
                "body": "Resource ID is required.",
            }

        allowed_update_fields = [
            "name",
            "type",
            "environment",
            "owner",
            "status",
            "securityReview",
            "notes",
        ]

        # Identifies which allowed fields were included in the update request.
        updated_fields = []

        for field in allowed_update_fields:
            if field in event:
                updated_fields.append(field)

        if not updated_fields:
            return {
                "statusCode": 400,
                "body": "At least one field must be provided for update.",
            }

        # Checks that updated fields contain string values.
        invalid_type_fields = []

        for field in updated_fields:
            if not isinstance(event[field], str):
                invalid_type_fields.append(field)

        if invalid_type_fields:
            return {
                "statusCode": 400,
                "body": f"Invalid data types for fields: {', '.join(invalid_type_fields)}",
            }

        # Checks that updated fields are not empty or whitespace-only.
        # Notes are excluded so an existing note can intentionally be cleared.
        empty_fields = []

        for field in updated_fields:
            if field != "notes" and event[field].strip() == "":
                empty_fields.append(field)

        if empty_fields:
            return {
                "statusCode": 400,
                "body": f"Updated fields cannot be empty: {', '.join(empty_fields)}",
            }


        # Validates restricted fields only when they are included in the update request.
        if (
            "environment" in updated_fields
            and event["environment"] not in ALLOWED_ENVIRONMENTS
        ):
            return {
                "statusCode": 400,
                "body": "Invalid environment.",
            }

        if (
            "status" in updated_fields
            and event["status"] not in ALLOWED_STATUSES
        ):
            return {
                "statusCode": 400,
                "body": "Invalid status.",
            }

        if (
            "securityReview" in updated_fields
            and event["securityReview"] not in ALLOWED_SECURITY_REVIEWS
        ):
            return {
                "statusCode": 400,
                "body": "Invalid security review status.",
            }

        # Confirms the resource exists before attempting to update it.
        existing_response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in existing_response:
            return {
                "statusCode": 404,
                "body": "Resource not found.",
            }

        # Builds the DynamoDB update expression from the fields included in the request.
        update_expressions = []
        expression_attribute_names = {}
        expression_attribute_values = {}

        for index, field in enumerate(updated_fields):
            name_placeholder = f"#field{index}"
            value_placeholder = f":value{index}"

            update_expressions.append(
                f"{name_placeholder} = {value_placeholder}"
            )

            expression_attribute_names[name_placeholder] = field
            expression_attribute_values[value_placeholder] = event[field]

        # Updates the timestamp whenever the resource is modified.
        timestamp = datetime.now(timezone.utc).isoformat()

        update_expressions.append("#updatedAt = :updatedAt")
        expression_attribute_names["#updatedAt"] = "updatedAt"
        expression_attribute_values[":updatedAt"] = timestamp

        # Updates the resource in DynamoDB and returns the modified item.
        response = table.update_item(
            Key={
                "id": resource_id
            },
            UpdateExpression="SET " + ", ".join(update_expressions),
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW",
        )

        return {
            "statusCode": 200,
            "body": response["Attributes"],
        }

    # Deletes an existing resource from DynamoDB based on the provided resource ID.
    if action == "delete":
        resource_id = event.get("id")

        if not resource_id:
            return {
                "statusCode": 400,
                "body": "Resource ID is required.",
            }

        # Confirms the resource exists before attempting to delete it.
        existing_response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in existing_response:
            return {
                "statusCode": 404,
                "body": "Resource not found.",
            }

        # Deletes the resource from DynamoDB.
        table.delete_item(
            Key={
                "id": resource_id
            }
        )

        return {
            "statusCode": 200,
            "body": "Resource deleted successfully.",
        }

    # Handles requests that create a new resource.
    if action == "create":
        # Defines the fields that must be provided when creating a resource.
        required_fields = [
            "name",
            "type",
            "environment",
            "owner",
            "status",
            "securityReview",
        ]

        # Tracks validation problems found in the request.
        missing_fields = []
        empty_fields = []
        invalid_type_fields = []

        # Checks that all required fields are present in the request.
        for field in required_fields:
            if field not in event:
                missing_fields.append(field)

        if missing_fields:
            return {
                "statusCode": 400,
                "body": f"Missing required fields: {', '.join(missing_fields)}",
            }

        # Checks that provided resource fields contain string values.
        for field in required_fields:
            if not isinstance(event[field], str):
                invalid_type_fields.append(field)

        if "notes" in event and not isinstance(event["notes"], str):
            invalid_type_fields.append("notes")

        if invalid_type_fields:
            return {
                "statusCode": 400,
                "body": f"Invalid data types for fields: {', '.join(invalid_type_fields)}",
            }

        # Checks that required string fields are not empty or whitespace-only.
        for field in required_fields:
            if event[field].strip() == "":
                empty_fields.append(field)

        if empty_fields:
            return {
                "statusCode": 400,
                "body": f"Required fields cannot be empty: {', '.join(empty_fields)}",
            }

        # Checks fields that only allow specific values.
        if event["environment"] not in ALLOWED_ENVIRONMENTS:
            return {
                "statusCode": 400,
                "body": "Invalid environment.",
            }

        if event["status"] not in ALLOWED_STATUSES:
            return {
                "statusCode": 400,
                "body": "Invalid status.",
            }

        if event["securityReview"] not in ALLOWED_SECURITY_REVIEWS:
            return {
                "statusCode": 400,
                "body": "Invalid security review status.",
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

    # Rejects requests that specify an unsupported action.
    return {
        "statusCode": 400,
        "body": "Invalid action.",
    }