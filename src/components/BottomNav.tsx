import type { NavTab } from '../data/modules'
import { IconGlobe, IconGrid, IconKey, IconShield, IconWifi } from './Icons'
import './BottomNav.css'

function IconVault({ className, size = 22 }: { className?: string; size?: number }) {
  return (
    <svg className={className} width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M5 11h14v9H5v-9zM8 11V8a4 4 0 018 0v3"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="15.5" r="1.4" fill="currentColor" />
    </svg>
  )
}

const TABS: { id: NavTab; label: string; Icon: typeof IconGrid }[] = [
  { id: 'home', label: 'Home', Icon: IconGrid },
  { id: 'scanner', label: 'Scanner', Icon: IconShield },
  { id: 'portal', label: 'Portal', Icon: IconGlobe },
  { id: 'captures', label: 'Captures', Icon: IconKey },
  { id: 'wifi', label: 'WiFi', Icon: IconWifi },
  { id: 'vault', label: 'Vault', Icon: IconVault },
]

interface BottomNavProps {
  active: NavTab
  onChange: (tab: NavTab) => void
}

export function BottomNav({ active, onChange }: BottomNavProps) {
  return (
    <nav className="bottom-nav" aria-label="Primary">
      {TABS.map(({ id, label, Icon }) => {
        const isActive = active === id
        return (
          <button
            key={id}
            type="button"
            className={isActive ? 'bottom-nav__item is-active' : 'bottom-nav__item'}
            aria-current={isActive ? 'page' : undefined}
            onClick={() => onChange(id)}
          >
            <Icon size={18} />
            <span>{label}</span>
          </button>
        )
      })}
    </nav>
  )
}
