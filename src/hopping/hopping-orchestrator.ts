#!/usr/bin/env node
/**
 * hopping-orchestrator.ts
 *
 * Operator-owned WireGuard / SOCKS5 hop rotator.
 * Reads endpoints from an AES-256-GCM encrypted .env (HOPENV1), rotates every N
 * minutes with node-cron, signs the public connection details with ML-DSA-65,
 * and publishes the envelope to Redis/Valkey and/or a DNS TXT API.
 *
 * Clients must call fetchAndVerifyHopPayload() before connecting.
 *
 * Usage:
 *   npx tsx src/hopping/hopping-orchestrator.ts keygen
 *   npx tsx src/hopping/hopping-orchestrator.ts encrypt-env --in .env.hop --out .env
 *   npx tsx src/hopping/hopping-orchestrator.ts rotate-once
 *   npx tsx src/hopping/hopping-orchestrator.ts serve
 *   npx tsx src/hopping/hopping-orchestrator.ts fetch
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import cron from 'node-cron'
import { bytesToHex, decodeKey } from './bytes'
import { fetchAndVerifyHopPayload } from './client'
import { loadConfigFromEnvFile, loadOrchestratorConfig } from './config'
import { encryptEnvText } from './encryptedEnv'
import { generateMlDsaKeys, signHopPayload, verifyHopEnvelope } from './mlDsa'
import { createPublishers } from './publish'
import { applyEndpoint, nextEndpoint } from './rotate'
import type { HopPublisher, OrchestratorConfig, SignedHopEnvelope } from './types'
import { toPublicConnection } from './wireguard'

export { fetchAndVerifyHopPayload } from './client'
export { verifyHopEnvelope, signHopPayload, generateMlDsaKeys } from './mlDsa'
export { loadConfigFromEnvFile, loadOrchestratorConfig } from './config'

export interface RotateResult {
  hop: number
  envelope: SignedHopEnvelope
  statePath: string
}

export async function rotateOnce(
  config: OrchestratorConfig,
  hop: number,
  publishers: HopPublisher[],
  now: Date = new Date(),
): Promise<RotateResult> {
  const endpoint = nextEndpoint(config.endpoints, hop)
  const applied = await applyEndpoint(endpoint, {
    runtimeDir: config.runtimeDir,
    activateCommand: config.activateCommand,
    activateArgs: config.activateArgs,
  })

  const issuedAt = now.toISOString()
  const expiresAt = new Date(now.getTime() + config.ttlMinutes * 60_000).toISOString()
  const envelope = signHopPayload(
    {
      v: 1,
      hop,
      issuedAt,
      expiresAt,
      connection: toPublicConnection(endpoint, config.publishSocksPassword),
    },
    config.secretKey,
  )

  verifyHopEnvelope(envelope, config.publicKey, now)
  for (const publisher of publishers) {
    await publisher.push(envelope)
  }

  return { hop, envelope, statePath: applied.statePath }
}

export function startHoppingScheduler(
  config: OrchestratorConfig,
  publishers: HopPublisher[],
  onRotate?: (result: RotateResult) => void,
): { stop: () => void; getHop: () => number } {
  let hop = 0
  const expression = `*/${config.intervalMinutes} * * * *`
  if (!cron.validate(expression)) {
    throw new Error(`Invalid cron expression for interval ${config.intervalMinutes}m`)
  }

  const task = cron.schedule(expression, () => {
    hop += 1
    void rotateOnce(config, hop, publishers)
      .then((result) => onRotate?.(result))
      .catch((error: unknown) => {
        console.error('[hop] rotation failed', error)
      })
  })

  return {
    stop: () => {
      task.stop()
    },
    getHop: () => hop,
  }
}

function parseArgs(argv: string[]): { command: string; flags: Record<string, string> } {
  const [command = 'help', ...rest] = argv
  const flags: Record<string, string> = {}
  for (let i = 0; i < rest.length; i++) {
    const token = rest[i]
    if (token.startsWith('--') && rest[i + 1] && !rest[i + 1].startsWith('--')) {
      flags[token.slice(2)] = rest[i + 1]
      i += 1
    } else if (token.startsWith('--')) {
      flags[token.slice(2)] = '1'
    }
  }
  return { command, flags }
}

function resolveConfig(flags: Record<string, string>): OrchestratorConfig {
  const envFile = flags.env ?? process.env.HOP_ENV_FILE
  if (envFile) {
    return loadConfigFromEnvFile(envFile, {
      masterKey: process.env.HOP_ENV_KEY ? decodeKey(process.env.HOP_ENV_KEY) : undefined,
      allowPlaintext: process.env.HOP_ALLOW_PLAINTEXT_ENV === '1' || flags.plaintext === '1',
    })
  }
  return loadOrchestratorConfig()
}

async function main(argv: string[]): Promise<void> {
  const { command, flags } = parseArgs(argv)

  if (command === 'keygen') {
    const keys = generateMlDsaKeys()
    process.stdout.write(
      `HOP_MLDSA_PUBLIC_KEY=${bytesToHex(keys.publicKey)}\nHOP_MLDSA_SECRET_KEY=${bytesToHex(keys.secretKey)}\n`,
    )
    return
  }

  if (command === 'encrypt-env') {
    const input = flags.in ?? '.env.hop'
    const output = flags.out ?? '.env'
    const key = decodeKey(flags.key ?? process.env.HOP_ENV_KEY ?? '')
    const encrypted = encryptEnvText(readFileSync(input, 'utf8'), key)
    writeFileSync(output, encrypted, { mode: 0o600 })
    process.stdout.write(`Wrote ${output}\n`)
    return
  }

  if (command === 'help' || command === '--help' || command === '-h') {
    process.stdout.write(`hopping-orchestrator commands: keygen | encrypt-env | rotate-once | serve | fetch\n`)
    return
  }

  const config = resolveConfig(flags)
  mkdirSync(config.runtimeDir, { recursive: true, mode: 0o700 })
  const publishers = createPublishers(config)

  if (command === 'rotate-once') {
    const hop = Number.parseInt(flags.hop ?? '0', 10)
    const result = await rotateOnce(config, hop, publishers)
    process.stdout.write(`${JSON.stringify({ hop: result.hop, id: result.envelope.payload.connection.id }, null, 2)}\n`)
    return
  }

  if (command === 'serve') {
    const first = await rotateOnce(config, 0, publishers)
    process.stdout.write(`[hop] published ${first.envelope.payload.connection.id} (hop 0)\n`)
    const scheduler = startHoppingScheduler(config, publishers, (result) => {
      process.stdout.write(`[hop] rotated to ${result.envelope.payload.connection.id} (hop ${result.hop})\n`)
    })
    process.stdout.write(`[hop] cron */${config.intervalMinutes} * * * *\n`)
    const shutdown = () => {
      scheduler.stop()
      process.exit(0)
    }
    process.on('SIGINT', shutdown)
    process.on('SIGTERM', shutdown)
    await new Promise(() => undefined)
    return
  }

  if (command === 'fetch') {
    const payload = await fetchAndVerifyHopPayload({
      publicKey: config.publicKey,
      redisUrl: config.redisUrl,
      redisKey: config.redisKey,
      dnsName: config.dns?.name,
    })
    process.stdout.write(`${JSON.stringify(payload, null, 2)}\n`)
    return
  }

  throw new Error(`Unknown command: ${command}`)
}

const invoked = process.argv[1] && resolve(process.argv[1]).includes('hopping-orchestrator')
if (invoked) {
  main(process.argv.slice(2)).catch((error: unknown) => {
    console.error(error instanceof Error ? error.message : error)
    process.exitCode = 1
  })
}

export { MemoryPublisher } from './publish'
