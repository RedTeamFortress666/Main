/** @vitest-environment node */
import { mkdtemp, readFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'
import { bytesToHex } from './bytes'
import { fetchAndVerifyHopPayload } from './client'
import { loadOrchestratorConfig } from './config'
import { decryptEnvText, encryptEnvText, parseDotEnv } from './encryptedEnv'
import { generateMlDsaKeys } from './mlDsa'
import { decodeDnsTxtChunks, MemoryPublisher } from './publish'
import { nextEndpoint } from './rotate'
import { rotateOnce } from './hopping-orchestrator'

const WG_A = `[Interface]
PrivateKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
Address = 10.8.0.2/32
[Peer]
PublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB BBB=
Endpoint = 203.0.113.10:51820
`

const WG_B = `[Interface]
PrivateKey = CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=
Address = 10.8.0.3/32
[Peer]
PublicKey = DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=
Endpoint = 198.51.100.20:51820
`

function sampleEndpoints() {
  return [
    {
      id: 'exit-a',
      wireguard: { interface: 'wg0', config: WG_A },
      socks5: { host: '203.0.113.10', port: 1080, username: 'alice', password: 'secret-a' },
    },
    {
      id: 'exit-b',
      wireguard: { interface: 'wg1', config: WG_B },
      socks5: { host: '198.51.100.20', port: 1080, username: 'bob', password: 'secret-b' },
    },
  ]
}

describe('encrypted env', () => {
  it('round-trips dotenv text through AES-256-GCM', () => {
    const key = new Uint8Array(32).map((_, i) => i + 1)
    const plain = 'HOP_INTERVAL_MINUTES=5\nHOP_REDIS_KEY=hop:current\n'
    const encrypted = encryptEnvText(plain, key)
    expect(encrypted.startsWith('HOPENV1')).toBe(true)
    expect(decryptEnvText(encrypted, key)).toBe(plain)
    expect(parseDotEnv(plain).HOP_INTERVAL_MINUTES).toBe('5')
  })
})

describe('hopping orchestrator', () => {
  it('rotates endpoints, signs with ML-DSA, and lets a client verify before connect', async () => {
    const keys = generateMlDsaKeys(new Uint8Array(32).fill(7))
    const runtimeDir = await mkdtemp(join(tmpdir(), 'hop-'))
    const config = loadOrchestratorConfig({
      HOP_INTERVAL_MINUTES: '5',
      HOP_TTL_MINUTES: '30',
      HOP_ENDPOINTS: JSON.stringify(sampleEndpoints()),
      HOP_MLDSA_SECRET_KEY: bytesToHex(keys.secretKey),
      HOP_MLDSA_PUBLIC_KEY: bytesToHex(keys.publicKey),
      HOP_RUNTIME_DIR: runtimeDir,
    })
    const publisher = new MemoryPublisher()

    const first = await rotateOnce(config, 0, [publisher], new Date('2026-08-22T21:00:00Z'))
    expect(first.envelope.payload.connection.id).toBe('exit-a')
    expect(first.envelope.payload.connection.wireguard?.peerEndpoint).toBe('203.0.113.10:51820')
    expect(JSON.stringify(first.envelope)).not.toMatch(/PrivateKey/i)
    expect(first.envelope.payload.connection.socks5?.password).toBeUndefined()

    const verified = await fetchAndVerifyHopPayload({
      publicKey: keys.publicKey,
      publisher,
      now: new Date('2026-08-22T21:05:00Z'),
    })
    expect(verified.connection.id).toBe('exit-a')
    expect(verified.hop).toBe(0)

    const second = await rotateOnce(config, 1, [publisher], new Date('2026-08-22T21:05:00Z'))
    expect(second.envelope.payload.connection.id).toBe('exit-b')

    const again = await fetchAndVerifyHopPayload({
      publicKey: keys.publicKey,
      publisher,
      now: new Date('2026-08-22T21:06:00Z'),
    })
    expect(again.connection.id).toBe('exit-b')
    expect(nextEndpoint(config.endpoints, 2).id).toBe('exit-a')

    const txt = decodeDnsTxtChunks(publisher.txtChunks)
    expect(txt.payload.connection.id).toBe('exit-b')

    const state = await readFile(join(runtimeDir, 'active.json'), 'utf8')
    expect(state).toContain('exit-b')
  })

  it('rejects an expired payload', async () => {
    const keys = generateMlDsaKeys(new Uint8Array(32).fill(3))
    const runtimeDir = await mkdtemp(join(tmpdir(), 'hop-'))
    const config = loadOrchestratorConfig({
      HOP_INTERVAL_MINUTES: '5',
      HOP_TTL_MINUTES: '1',
      HOP_ENDPOINTS: JSON.stringify(sampleEndpoints()),
      HOP_MLDSA_SECRET_KEY: bytesToHex(keys.secretKey),
      HOP_MLDSA_PUBLIC_KEY: bytesToHex(keys.publicKey),
      HOP_RUNTIME_DIR: runtimeDir,
    })
    const publisher = new MemoryPublisher()
    await rotateOnce(config, 0, [publisher], new Date('2026-08-22T21:00:00Z'))

    await expect(
      fetchAndVerifyHopPayload({
        publicKey: keys.publicKey,
        publisher,
        now: new Date('2026-08-22T21:05:00Z'),
      }),
    ).rejects.toThrow(/expired/i)
  })
})
