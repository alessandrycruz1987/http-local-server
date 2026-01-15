import { registerPlugin } from '@capacitor/core';

import type { HttpLocalServerPlugin } from './definitions';

const HttpLocalServer = registerPlugin<HttpLocalServerPlugin>('HttpLocalServer', {
  web: () => import('./web').then((m) => new m.HttpLocalServerWeb()),
});

export * from './definitions';
export { HttpLocalServer };
