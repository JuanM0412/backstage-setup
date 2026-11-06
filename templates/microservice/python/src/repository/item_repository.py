class ItemRepository:
    def __init__(self):
        self._items = {}

    def list(self):
        return list(self._items.values())

    def find_by_id(self, item_id):
        return self._items.get(item_id)

    def save(self, item):
        self._items[item["id"]] = item
        return item

    def remove(self, item_id):
        return self._items.pop(item_id, None) is not None
