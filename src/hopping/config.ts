import { decodeKey } from './bytes'
import { loadEnvFile, requiredEnv } from './encryptedEnv'
import {
  DEFAULT_INTERVAL_MINUTES,
  DEFAULT_REDIS_KEY,
  type HopEndpoint,
  type OrchestratorConfig,
} from './types'

export function loadOrchestratorConfig(
  env: Record<string, string | undefined> = process.env,
): OrchestratorConfig {
  const intervalMinutes = Number.parseInt(
    env.HOP_INTERVAL_MINUTES ?? String(DEFAULT_INTERVAL_MINUTES),
    10,
  )
  if (!Number.isInteger(intervalMinutes) || intervalMinutes < 1 || intervalMinutes > 59) {
    throw new Error('HOP_INTERVAL_MINUTES must be an integer from 1 to 59')
  }

  const ttlMinutes = Number.parseInt(env.HOP_TTL_MINUTES ?? String(intervalMinutes * 2), 10)
  const endpoints = parseEndpoints(env)
  const secretKey = decodeKey(requiredEnv('HOP_MLDSA_SECRET_KEY', env))
  const publicKey = decodeKey(requiredEnv('HOP_MLDSA_PUBLIC_KEY', env))

  let activateArgs: string[] = []
  if (env.HOP_ACTIVATE_ARGS) {
    const parsed = JSON.parse(env.HOP_ACTIVATE_ARGS) as unknown
    if (!Array.isArray(parsed) || parsed.some((item) => typeof item !== 'string')) {
      throw new Error('HOP_ACTIVATE_ARGS must be a JSON array of strings')
    }
    activateArgs = parsed
  }

  return {
    intervalMinutes,
    ttlMinutes,
    endpoints,
    secretKey,
    publicKey,
    publishSocksPassword: env.HOP_PUBLISH_SOCKS_PASSWORD === '1',
    runtimeDir: env.HOP_RUNTIME_DIR ?? '.hop-runtime',
    activateCommand: env.HOP_ACTIVATE_COMMAND,
    activateArgs,
    redisUrl: env.HOP_REDIS_URL,
    redisKey: env.HOP_REDIS_KEY ?? DEFAULT_REDIS_KEY,
    dns: env.HOP_DNS_NAME
      ? {
          name: env.HOP_DNS_NAME,
          provider: env.HOP_DNS_PROVIDER === 'generic' ? 'generic' : 'cloudflare',
          token: env.HOP_DNS_TOKEN,
          zoneId: env.HOP_DNS_ZONE_ID,
          genericUrl: env.HOP_DNS_GENERIC_URL,
        }
      : undefined,
  }
}

export function parseEndpoints(env: Record<string, string | undefined>): HopEndpoint[] {
  if (!env.HOP_ENDPOINTS) {
    throw new Error('HOP_ENDPOINTS is required (JSON array of WireGuard/SOCKS5 endpoints)')
  }
  const parsed = JSON.parse(env.HOP_ENDPOINTS) as unknown
  if (!Array.isArray(parsed) || parsed.length === 0) {
    throw new Error('HOP_ENDPOINTS must be a non-empty JSON array')
  }
  return parsed.map((item, index) => {
    if (!item || typeof item !== 'object') {
      throw new Error(`HOP_ENDPOINTS[${index}] must be an object`)
    }
    const row = item as HopEndpoint
    if (!row.id) throw new Error(`HOP_ENDPOINTS[${index}].id is required`)
    if (row.socks5) {
      if (!row.socks5.host || !Number.isInteger(row.socks5.port)) {
        throw new Error(`HOP_ENDPOINTS[${index}].socks5 needs host and integer port`)
      }
    }
    if (row.wireguard && (!row.wireguard.interface || !row.wireguard.config)) {
      throw new Error(`HOP_ENDPOINTS[${index}].wireguard needs interface and config`)
    }
    if (!row.socks5 && !row.wireguard) {
      throw new Error(`HOP_ENDPOINTS[${index}] needs wireguard and/or socks5`)
    }
    return row
  })
}

export function loadConfigFromEnvFile(
  path: string,
  options: { masterKey?: Uint8Array; allowPlaintext?: boolean } = {},
): OrchestratorConfig {
  const parsed = loadEnvFile(path, options)
  return loadOrchestratorConfig({ ...process.env, ...parsed })
}
