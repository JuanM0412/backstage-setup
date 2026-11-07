const app = require('./app');

module.exports.handler = async (event, context) => {
  const serverless = require('serverless-http');
  const servicePrefix = '/${{ values.name }}';
  const path = event.path || event.requestContext?.path;
  if (path?.startsWith(servicePrefix)) {
    event = {
      ...event,
      path: path.slice(servicePrefix.length) || '/',
      resource: event.resource?.replace(servicePrefix, '') || event.resource,
    };
  }
  return serverless(app)(event, context);
};
