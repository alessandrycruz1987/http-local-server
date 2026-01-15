import { WebPlugin } from '@capacitor/core';

import type { HttpLocalServerPlugin } from './definitions';

export class HttpLocalServerWeb extends WebPlugin implements HttpLocalServerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
