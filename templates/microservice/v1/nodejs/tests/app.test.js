const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const app = require('../src/app');
const apiPath = '/api/v1/${{ values.apiPath }}';

test('creates, reads, updates, lists, and deletes an item', async () => {
  const created = await request(app)
    .post(`${apiPath}`)
    .send({ name: 'Example', description: 'Initial description' })
    .expect(201);

  assert.equal(created.body.name, 'Example');
  const id = created.body.id;

  await request(app).get(apiPath).expect(200).expect(response => {
    assert.equal(response.body.length, 1);
  });
  await request(app)  .get(`${apiPath}/${id}`).expect(200);
  await request(app)
    .put(`${apiPath}/${id}`)
    .send({ name: 'Updated' })
    .expect(200)
    .expect(response => assert.equal(response.body.name, 'Updated'));
  await request(app).delete(`${apiPath}/${id}`).expect(204);
  await request(app).get(`${apiPath}/${id}`).expect(404);
});

test('rejects an item without a name', async () => {
  await request(app).post(apiPath).send({ description: 'Invalid' }).expect(400);
});

test('reports service health', async () => {
  await request(app).get('/health').expect(200).expect({ status: 'ok' });
});