export type OperatorId = 'spamkat2' | 'gameon'

export interface OperatorAccount {
  id: OperatorId
  username: string
  password: string
  displayName: string
  vaultCode: string
  role: string
}

/** Bootstrapped operator accounts for GAME ØVER! Red Team Fortress */
export const OPERATORS: OperatorAccount[] = [
  {
    id: 'spamkat2',
    username: 'SpamKat2',
    password: 'Ev1lSchm33',
    displayName: 'SpamKat2',
    vaultCode: 'W1-66-3R',
    role: 'Red Team Operator',
  },
  {
    id: 'gameon',
    username: 'Gam3.0n',
    password: 'Dig1tal.Ra1n99',
    displayName: 'Gam3.0n',
    vaultCode: 'B1-66-3R',
    role: 'Fortress Lead',
  },
]

export function authenticate(username: string, password: string): OperatorAccount | null {
  const u = username.trim()
  const p = password
  return (
    OPERATORS.find((op) => op.username === u && op.password === p) ?? null
  )
}

export function verifyVaultCode(operator: OperatorAccount, code: string): boolean {
  return code.trim().toUpperCase() === operator.vaultCode.toUpperCase()
}

export const APP_NAME = 'GAME ØVER! Red Team Fortress'
export const APP_SHORT = 'GAME ØVER!'
export const APP_ORG = 'Red Team Fortress'
