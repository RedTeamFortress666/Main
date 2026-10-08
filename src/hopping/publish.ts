import { gunzipSync, gzipSync } from 'node:zlib'
import { createClient, type RedisClientType } from 'redis'
import { base64ToBytes, bytesToBase64 } from './bytes'
import {
  DEFAULT_REDIS_KEY,
  DNS_CHUNK_PREFIX,
  type DnsPublishConfig,
  type HopPublisher,
  type SignedHopEnvelope,
} from './types'

const CHUNK_SIZE = 180

export function encodeDnsTxtChunks(envelope: SignedHopEnvelope): string[] {
  const packed = bytesToBase64(gzipSync(Buffer.from(JSON.stringify(envelope))))
  const chunks: string[] = []
  const total = Math.max(1, Math.ceil(packed.length / CHUNK_SIZE))
  for (let i = 0; i < total; i++) {
    const part = packed.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE)
    chunks.push(
      `${DNS_CHUNK_PREFIX}/${String(i + 1).padStart(3, '0')}/${String(total).padStart(3, '0')}/${part}`,
    )
  }
  return chunks
}

export function decodeDnsTxtChunks(records: string[]): SignedHopEnvelope {
  const parsed = records
    .map((record) => record.replace(/\s+/g, ''))
    .map((record) => {
      const match = record.match(/^HOP1\/(\d{3})\/(\d{3})\/([A-Za-z0-9+/=]+)$/)
      if (!match) return null
      return {
        index: Number.parseInt(match[1], 10),
        total: Number.parseInt(match[2], 10),
        chunk: match[3],
      }
    })
    .filter((row): row is { index: number; total: number; chunk: string } => row !== null)
    .sort((a, b) => a.index - b.index)

  if (parsed.length === 0) {
    throw new Error('No hop TXT chunks found')
  }
  const total = parsed[0].total
  if (parsed.length !== total) {
    throw new Error(`Incomplete hop TXT set: got ${parsed.length} of ${total}`)
  }
  const packed = parsed.map((row) => row.chunk).join('')
  return JSON.parse(gunzipSync(Buffer.from(base64ToBytes(packed))).toString('utf8')) as SignedHopEnvelope
}

export class MemoryPublisher implements HopPublisher {
  private envelope: SignedHopEnvelope | null = null
  readonly txtChunks: string[] = []

  async push(envelope: SignedHopEnvelope): Promise<void> {
    this.envelope = envelope
    this.txtChunks.splice(0, this.txtChunks.length, ...encodeDnsTxtChunks(envelope))
  }

  async fetch(): Promise<SignedHopEnvelope | null> {
    return this.envelope
  }
}

export class RedisPublisher implements HopPublisher {
  private client: RedisClientType | null = null

  constructor(
    private readonly url: string,
    private readonly key = DEFAULT_REDIS_KEY,
  ) {}

  private async connect(): Promise<RedisClientType> {
    if (this.client) return this.client
    const client = createClient({ url: this.url })
    await client.connect()
    this.client = client as RedisClientType
    return this.client
  }

  async push(envelope: SignedHopEnvelope): Promise<void> {
    const client = await this.connect()
    await client.set(this.key, JSON.stringify(envelope))
  }

  async fetch(): Promise<SignedHopEnvelope | null> {
    const client = await this.connect()
    const raw = await client.get(this.key)
    if (!raw) return null
    return JSON.parse(raw) as SignedHopEnvelope
  }

  async close(): Promise<void> {
    if (this.client) {
      await this.client.quit()
      this.client = null
    }
  }
}

export class DnsTxtPublisher implements HopPublisher {
  constructor(
    private readonly dns: DnsPublishConfig,
    private readonly fetchImpl: typeof fetch = fetch,
    private readonly resolveTxt: (name: string) => Promise<string[]> = defaultResolveTxt,
  ) {}

  async push(envelope: SignedHopEnvelope): Promise<void> {
    const chunks = encodeDnsTxtChunks(envelope)
    const content = chunks.join(' ')
    if (this.dns.provider === 'generic') {
      if (!this.dns.genericUrl) throw new Error('HOP_DNS_GENERIC_URL is required')
      const response = await this.fetchImpl(this.dns.genericUrl, {
        method: 'PUT',
        headers: {
          'content-type': 'application/json',
          ...(this.dns.token ? { authorization: `Bearer ${this.dns.token}` } : {}),
        },
        body: JSON.stringify({ name: this.dns.name, type: 'TXT', chunks }),
      })
      if (!response.ok) {
        throw new Error(`DNS generic API returned ${response.status}`)
      }
      return
    }

    if (!this.dns.token || !this.dns.zoneId) {
      throw new Error('Cloudflare DNS publish requires HOP_DNS_TOKEN and HOP_DNS_ZONE_ID')
    }
    await this.upsertCloudflareTxt(content)
  }

  async fetch(): Promise<SignedHopEnvelope | null> {
    const records = await this.resolveTxt(this.dns.name)
    if (records.length === 0) return null
    return decodeDnsTxtChunks(records)
  }

  private async upsertCloudflareTxt(content: string): Promise<void> {
    const headers = {
      authorization: `Bearer ${this.dns.token}`,
      'content-type': 'application/json',
    }
    const listUrl = `https://api.cloudflare.com/client/v4/zones/${this.dns.zoneId}/dns_records?type=TXT&name=${encodeURIComponent(this.dns.name)}`
    const listed = (await (await this.fetchImpl(listUrl, { headers })).json()) as {
      result?: Array<{ id: string }>
    }
    const existingId = listed.result?.[0]?.id
    const body = JSON.stringify({
      type: 'TXT',
      name: this.dns.name,
      content,
      ttl: 60,
    })
    const url = existingId
      ? `https://api.cloudflare.com/client/v4/zones/${this.dns.zoneId}/dns_records/${existingId}`
      : `https://api.cloudflare.com/client/v4/zones/${this.dns.zoneId}/dns_records`
    const response = await this.fetchImpl(url, {
      method: existingId ? 'PUT' : 'POST',
      headers,
      body,
    })
    if (!response.ok) {
      throw new Error(`Cloudflare DNS API returned ${response.status}`)
    }
  }
}

async function defaultResolveTxt(name: string): Promise<string[]> {
  const { resolveTxt } = await import('node:dns/promises')
  try {
    const chunks = await resolveTxt(name)
    return chunks.map((parts) => parts.join(''))
  } catch {
    return []
  }
}

export function createPublishers(options: {
  redisUrl?: string
  redisKey: string
  dns?: DnsPublishConfig
}): HopPublisher[] {
  const publishers: HopPublisher[] = []
  if (options.redisUrl) {
    publishers.push(new RedisPublisher(options.redisUrl, options.redisKey))
  }
  if (options.dns) {
    publishers.push(new DnsTxtPublisher(options.dns))
  }
  return publishers
}
