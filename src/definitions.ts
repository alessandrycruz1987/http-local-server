export interface HttpLocalServerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
