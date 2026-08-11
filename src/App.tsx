import { useEffect, useState } from 'react'
import { BottomNav } from './components/BottomNav'
import { ATTACK_MODULES, type ModuleId, type NavTab } from './data/modules'
import { CapturesScreen } from './screens/CapturesScreen'
import { HomeScreen } from './screens/HomeScreen'
import { ModuleDetailScreen } from './screens/ModuleDetailScreen'
import { PortalScreen } from './screens/PortalScreen'
import { ScannerScreen } from './screens/ScannerScreen'
import { WifiScreen } from './screens/WifiScreen'
import './App.css'

export default function App() {
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
    setTab(next)
  }

  return (
    <div className="shell">
      <div className="shell__glow" aria-hidden />
      <header className="topbar">
        <div>
          <p className="topbar__brand">GÅMÊ-ØVĒR</p>
          <p className="topbar__sub">Cyber Solutions · Pentest Suite</p>
        </div>
        <div className="topbar__status">
          <span className="topbar__dot" />
          LAB ONLINE
        </div>
      </header>

      <main className="shell__main">
        {moduleId ? (
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
          </>
        )}
      </main>

      <BottomNav active={tab} onChange={changeTab} />

      {toast && (
        <div className="toast" role="status" aria-live="polite">
          {toast}
        </div>
      )}
    </div>
  )
}
