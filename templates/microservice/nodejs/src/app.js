const express = require('express');

const itemRepository = require('./repository/itemRepository');
const itemService = require('./services/itemService');
const createItemRouter = require('./api/itemRoutes');

const app = express();
const service = itemService(itemRepository);

app.use(express.json());
app.use('/api/v1/items', createItemRouter(service));
app.use((error, _request, response, _next) => {
  if (error instanceof SyntaxError && error.status === 400 && error.body) {
    return response.status(400).json({ error: 'Request body must be valid JSON' });
  }

  console.error(error);
  return response.status(500).json({ error: 'Internal server error' });
});

if (require.main === module) {
  const port = Number(process.env.PORT || 8080);
  app.listen(port, () => {
    console.log(`API listening on port ${port}`);
  });
}

module.exports = app;