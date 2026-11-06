from flask import Blueprint, jsonify, request


def _validate_item(data):
    if not isinstance(data, dict):
        return "Request body must be a JSON object"
    if not isinstance(data.get("name"), str) or not data["name"].strip():
        return "name is required and must be a non-empty string"
    if "description" in data and not isinstance(data["description"], str):
        return "description must be a string"
    return None


def item_api(service):
    blueprint = Blueprint("items", __name__)

    @blueprint.get("")
    def list_items():
        return jsonify(service.list())

    @blueprint.post("")
    def create_item():
        data = request.get_json(silent=True)
        error = _validate_item(data)
        if error:
            return jsonify({"error": error}), 400
        return jsonify(service.create(data)), 201

    @blueprint.get("/<item_id>")
    def get_item(item_id):
        item = service.get(item_id)
        return jsonify(item) if item else (jsonify({"error": "Item not found"}), 404)

    @blueprint.put("/<item_id>")
    def update_item(item_id):
        data = request.get_json(silent=True)
        error = _validate_item(data)
        if error:
            return jsonify({"error": error}), 400
        item = service.update(item_id, data)
        return jsonify(item) if item else (jsonify({"error": "Item not found"}), 404)

    @blueprint.delete("/<item_id>")
    def delete_item(item_id):
        if not service.delete(item_id):
            return jsonify({"error": "Item not found"}), 404
        return "", 204

    return blueprint
