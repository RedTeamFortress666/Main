import { useEffect, useState } from 'react'
import {
  APP_NAME,
  APP_ORG,
  APP_SHORT,
  type OperatorAccount,
} from './auth/operators'
import { BottomNav } from './components/BottomNav'
import { ATTACK_MODULES, type ModuleId, type NavTab } from './data/modules'
import { AirScreen } from './screens/AirScreen'
import { CapturesScreen } from './screens/CapturesScreen'
import { HomeScreen } from './screens/HomeScreen'
import { LoginScreen } from './screens/LoginScreen'
import { ModuleDetailScreen } from './screens/ModuleDetailScreen'
import { PortalScreen } from './screens/PortalScreen'
import { ScannerScreen } from './screens/ScannerScreen'
import { VaultScreen } from './screens/VaultScreen'
import { WifiScreen } from './screens/WifiScreen'
import './App.css'

const SESSION_KEY = 'game-over.operator'
const VAULT_KEY = 'game-over.vault'

function loadOperator(): OperatorAccount | null {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY)
    if (!raw) return null
    return JSON.parse(raw) as OperatorAccount
  } catch {
    return null
  }
}

export default function App() {
  const [operator, setOperator] = useState<OperatorAccount | null>(() => loadOperator())
  const [vaultUnlocked, setVaultUnlocked] = useState(() => {
    try {
      return sessionStorage.getItem(VAULT_KEY) === '1'
    } catch {
      return false
    }
  })
  const [airOpen, setAirOpen] = useState(false)
  const [tab, setTab] = useState<NavTab>('home')
  const [moduleId, setModuleId] = useState<ModuleId | null>(null)
  const [toast, setToast] = useState<string | null>(null)

  useEffect(() => {
    if (!toast) return
    const id = window.setTimeout(() => setToast(null), 2600)
    return () => window.clearTimeout(id)
  }, [toast])

  function showToast(message: string) {
    setToast(message)
  }

  function handleLogin(op: OperatorAccount) {
    setOperator(op)
    setVaultUnlocked(false)
    setAirOpen(false)
    setTab('home')
    try {
      sessionStorage.setItem(SESSION_KEY, JSON.stringify(op))
      sessionStorage.removeItem(VAULT_KEY)
    } catch {
      /* ignore */
    }
    showToast(`Welcome, ${op.displayName}`)
  }

  function handleLogout() {
    setOperator(null)
    setVaultUnlocked(false)
    setAirOpen(false)
    setModuleId(null)
    try {
      sessionStorage.removeItem(SESSION_KEY)
      sessionStorage.removeItem(VAULT_KEY)
    } catch {
      /* ignore */
    }
  }

  function unlockVault() {
    setVaultUnlocked(true)
    try {
      sessionStorage.setItem(VAULT_KEY, '1')
    } catch {
      /* ignore */
    }
  }

  function openModule(id: ModuleId) {
    const mod = ATTACK_MODULES.find((m) => m.id === id)
    if (mod?.tab) {
      setModuleId(null)
      setTab(mod.tab)
      return
    }
    setModuleId(id)
  }

  function changeTab(next: NavTab) {
    setModuleId(null)
    setAirOpen(false)
    setTab(next)
  }

  if (!operator) {
    return (
      <>
        <LoginScreen onLogin={handleLogin} />
        {toast && (
          <div className="toast" role="status" aria-live="polite">
            {toast}
          </div>
        )}
      </>
    )
  }

  return (
    <div className="shell">
      <div className="shell__glow" aria-hidden />
      <header className="topbar">
        <div>
          <p className="topbar__brand">{APP_SHORT}</p>
          <p className="topbar__sub">{APP_ORG} · {APP_NAME}</p>
        </div>
        <div className="topbar__actions">
          <div className="topbar__status">
            <span className="topbar__dot" />
            {operator.displayName}
          </div>
          <button type="button" className="topbar__logout" onClick={handleLogout}>
            LOGOUT
          </button>
        </div>
      </header>

      <main className="shell__main">
        {airOpen ? (
          <AirScreen
            operator={operator}
            onBack={() => setAirOpen(false)}
            toast={showToast}
          />
        ) : moduleId ? (
          <ModuleDetailScreen
            moduleId={moduleId}
            toast={showToast}
            onBack={() => setModuleId(null)}
          />
        ) : (
          <>
            {tab === 'home' && <HomeScreen onOpenModule={openModule} />}
            {tab === 'scanner' && <ScannerScreen toast={showToast} />}
            {tab === 'portal' && <PortalScreen toast={showToast} />}
            {tab === 'captures' && <CapturesScreen toast={showToast} />}
            {tab === 'wifi' && <WifiScreen toast={showToast} />}
            {tab === 'vault' && (
              <VaultScreen
                operator={operator}
                unlocked={vaultUnlocked}
                onUnlock={unlockVault}
                onEnterAir={() => setAirOpen(true)}
                toast={showToast}
              />
            )}
          </>
        )}
      </main>

      {!airOpen && <BottomNav active={tab} onChange={changeTab} />}

      {toast && (
        <div className="toast" role="status" aria-live="polite">
          {toast}
        </div>
      )}
    </div>
  )
}
