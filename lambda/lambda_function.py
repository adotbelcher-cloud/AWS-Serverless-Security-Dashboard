import os
import uuid
from datetime import datetime, timezone
import json

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

# Defines a helper function to build a standard HTTP response with JSON content.
def build_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }


def lambda_handler(event, context):
    # Extracts the HTTP method and request path provided by API Gateway.
    http_method = event["requestContext"]["http"]["method"]
    path = event.get("rawPath")

    # Parses the JSON request body provided by API Gateway.
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return build_response(400, {
            "message": "Request body must contain valid JSON."
        })
    
    # Validates that the request body is a JSON object (dictionary) rather than an array or other data type.
    if not isinstance(body, dict):
        return build_response(400, {
            "message": "Request body must be a JSON object."
        })


    # Returns all resources currently stored in DynamoDB.
    if http_method == "GET" and path == "/resources":
        response = table.scan()

        return build_response(200, response["Items"])

    # Returns a specific resource from DynamoDB based on the provided resource ID.
    if http_method == "GET" and path.startswith("/resources/"):
        resource_id = event.get("pathParameters", {}).get("id")

        if not resource_id:
            return build_response(400, {
                "message": "Resource ID is required."
                })

        response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in response:
            return build_response(404, {"message": "Resource not found."})

        return build_response(200, response["Item"])

    # Updates an existing resource in DynamoDB based on the provided resource ID and updated fields.
    if http_method == "PATCH" and path.startswith("/resources/"):
        resource_id = event.get("pathParameters", {}).get("id")

        if not resource_id:
            return build_response(400, {"message": "Resource ID is required."})

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
            if field in body:
                updated_fields.append(field)

        if not updated_fields:
            return build_response(400, {"message": "At least one field must be provided for update."})

        # Checks that updated fields contain string values.
        invalid_type_fields = []

        for field in updated_fields:
            if not isinstance(body[field], str):
                invalid_type_fields.append(field)

        if invalid_type_fields:
            return build_response(400, {
                "message": f"Invalid data types for fields: {', '.join(invalid_type_fields)}"
            })

        # Checks that updated fields are not empty or whitespace-only.
        # Notes are excluded so an existing note can intentionally be cleared.
        empty_fields = []

        for field in updated_fields:
            if field != "notes" and body[field].strip() == "":
                empty_fields.append(field)

        if empty_fields:
            return build_response(400, {
                "message": f"Required fields cannot be empty: {', '.join(empty_fields)}"
                })


        # Validates restricted fields only when they are included in the update request.
        if (
            "environment" in updated_fields
            and body["environment"] not in ALLOWED_ENVIRONMENTS
        ):
            return build_response(400, {
                "message": "Invalid environment."
                })

        if (
            "status" in updated_fields
            and body["status"] not in ALLOWED_STATUSES
        ):
            return build_response(400, {
                "message": "Invalid status."
                })

        if (
            "securityReview" in updated_fields
            and body["securityReview"] not in ALLOWED_SECURITY_REVIEWS
        ):
            return build_response(400, {
                "message": "Invalid security review status."
                })

        # Confirms the resource exists before attempting to update it.
        existing_response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in existing_response:
            return build_response(404, {"message": "Resource not found."})

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
            expression_attribute_values[value_placeholder] = body[field]

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

        return build_response(200, response["Attributes"])

    # Deletes an existing resource from DynamoDB based on the provided resource ID.
    if http_method == "DELETE" and path.startswith("/resources/"):
        resource_id = event.get("pathParameters", {}).get("id")

        if not resource_id:
            return build_response(400, {
                "message": "Resource ID is required."
                })

        # Confirms the resource exists before attempting to delete it.
        existing_response = table.get_item(
            Key={
                "id": resource_id
            }
        )

        if "Item" not in existing_response:
            return build_response(404, {
                "message": "Resource not found."
                })

        # Deletes the resource from DynamoDB.
        table.delete_item(
            Key={
                "id": resource_id
            }
        )

        return build_response(200, {
            "message": "Resource deleted successfully."
        })

    # Handles requests that create a new resource.
    if http_method == "POST" and path == "/resources":
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
            if field not in body:
                missing_fields.append(field)

        if missing_fields:
            return build_response(400, {
                "message": f"Missing required fields: {', '.join(missing_fields)}"
                })

        # Checks that provided resource fields contain string values.
        for field in required_fields:
            if not isinstance(body[field], str):
                invalid_type_fields.append(field)

        if "notes" in body and not isinstance(body["notes"], str):
            invalid_type_fields.append("notes")

        if invalid_type_fields:
            return build_response(400, {
                "message": f"Invalid data types for fields: {', '.join(invalid_type_fields)}"
                })

        # Checks that required string fields are not empty or whitespace-only.
        for field in required_fields:
            if body[field].strip() == "":
                empty_fields.append(field)

        if empty_fields:
            return build_response(400, {
                "message": f"Required fields cannot be empty: {', '.join(empty_fields)}"
                })  
            

        # Checks fields that only allow specific values.
        if body["environment"] not in ALLOWED_ENVIRONMENTS:
            return build_response(400, {
                "message": "Invalid environment."
                })

        if body["status"] not in ALLOWED_STATUSES:
            return build_response(400, {
                "message": "Invalid status."    
                })  

        if body["securityReview"] not in ALLOWED_SECURITY_REVIEWS:
            return build_response(400, {
                "message": "Invalid security review status."
                })

        # Generates values controlled by the application rather than the client.
        resource_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()

        # Builds the resource using client-provided and application-generated values.
        item = {
            "id": resource_id,
            "name": body["name"],
            "type": body["type"],
            "environment": body["environment"],
            "owner": body["owner"],
            "status": body["status"],
            "securityReview": body["securityReview"],
            "notes": body.get("notes", ""),
            "createdAt": timestamp,
            "updatedAt": timestamp,
        }

        # Writes the validated resource to DynamoDB.
        table.put_item(Item=item)

        return build_response(201, {
            "message": "Resource created successfully.",
            "id": resource_id
        })

    # Rejects requests that specify an unsupported action.
    return build_response(400, {
        "message": "Invalid action."
    })  