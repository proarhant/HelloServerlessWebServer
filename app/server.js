const { createServer } = require('http');
const port = process.env.PORT ?? 8080;

createServer(function (req, res) {
  // The server listens on port 8080
  // As of this release, we only handle GET /hello requests on the exposed port 8080
  if (req.method === 'GET' && req.url === '/hello') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.write('OK');
    res.end();
  } else {
    // We return 404 for other routes
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.write('Sorry, that page cannot be served at this moment. Please check the URL and try again.');
    res.end();
  }
}).listen(port);

console.log(`Server listening at localhost:${port}`); 