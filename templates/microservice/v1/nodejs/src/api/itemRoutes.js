const express = require('express');

function validateItem(body) {
  if (!body || typeof body.name !== 'string' || body.name.trim() === '') {
    return 'name is required and must be a non-empty string';
  }
  if (body.description !== undefined && typeof body.description !== 'string') {
    return 'description must be a string';
  }
  return null;
}

module.exports = service => {
  const router = express.Router();

  router.get('/', (_request, response) => response.json(service.list()));

  router.post('/', (request, response) => {
    const validationError = validateItem(request.body);
    if (validationError) return response.status(400).json({ error: validationError });
    return response.status(201).json(service.create(request.body));
  });

  router.get('/:id', (request, response) => {
    const item = service.get(request.params.id);
    return item ? response.json(item) : response.status(404).json({ error: 'Item not found' });
  });

  router.put('/:id', (request, response) => {
    const validationError = validateItem(request.body);
    if (validationError) return response.status(400).json({ error: validationError });
    const item = service.update(request.params.id, request.body);
    return item ? response.json(item) : response.status(404).json({ error: 'Item not found' });
  });

  router.delete('/:id', (request, response) => {
    if (!service.delete(request.params.id)) {
      return response.status(404).json({ error: 'Item not found' });
    }
    return response.status(204).send();
  });

  return router;
};
