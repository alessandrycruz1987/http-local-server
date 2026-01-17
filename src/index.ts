import { registerPlugin } from '@capacitor/core';
import type { HttpLocalServerPlugin } from './definitions';

/**
 * Plugin de servidor HTTP local para Android e iOS.
 * 
 * Permite crear un servidor HTTP en el dispositivo que puede recibir
 * peticiones desde otros dispositivos en la misma red.
 * 
 * @example
 * ```typescript
 * import { HttpLocalServer } from '@cappitolian/http-local-server';
 * 
 * // Iniciar servidor
 * const { ip, port } = await HttpLocalServer.connect();
 * console.log(`Servidor en http://${ip}:${port}`);
 * 
 * // Escuchar peticiones
 * await HttpLocalServer.addListener('onRequest', async (data) => {
 *   console.log('Petición recibida:', data);
 *   
 *   // Procesar y responder
 *   await HttpLocalServer.sendResponse({
 *     requestId: data.requestId,
 *     body: JSON.stringify({ success: true })
 *   });
 * });
 * ```
 */
const HttpLocalServer = registerPlugin<HttpLocalServerPlugin>('HttpLocalServer', {
  web: () => import('./web').then(m => new m.HttpLocalServerWeb()),
});

export * from './definitions';
export { HttpLocalServer };
export default HttpLocalServer;