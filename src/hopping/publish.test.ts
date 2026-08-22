import { describe, expect, it, vi } from 'vitest'
import { generateMlDsaKeys, signHopPayload } from './mlDsa'
import { decodeDnsTxtChunks, DnsTxtPublisher, encodeDnsTxtChunks } from './publish'
import type { HopPayload } from './types'

describe('DNS TXT chunking', () => {
  it('round-trips a signed envelope through concatenated TXT chunks', () => {
    const keys = generateMlDsaKeys(new Uint8Array(32).fill(9))
    const payload: HopPayload = {
      v: 1,
      hop: 3,
      issuedAt: '2026-08-22T21:00:00.000Z',
      expiresAt: '2026-08-22T21:30:00.000Z',
      connection: {
        id: 'exit-a',
        socks5: { host: '203.0.113.10', port: 1080 },
      },
    }
    const envelope = signHopPayload(payload, keys.secretKey)
    const chunks = encodeDnsTxtChunks(envelope)
    expect(chunks.length).toBeGreaterThan(1)
    expect(chunks[0].startsWith('HOP1/001/')).toBe(true)
    expect(decodeDnsTxtChunks(chunks).payload.connection.id).toBe('exit-a')
  })
})

describe('DnsTxtPublisher', () => {
  it('PUTs chunked records to a generic DNS API', async () => {
    const fetchImpl = vi.fn(async () => new Response('ok', { status: 200 }))
    const publisher = new DnsTxtPublisher(
      {
        name: 'hop.example.com',
        provider: 'generic',
        genericUrl: 'https://dns.example.com/txt',
        token: 'dns-token',
      },
      fetchImpl as unknown as typeof fetch,
    )
    const keys = generateMlDsaKeys(new Uint8Array(32).fill(2))
    const envelope = signHopPayload(
      {
        v: 1,
        hop: 0,
        issuedAt: '2026-08-22T21:00:00.000Z',
        expiresAt: '2026-08-22T22:00:00.000Z',
        connection: { id: 'exit-a' },
      },
      keys.secretKey,
    )
    await publisher.push(envelope)
    expect(fetchImpl).toHaveBeenCalledOnce()
    const [url, init] = fetchImpl.mock.calls[0] as unknown as [string, RequestInit]
    expect(url).toBe('https://dns.example.com/txt')
    expect(init.method).toBe('PUT')
    const body = JSON.parse(String(init.body)) as { chunks: string[] }
    expect(body.chunks[0]).toMatch(/^HOP1\/001\//)
  })
})
