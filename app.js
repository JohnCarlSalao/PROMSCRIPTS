const express = require('express');
const { collectDefaultMetrics, register, Histogram, Gauge } = require('prom-client');

const app = express();
const PORT = 4000;

// Collect default metrics (CPU, memory, etc.)
collectDefaultMetrics();

// Custom metrics
const httpRequestDurationMicroseconds = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status'],
});

const activeRequestsGauge = new Gauge({
    name: 'active_requests',
    help: 'Number of active HTTP requests',
});

// Middleware to track request duration and active requests
app.use((req, res, next) => {
    const end = httpRequestDurationMicroseconds.startTimer();
    activeRequestsGauge.inc();

    res.on('finish', () => {
        end({ method: req.method, route: req.path, status: res.statusCode });
        activeRequestsGauge.dec();
    });

    next();
});

// Sample route
app.get('/', (req, res) => {
    res.send('Hello, world!');
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', register.contentType);
    res.end(await register.metrics());
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
