import type { HopEndpoint, PublicConnectionDetails } from './types'

const PRIVATE_KEY_LINE = /^\s*PrivateKey\s*=/i

export function parseWireGuardPublicFields(config: string): {
  address?: string
  peerPublicKey?: string
  peerEndpoint?: string
} {
  const address = matchField(config, 'Address')
  const peerPublicKey = matchField(config, 'PublicKey')
  const peerEndpoint = matchField(config, 'Endpoint')
  return { address, peerPublicKey, peerEndpoint }
}

function matchField(config: string, name: string): string | undefined {
  const match = config.match(new RegExp(`^\\s*${name}\\s*=\\s*(.+)$`, 'im'))
  return match?.[1]?.trim()
}

export function assertNoPrivateKeyLeak(text: string): void {
  if (PRIVATE_KEY_LINE.test(text) || /PrivateKey/i.test(text)) {
    throw new Error('Refusing to publish a payload that contains a WireGuard PrivateKey')
  }
}

export function toPublicConnection(
  endpoint: HopEndpoint,
  publishSocksPassword: boolean,
): PublicConnectionDetails {
  const connection: PublicConnectionDetails = { id: endpoint.id }

  if (endpoint.wireguard) {
    const fields = parseWireGuardPublicFields(endpoint.wireguard.config)
    connection.wireguard = {
      interface: endpoint.wireguard.interface,
      ...fields,
    }
  }

  if (endpoint.socks5) {
    connection.socks5 = {
      host: endpoint.socks5.host,
      port: endpoint.socks5.port,
      username: endpoint.socks5.username,
      ...(publishSocksPassword ? { password: endpoint.socks5.password } : {}),
    }
  }

  assertNoPrivateKeyLeak(JSON.stringify(connection))
  return connection
}
