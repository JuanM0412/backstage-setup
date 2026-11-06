const items = new Map();

function list() {
  return Array.from(items.values());
}

function findById(id) {
  return items.get(id);
}

function save(item) {
  items.set(item.id, item);
  return item;
}

function remove(id) {
  return items.delete(id);
}

function clear() {
  items.clear();
}

module.exports = { list, findById, save, remove, clear };
