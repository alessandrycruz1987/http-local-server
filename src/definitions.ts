import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Resultado de la conexión del servidor
 */
export interface HttpConnectResult {
  ip: string;
  port: number;
}

/**
 * Datos de una petición HTTP entrante
 */
export interface HttpRequestData {
  requestId: string;
  method: string;
  path: string;
  body?: string; // Ahora es opcional (GET/DELETE no tienen body)
  headers?: Record<string, string>; // Mejor tipado que 'any'
  query?: Record<string, string>; // Agregado: query parameters
}

/**
 * Opciones para enviar una respuesta
 */
export interface HttpSendResponseOptions {
  requestId: string;
  body: string;
}

/**
 * Plugin para manejar un servidor HTTP local en dispositivos nativos
 */
export interface HttpLocalServerPlugin {
  /**
   * Inicia el servidor local en el dispositivo nativo.
   * Devuelve la IP y el puerto asignado.
   * 
   * @returns Promesa con la IP y puerto del servidor
   * @throws Error si el servidor no puede iniciarse
   */
  connect(): Promise<HttpConnectResult>;

  /**
   * Detiene el servidor local y limpia todos los recursos.
   * 
   * @returns Promesa que se resuelve cuando el servidor se detiene
   */
  disconnect(): Promise<void>;

  /**
   * Envía la respuesta de vuelta al cliente que hizo la petición.
   * El requestId debe coincidir con el recibido en 'onRequest'.
   * 
   * @param options - Objeto con requestId y body de la respuesta
   * @returns Promesa que se resuelve cuando la respuesta se envía
   * @throws Error si faltan requestId o body
   */
  sendResponse(options: HttpSendResponseOptions): Promise<void>;

  /**
   * Escucha las peticiones HTTP entrantes.
   * 
   * @param eventName - Debe ser 'onRequest'
   * @param listenerFunc - Callback que recibe los datos de la petición
   * @returns Handle para remover el listener
   */
  addListener(
    eventName: 'onRequest',
    listenerFunc: (data: HttpRequestData) => void
  ): Promise<PluginListenerHandle>;

  /**
   * Elimina todos los listeners registrados.
   * 
   * @returns Promesa que se resuelve cuando se eliminan los listeners
   */
  removeAllListeners(): Promise<void>;
}