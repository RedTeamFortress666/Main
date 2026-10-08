import { ATTACK_MODULES, SAMPLE_ENGAGEMENTS, type ModuleId } from '../data/modules'
import { APP_ORG } from '../auth/operators'
import { IconBolt } from '../components/Icons'
import { LegalBanner } from '../components/LegalBanner'
import { ModuleCard } from '../components/ModuleCard'
import '../components/screens.css'

interface HomeScreenProps {
  onOpenModule: (id: ModuleId) => void
}

export function HomeScreen({ onOpenModule }: HomeScreenProps) {
  return (
    <section className="screen">
      <header className="brand-block">
        <p className="brand-block__eyebrow">{APP_ORG}</p>
        <h1 className="brand-block__title">
          <IconBolt className="brand-block__bolt" /> ATTACK MODULES
        </h1>
        <p className="brand-block__sub">
          GAME ØVER! Red Team Fortress — NetHunter + ESP32 / Bruce bridge.
        </p>
      </header>

      <div className="module-grid">
        {ATTACK_MODULES.map((mod) => (
          <ModuleCard key={mod.id} module={mod} onOpen={onOpenModule} />
        ))}
      </div>

      <div className="section-block">
        <h2 className="section-title">Recent Engagements</h2>
        <ul className="engagement-list">
          {SAMPLE_ENGAGEMENTS.map((eng) => (
            <li key={eng.id} className="engagement-row">
              <div>
                <p className="engagement-row__target">{eng.target}</p>
                <p className="engagement-row__meta">Lab sample · recon report</p>
              </div>
              <div className="engagement-row__tags">
                <span className="tag tag--ok">{eng.status}</span>
                <span className="tag tag--crit">{eng.critical} CRIT</span>
              </div>
            </li>
          ))}
        </ul>
      </div>

      <LegalBanner />
    </section>
  )
}
