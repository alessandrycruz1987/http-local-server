import { WebPlugin } from '@capacitor/core';
import type { HttpLocalServerPlugin, HttpConnectResult } from './definitions';

export class HttpLocalServerWeb extends WebPlugin implements HttpLocalServerPlugin {
  async connect(): Promise<HttpConnectResult> {
    console.warn('HttpLocalServer: El servidor nativo no se puede iniciar en el navegador.');
    // Devolvemos un valor por defecto para no romper la ejecución en web
    return { ip: '127.0.0.1', port: 8080 };
  }

  async disconnect(): Promise<void> {
    console.log('HttpLocalServer: Servidor detenido (Mock).');
  }

  async sendResponse(options: { requestId: string; body: string }): Promise<void> {
    console.log('HttpLocalServer: Respuesta mock enviada al requestId:', options.requestId);
  }
}