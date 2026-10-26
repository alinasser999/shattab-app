import { Writable } from "node:stream";

import type { DatabaseHealth } from "../src/database.js";

export function fakeDatabaseHealth(
  check: () => Promise<void> = async () => undefined,
  close: () => Promise<void> = async () => undefined,
): DatabaseHealth {
  return { check, close };
}

export class LogCapture extends Writable {
  readonly chunks: string[] = [];

  override _write(
    chunk: Buffer | string,
    _encoding: BufferEncoding,
    callback: (error?: Error | null) => void,
  ): void {
    this.chunks.push(String(chunk));
    callback();
  }

  get text(): string {
    return this.chunks.join("");
  }
}
