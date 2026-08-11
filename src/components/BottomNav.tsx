import type { NavTab } from '../data/modules'
import { IconGlobe, IconGrid, IconKey, IconShield, IconWifi } from './Icons'
import './BottomNav.css'

const TABS: { id: NavTab; label: string; Icon: typeof IconGrid }[] = [
  { id: 'home', label: 'Home', Icon: IconGrid },
  { id: 'scanner', label: 'Scanner', Icon: IconShield },
  { id: 'portal', label: 'Portal', Icon: IconGlobe },
  { id: 'captures', label: 'Captures', Icon: IconKey },
  { id: 'wifi', label: 'WiFi', Icon: IconWifi },
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
            <Icon size={20} />
            <span>{label}</span>
          </button>
        )
      })}
    </nav>
  )
}
