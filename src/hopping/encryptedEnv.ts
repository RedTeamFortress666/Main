import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto'
import { readFileSync } from 'node:fs'
import { ENV_MAGIC } from './types'
import { base64ToBytes, bytesToBase64, decodeKey } from './bytes'

export function parseDotEnv(text: string): Record<string, string> {
  const out: Record<string, string> = {}
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue
    const eq = line.indexOf('=')
    if (eq < 1) continue
    const key = line.slice(0, eq).trim()
    let value = line.slice(eq + 1).trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    out[key] = value
  }
  return out
}

export function encryptEnvText(plaintext: string, masterKey: Uint8Array): string {
  if (masterKey.length !== 32) {
    throw new Error('HOP_ENV_KEY must be 32 bytes (64 hex chars)')
  }
  const key = Buffer.from(masterKey)
  const iv = randomBytes(12)
  const cipher = createCipheriv('aes-256-gcm', key, iv)
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()])
  const tag = cipher.getAuthTag()
  const packed = Buffer.concat([iv, tag, ciphertext])
  return `${ENV_MAGIC}\n${bytesToBase64(packed)}\n`
}

export function decryptEnvText(serialized: string, masterKey: Uint8Array): string {
  if (masterKey.length !== 32) {
    throw new Error('HOP_ENV_KEY must be 32 bytes (64 hex chars)')
  }
  const trimmed = serialized.trim()
  if (!trimmed.startsWith(ENV_MAGIC)) {
    throw new Error('Encrypted env must start with HOPENV1')
  }
  const payload = trimmed.slice(ENV_MAGIC.length).trim()
  const packed = Buffer.from(base64ToBytes(payload))
  if (packed.length < 12 + 16) {
    throw new Error('Encrypted env payload is truncated')
  }
  const iv = packed.subarray(0, 12)
  const tag = packed.subarray(12, 28)
  const ciphertext = packed.subarray(28)
  const decipher = createDecipheriv('aes-256-gcm', Buffer.from(masterKey), iv)
  decipher.setAuthTag(tag)
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8')
}

export function loadEnvFile(
  path: string,
  options: { masterKey?: Uint8Array; allowPlaintext?: boolean } = {},
): Record<string, string> {
  const raw = readFileSync(path, 'utf8')
  if (raw.trimStart().startsWith(ENV_MAGIC)) {
    const key = options.masterKey ?? decodeKey(requiredEnv('HOP_ENV_KEY'))
    return parseDotEnv(decryptEnvText(raw, key))
  }
  if (!options.allowPlaintext) {
    throw new Error(
      `Refusing to read plaintext ${path}. Encrypt it (hop encrypt-env) or set HOP_ALLOW_PLAINTEXT_ENV=1`,
    )
  }
  return parseDotEnv(raw)
}

export function requiredEnv(
  name: string,
  source: Record<string, string | undefined> = process.env,
): string {
  const value = source[name]
  if (!value) throw new Error(`Missing required environment variable ${name}`)
  return value
}
