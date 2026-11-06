import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from app import create_app


def test_item_lifecycle():
    client = create_app().test_client()

    created = client.post(
        "/api/v1/items",
        json={"name": "Example", "description": "Initial description"},
    )
    assert created.status_code == 201
    item_id = created.json["id"]

    assert client.get("/api/v1/items").status_code == 200
    assert client.get(f"/api/v1/items/{item_id}").status_code == 200
    updated = client.put(f"/api/v1/items/{item_id}", json={"name": "Updated"})
    assert updated.status_code == 200
    assert updated.json["name"] == "Updated"
    assert client.delete(f"/api/v1/items/{item_id}").status_code == 204
    assert client.get(f"/api/v1/items/{item_id}").status_code == 404


def test_item_requires_name():
    response = create_app().test_client().post(
        "/api/v1/items", json={"description": "Invalid"}
    )
    assert response.status_code == 400