import { execFile } from 'node:child_process'
import { mkdir, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { promisify } from 'node:util'
import type { HopEndpoint } from './types'

const execFileAsync = promisify(execFile)

export function nextEndpoint(endpoints: HopEndpoint[], hop: number): HopEndpoint {
  if (endpoints.length === 0) {
    throw new Error('No WireGuard/SOCKS5 endpoints configured')
  }
  return endpoints[hop % endpoints.length]
}

/**
 * Apply the selected operator-owned endpoint locally.
 * Writes runtime state (0600) and optionally runs HOP_ACTIVATE_COMMAND.
 * The command is execFile'd — never interpolated into a shell.
 */
export async function applyEndpoint(
  endpoint: HopEndpoint,
  options: { runtimeDir: string; activateCommand?: string; activateArgs?: string[] },
): Promise<{ configPath?: string; statePath: string }> {
  await mkdir(options.runtimeDir, { recursive: true, mode: 0o700 })
  const statePath = join(options.runtimeDir, 'active.json')
  let configPath: string | undefined

  if (endpoint.wireguard) {
    configPath = join(options.runtimeDir, `${sanitizeName(endpoint.wireguard.interface)}.conf`)
    await writeFile(configPath, endpoint.wireguard.config, { mode: 0o600 })
  }

  await writeFile(
    statePath,
    `${JSON.stringify(
      {
        id: endpoint.id,
        interface: endpoint.wireguard?.interface,
        socks5: endpoint.socks5
          ? `${endpoint.socks5.host}:${endpoint.socks5.port}`
          : undefined,
        configPath,
      },
      null,
      2,
    )}\n`,
    { mode: 0o600 },
  )

  if (options.activateCommand) {
    await execFileAsync(options.activateCommand, options.activateArgs ?? [], {
      env: {
        ...process.env,
        HOP_ENDPOINT_ID: endpoint.id,
        HOP_INTERFACE: endpoint.wireguard?.interface ?? '',
        HOP_WG_CONFIG: configPath ?? '',
        HOP_SOCKS5_HOST: endpoint.socks5?.host ?? '',
        HOP_SOCKS5_PORT: endpoint.socks5 ? String(endpoint.socks5.port) : '',
      },
    })
  }

  return { configPath, statePath }
}

function sanitizeName(name: string): string {
  const cleaned = name.replace(/[^A-Za-z0-9._-]/g, '')
  if (!cleaned) throw new Error('Invalid WireGuard interface name')
  return cleaned
}
