import { WebPlugin } from '@capacitor/core';
import type {
  HttpLocalServerPlugin,
  HttpConnectResult,
  HttpSendResponseOptions
} from './definitions';

/**
 * Implementación web del plugin HttpLocalServer.
 * Proporciona funcionalidad mock para desarrollo en navegador.
 */
export class HttpLocalServerWeb extends WebPlugin implements HttpLocalServerPlugin {

  private isRunning = false;

  async connect(): Promise<HttpConnectResult> {
    if (this.isRunning) {
      console.warn('HttpLocalServer: El servidor ya está ejecutándose (Mock).');
      return { ip: '127.0.0.1', port: 8080 };
    }

    console.warn(
      'HttpLocalServer: El servidor nativo no está disponible en navegador. ' +
      'Retornando valores mock para desarrollo.'
    );

    this.isRunning = true;

    return {
      ip: '127.0.0.1',
      port: 8080
    };
  }

  async disconnect(): Promise<void> {
    if (!this.isRunning) {
      console.log('HttpLocalServer: El servidor ya está detenido (Mock).');
      return;
    }

    console.log('HttpLocalServer: Servidor detenido (Mock).');
    this.isRunning = false;
  }

  async sendResponse(options: HttpSendResponseOptions): Promise<void> {
    if (!this.isRunning) {
      console.warn('HttpLocalServer: El servidor no está ejecutándose (Mock).');
      return;
    }

    const { requestId, body } = options;

    if (!requestId) {
      throw new Error('Missing requestId');
    }

    if (!body) {
      throw new Error('Missing body');
    }

    console.log(
      `HttpLocalServer: Respuesta mock enviada para requestId: ${requestId}`,
      '\nBody:', body.substring(0, 100) + (body.length > 100 ? '...' : '')
    );
  }
}