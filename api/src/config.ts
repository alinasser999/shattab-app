export const LOOPBACK_HOST = "127.0.0.1" as const;

export type ApiHost = typeof LOOPBACK_HOST | "0.0.0.0";

const LOG_LEVELS = ["fatal", "error", "warn", "info", "debug", "trace", "silent"] as const;

export type LogLevel = (typeof LOG_LEVELS)[number];

export interface AppConfig {
  readonly host: ApiHost;
  readonly port: number;
  readonly logLevel: LogLevel;
  readonly database: DatabaseConfig;
}

export interface DatabaseConfig {
  readonly host: string;
  readonly name: string;
  readonly user: string;
  readonly passwordFile: string;
  readonly port: number;
  readonly poolMax: number;
}

type ConfigurationSetting =
  | "HOST"
  | "PORT"
  | "LOG_LEVEL"
  | "DATABASE_HOST"
  | "DATABASE_NAME"
  | "DATABASE_USER"
  | "DATABASE_PASSWORD_FILE"
  | "DATABASE_PORT"
  | "DATABASE_POOL_MAX"
  | "DATABASE_PASSWORD"
  | "DATABASE_URL"
  | "PGBINARY"
  | "PGREPLICATION";

export class ConfigurationError extends Error {
  constructor(setting: ConfigurationSetting, expected: string) {
    super(`Invalid ${setting}: expected ${expected}.`);
    this.name = "ConfigurationError";
  }
}

function requiredSetting(
  env: Record<string, string | undefined>,
  setting: "DATABASE_HOST" | "DATABASE_NAME" | "DATABASE_USER" | "DATABASE_PASSWORD_FILE",
): string {
  const value = env[setting];
  if (value === undefined || value.length === 0 || value.trim() !== value || /[\0\r\n]/.test(value)) {
    throw new ConfigurationError(setting, "a non-empty value without surrounding whitespace or control characters");
  }
  return value;
}

function integerSetting(
  env: Record<string, string | undefined>,
  setting: "DATABASE_PORT" | "DATABASE_POOL_MAX",
  defaultValue: number,
  minimum: number,
  maximum: number,
): number {
  const value = env[setting];
  if (value === undefined) return defaultValue;
  if (!/^\d+$/.test(value)) {
    throw new ConfigurationError(setting, `a decimal integer from ${minimum} to ${maximum}`);
  }

  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed < minimum || parsed > maximum) {
    throw new ConfigurationError(setting, `a decimal integer from ${minimum} to ${maximum}`);
  }
  return parsed;
}

export function parseConfig(env: Record<string, string | undefined>): AppConfig {
  const hostValue = env["HOST"] ?? LOOPBACK_HOST;
  if (hostValue !== LOOPBACK_HOST && hostValue !== "0.0.0.0") {
    throw new ConfigurationError("HOST", "127.0.0.1 or 0.0.0.0");
  }

  const portValue = env["PORT"] ?? "3000";
  if (!/^\d+$/.test(portValue)) {
    throw new ConfigurationError("PORT", "a decimal integer from 1 to 65535");
  }

  const port = Number(portValue);
  if (!Number.isSafeInteger(port) || port < 1 || port > 65_535) {
    throw new ConfigurationError("PORT", "a decimal integer from 1 to 65535");
  }

  const levelValue = env["LOG_LEVEL"] ?? "info";
  if (!LOG_LEVELS.some((level) => level === levelValue)) {
    throw new ConfigurationError("LOG_LEVEL", "one of fatal, error, warn, info, debug, trace, or silent");
  }

  if (env["DATABASE_PASSWORD"] !== undefined) {
    throw new ConfigurationError("DATABASE_PASSWORD", "not to be set; use DATABASE_PASSWORD_FILE");
  }
  if (env["DATABASE_URL"] !== undefined) {
    throw new ConfigurationError("DATABASE_URL", "not to be set; configure the individual database settings");
  }
  if (env["PGBINARY"] !== undefined) {
    throw new ConfigurationError("PGBINARY", "not to be set; node-postgres protocol mode is fixed by the API");
  }
  if (env["PGREPLICATION"] !== undefined) {
    throw new ConfigurationError("PGREPLICATION", "not to be set; the API requires a normal SQL connection");
  }

  const database: DatabaseConfig = {
    host: requiredSetting(env, "DATABASE_HOST"),
    name: requiredSetting(env, "DATABASE_NAME"),
    user: requiredSetting(env, "DATABASE_USER"),
    passwordFile: requiredSetting(env, "DATABASE_PASSWORD_FILE"),
    port: integerSetting(env, "DATABASE_PORT", 5432, 1, 65_535),
    poolMax: integerSetting(env, "DATABASE_POOL_MAX", 4, 1, 8),
  };

  return {
    host: hostValue,
    port,
    logLevel: levelValue as LogLevel,
    database,
  };
}
