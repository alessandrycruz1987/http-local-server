import type { PluginListenerHandle } from '@capacitor/core';

export interface HttpConnectResult {
  ip: string;
  port: number;
}

export interface HttpRequestData {
  requestId: string;
  method: string;
  path: string;
  body: string;
  headers?: any;
}

export interface HttpLocalServerPlugin {
  /**
   * Inicia el servidor local en el dispositivo nativo.
   * Devuelve la IP y el puerto asignado.
   */
  connect(): Promise<HttpConnectResult>;

  /**
   * Detiene el servidor local.
   */
  disconnect(): Promise<void>;

  /**
   * Envía la respuesta de vuelta al cliente que hizo la petición.
   * El requestId debe coincidir con el recibido en 'onRequest'.
   */
  sendResponse(options: { requestId: string; body: string }): Promise<void>;

  /**
   * Escucha las peticiones HTTP entrantes.
   */
  addListener(
    eventName: 'onRequest',
    listenerFunc: (data: HttpRequestData) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Elimina todos los listeners registrados.
   */
  removeAllListeners(): Promise<void>;
}