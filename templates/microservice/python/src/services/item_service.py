from datetime import datetime, timezone
from uuid import uuid4


def _now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


class ItemService:
    def __init__(self, repository):
        self.repository = repository

    def list(self):
        return self.repository.list()

    def get(self, item_id):
        return self.repository.find_by_id(item_id)

    def create(self, data):
        now = _now()
        return self.repository.save(
            {
                "id": str(uuid4()),
                "name": data["name"].strip(),
                "description": data.get("description", "").strip(),
                "createdAt": now,
                "updatedAt": now,
            }
        )

    def update(self, item_id, data):
        current = self.repository.find_by_id(item_id)
        if current is None:
            return None
        item = {
            **current,
            "name": data["name"].strip(),
            "description": data.get("description", "").strip(),
            "updatedAt": _now(),
        }
        return self.repository.save(item)

    def delete(self, item_id):
        return self.repository.remove(item_id)
