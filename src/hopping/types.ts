export interface Socks5Endpoint {
  host: string
  port: number
  username?: string
  password?: string
}

export interface WireGuardProfile {
  /** Interface name owned by this operator, e.g. wg0 */
  interface: string
  /** Full WireGuard config text. Private keys stay on the orchestrator host. */
  config: string
}

export interface HopEndpoint {
  id: string
  wireguard?: WireGuardProfile
  socks5?: Socks5Endpoint
}

export interface PublicWireGuardDetails {
  interface: string
  address?: string
  peerPublicKey?: string
  peerEndpoint?: string
}

export interface PublicSocks5Details {
  host: string
  port: number
  username?: string
  password?: string
}

/** Client-facing connection details. WireGuard private keys are never included. */
export interface PublicConnectionDetails {
  id: string
  wireguard?: PublicWireGuardDetails
  socks5?: PublicSocks5Details
}

export interface HopPayload {
  v: 1
  hop: number
  issuedAt: string
  expiresAt: string
  connection: PublicConnectionDetails
}

export interface SignedHopEnvelope {
  payload: HopPayload
  algorithm: 'ML-DSA-65'
  signature: string
}

export interface OrchestratorConfig {
  intervalMinutes: number
  ttlMinutes: number
  endpoints: HopEndpoint[]
  secretKey: Uint8Array
  publicKey: Uint8Array
  publishSocksPassword: boolean
  runtimeDir: string
  activateCommand?: string
  activateArgs: string[]
  redisUrl?: string
  redisKey: string
  dns?: DnsPublishConfig
}

export interface DnsPublishConfig {
  name: string
  provider: 'cloudflare' | 'generic'
  token?: string
  zoneId?: string
  genericUrl?: string
}

export interface HopPublisher {
  push(envelope: SignedHopEnvelope): Promise<void>
  fetch(): Promise<SignedHopEnvelope | null>
}

export const SIGN_CONTEXT = new TextEncoder().encode('hop-orchestrator-v1')
export const ENV_MAGIC = 'HOPENV1'
export const DNS_CHUNK_PREFIX = 'HOP1'
export const DEFAULT_REDIS_KEY = 'hop:current'
export const DEFAULT_INTERVAL_MINUTES = 15
