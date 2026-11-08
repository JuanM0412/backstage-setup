import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from app import create_app

API_PATH = "/api/v1/${{ values.apiPath }}"


def test_item_lifecycle():
    client = create_app().test_client()

    created = client.post(
        API_PATH,
        json={"name": "Example", "description": "Initial description"},
    )
    assert created.status_code == 201
    item_id = created.json["id"]

    assert client.get(API_PATH).status_code == 200
    assert client.get(f"{API_PATH}/{item_id}").status_code == 200
    updated = client.put(f"{API_PATH}/{item_id}", json={"name": "Updated"})
    assert updated.status_code == 200
    assert updated.json["name"] == "Updated"
    assert client.delete(f"{API_PATH}/{item_id}").status_code == 204
    assert client.get(f"{API_PATH}/{item_id}").status_code == 404


def test_item_requires_name():
    response = create_app().test_client().post(
        API_PATH, json={"description": "Invalid"}
    )
    assert response.status_code == 400


def test_service_health():
    response = create_app().test_client().get("/health")
    assert response.status_code == 200
    assert response.json == {"status": "ok"}