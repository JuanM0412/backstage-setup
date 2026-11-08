from awsgi import response

from app import app


def handler(event, context):
    service_prefix = "/${{ values.name }}"
    path = event.get("path", "")
    if path.startswith(service_prefix):
        event["path"] = path[len(service_prefix) :] or "/"
    return response(app, event, context)
