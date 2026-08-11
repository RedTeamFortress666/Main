import { ModuleIcon, IconArrow } from './Icons'
import type { AttackModule } from '../data/modules'
import './ModuleCard.css'

interface ModuleCardProps {
  module: AttackModule
  onOpen: (id: AttackModule['id']) => void
}

export function ModuleCard({ module, onOpen }: ModuleCardProps) {
  return (
    <button
      type="button"
      className="module-card"
      onClick={() => onOpen(module.id)}
      aria-label={`${module.title}: ${module.description}`}
    >
      <span className="module-card__top">
        <span className="module-card__icon"><ModuleIcon name={module.icon} size={18} /></span>
        <IconArrow className="module-card__arrow" />
      </span>
      <span className="module-card__title">{module.title}</span>
      <span className="module-card__desc">{module.description}</span>
    </button>
  )
}
