import { registerPlugin } from '@capacitor/core';
import type { HttpLocalServerPlugin } from './definitions';

/**
 * Registramos el plugin. 
 * El nombre 'HttpLocalServer' debe coincidir con el @CapacitorPlugin en Java 
 * y el @objc(HttpLocalServerPlugin) en Swift.
 */
const HttpLocalServer = registerPlugin<HttpLocalServerPlugin>('HttpLocalServer', {
  web: () => import('./web').then(m => new m.HttpLocalServerWeb()),
});

// Exportamos las interfaces para que el usuario pueda tipar sus variables
export * from './definitions';

// Exportamos el objeto del plugin
export { HttpLocalServer };

// Exportación por defecto opcional para mayor compatibilidad
export default HttpLocalServer;