const { randomUUID } = require('node:crypto');

module.exports = repository => ({
  list() {
    return repository.list();
  },

  get(id) {
    return repository.findById(id) || null;
  },

  create(input) {
    const now = new Date().toISOString();
    const item = {
      id: randomUUID(),
      name: input.name.trim(),
      description: input.description?.trim() || '',
      createdAt: now,
      updatedAt: now,
    };
    return repository.save(item);
  },

  update(id, input) {
    const current = repository.findById(id);
    if (!current) return null;

    const item = {
      ...current,
      name: input.name.trim(),
      description: input.description?.trim() || '',
      updatedAt: new Date().toISOString(),
    };
    return repository.save(item);
  },

  delete(id) {
    return repository.remove(id);
  },
});
