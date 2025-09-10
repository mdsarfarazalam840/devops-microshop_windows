const express = require('express');
const client = require('prom-client');

const app = express();
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics(); // default metrics

const httpRequestDurationMs = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method','route','code'],
  buckets: [50, 100, 200, 300, 500, 1000]
});

app.use((req, res, next) => {
  const end = httpRequestDurationMs.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.path, code: res.statusCode });
  });
  next();
});

app.get('/', (req, res) => res.send('Hello from DevOps microservice!'));
app.get('/health', (req, res) => res.json({status:'ok'}));

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`App listening on ${port}`));
