import { verifyHopEnvelope } from './mlDsa'
import { DnsTxtPublisher, RedisPublisher } from './publish'
import type { DnsPublishConfig, HopPayload, HopPublisher, SignedHopEnvelope } from './types'

export interface FetchHopOptions {
  publicKey: Uint8Array
  redisUrl?: string
  redisKey?: string
  dnsName?: string
  dnsResolver?: (name: string) => Promise<string[]>
  publisher?: HopPublisher
  now?: Date
}

/**
 * Fetch the current signed hop envelope from Redis/Valkey or DNS TXT,
 * then verify the ML-DSA-65 signature and expiry before the client connects.
 */
export async function fetchAndVerifyHopPayload(options: FetchHopOptions): Promise<HopPayload> {
  const envelope = await fetchHopEnvelope(options)
  if (!envelope) {
    throw new Error('No signed hop payload is available')
  }
  return verifyHopEnvelope(envelope, options.publicKey, options.now ?? new Date())
}

export async function fetchHopEnvelope(
  options: FetchHopOptions,
): Promise<SignedHopEnvelope | null> {
  if (options.publisher) {
    return options.publisher.fetch()
  }

  if (options.redisUrl) {
    const redis = new RedisPublisher(options.redisUrl, options.redisKey)
    try {
      return await redis.fetch()
    } finally {
      await redis.close()
    }
  }

  if (options.dnsName) {
    const dns: DnsPublishConfig = { name: options.dnsName, provider: 'generic' }
    const publisher = new DnsTxtPublisher(dns, fetch, options.dnsResolver)
    return publisher.fetch()
  }

  throw new Error('Provide redisUrl, dnsName, or a publisher')
}
