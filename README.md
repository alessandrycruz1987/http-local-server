# @cappitolian/http-local-server

A Capacitor plugin to run a local HTTP server on your device, allowing you to receive and respond to HTTP requests directly from Angular/JavaScript.

---

## Features

- Embed a real HTTP server (NanoHTTPD on Android, GCDWebServer on iOS).
- Receive requests via events and send responses back from the JS layer.
- CORS support enabled by default for local communication.
- Tested with **Capacitor 7** and **Ionic 8**.

---

## Installation

```bash
npm install @cappitolian/local-ip
npx cap sync
```

---

## Usage

### Import

```typescript
import { HttpLocalServer } from '@cappitolian/http-local-server';
```

### Listen and Respond

```typescript
// 1. Set up the listener for incoming requests
HttpLocalServer.addListener('onRequest', async (request) => {
  console.log('Request received:', request.path, request.body);

  // 2. Send a response back to the client using the requestId
  await HttpLocalServer.sendResponse({
    requestId: request.requestId,
    body: JSON.stringify({ message: "Hello from Ionic!" })
  });
});

// 3. Start the server
HttpLocalServer.connect().then(result => {
  console.log('Server running at:', result.ip, 'Port:', result.port);
});
```

### Stop Server

```typescript
HttpLocalServer.disconnect()
```

---

## Platforms

- **iOS** (Swift)
- **Android** (Java)
- **Web** (Returns mock values for development)

---

## Requirements

- [Capacitor 7](https://capacitorjs.com/)
- [Ionic 8](https://ionicframework.com/) (optional, but tested)

---

## License

MIT

---

## Support

If you have any issues or feature requests, please open an issue on the repository.