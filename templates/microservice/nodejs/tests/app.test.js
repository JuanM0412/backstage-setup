const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const app = require('../src/app');

test('creates, reads, updates, lists, and deletes an item', async () => {
  const created = await request(app)
    .post('/api/v1/items')
    .send({ name: 'Example', description: 'Initial description' })
    .expect(201);

  assert.equal(created.body.name, 'Example');
  const id = created.body.id;

  await request(app).get('/api/v1/items').expect(200).expect(response => {
    assert.equal(response.body.length, 1);
  });
  await request(app).get(`/api/v1/items/${id}`).expect(200);
  await request(app)
    .put(`/api/v1/items/${id}`)
    .send({ name: 'Updated' })
    .expect(200)
    .expect(response => assert.equal(response.body.name, 'Updated'));
  await request(app).delete(`/api/v1/items/${id}`).expect(204);
  await request(app).get(`/api/v1/items/${id}`).expect(404);
});

test('rejects an item without a name', async () => {
  await request(app).post('/api/v1/items').send({ description: 'Invalid' }).expect(400);
});