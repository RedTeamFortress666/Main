import { useMemo, useState } from 'react'
import {
  verifyVaultCode,
  type OperatorAccount,
} from '../auth/operators'
import './VaultScreen.css'

interface VaultScreenProps {
  operator: OperatorAccount
  unlocked: boolean
  onUnlock: () => void
  onEnterAir: () => void
  toast: (msg: string) => void
}

export function VaultScreen({
  operator,
  unlocked,
  onUnlock,
  onEnterAir,
  toast,
}: VaultScreenProps) {
  const [code, setCode] = useState('')
  const [fail, setFail] = useState(false)

  const hint = useMemo(() => {
    if (operator.id === 'gameon') return 'Fortress Lead vault — Batcave clearance'
    return 'Operator vault — Batcave clearance'
  }, [operator.id])

  function tryUnlock(e: React.FormEvent) {
    e.preventDefault()
    if (verifyVaultCode(operator, code)) {
      setFail(false)
      onUnlock()
      toast('Batcave vault unlocked')
      return
    }
    setFail(true)
    toast('Vault rejected code')
  }

  if (!unlocked) {
    return (
      <section className="vault vault--locked screen">
        <div className="vault__cave" aria-hidden>
          <div className="vault__stalactites" />
          <svg className="vault__bat" width="28" height="28" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
            <path d="M12 14c1.2-2.2 3.8-4.2 7-4.5-1.4 1.8-1.6 3.6-1 5.2 1.8.2 3.2 1.2 4 2.8-2.4-.4-4.2.2-5.6 1.8-.8-1.2-2-2-3.4-2.3v2.5h-2v-2.5c-1.4.3-2.6 1.1-3.4 2.3-1.4-1.6-3.2-2.2-5.6-1.8.8-1.6 2.2-2.6 4-2.8.6-1.6.4-3.4-1-5.2 3.2.3 5.8 2.3 7 4.5z" />
          </svg>
        </div>
        <header className="screen-header">
          <div>
            <h1 className="screen-title">BATCAVE VAULT</h1>
            <p className="screen-sub">{hint}</p>
          </div>
          <span className="badge badge--warn">SEALED</span>
        </header>

        <div className="vault__gate panel">
          <h2 className="panel__label">ENTER UNLOCK CODE</h2>
          <p className="panel__copy">
            Offline AIR models (Gemma abliterated / Heretic / local GGUF) live behind this
            gate. Code is bound to operator <strong className="neon">{operator.displayName}</strong>.
          </p>
          <form onSubmit={tryUnlock} className="vault__form">
            <label className="field">
              <span className="field__label">VAULT CODE</span>
              <input
                className={fail ? 'field__input field__input--bad' : 'field__input'}
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="XX-XX-XR"
                autoComplete="off"
                spellCheck={false}
              />
            </label>
            <button type="submit" className="cta">
              OPEN BATCAVE
            </button>
          </form>
        </div>
      </section>
    )
  }

  return (
    <section className="vault vault--open screen">
      <div className="vault__cave vault__cave--open" aria-hidden>
        <div className="vault__stalactites" />
        <svg className="vault__bat vault__bat--fly" width="28" height="28" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
          <path d="M12 14c1.2-2.2 3.8-4.2 7-4.5-1.4 1.8-1.6 3.6-1 5.2 1.8.2 3.2 1.2 4 2.8-2.4-.4-4.2.2-5.6 1.8-.8-1.2-2-2-3.4-2.3v2.5h-2v-2.5c-1.4.3-2.6 1.1-3.4 2.3-1.4-1.6-3.2-2.2-5.6-1.8.8-1.6 2.2-2.6 4-2.8.6-1.6.4-3.4-1-5.2 3.2.3 5.8 2.3 7 4.5z" />
        </svg>
      </div>
      <header className="screen-header">
        <div>
          <h1 className="screen-title">BATCAVE VAULT</h1>
          <p className="screen-sub">Clearance granted · {operator.displayName}</p>
        </div>
        <span className="device-pill">AIR READY</span>
      </header>

      <div className="panel">
        <h2 className="panel__label">OFFLINE AIR CHAMBER</h2>
        <p className="panel__copy">
          Talk to a local / air-gapped LLM endpoint — Ollama, LM Studio, llama.cpp, or
          on-device GGUF (Gemma abliterated, Heretic, etc.). Nothing leaves the fortress
          unless you point it at a remote URL.
        </p>
        <dl className="kv">
          <div><dt>Operator</dt><dd>{operator.displayName}</dd></div>
          <div><dt>Role</dt><dd>{operator.role}</dd></div>
          <div><dt>Mode</dt><dd className="neon">LOCAL / AIR-GAP</dd></div>
        </dl>
        <button type="button" className="cta" onClick={onEnterAir}>
          ENTER AIR CONSOLE
        </button>
      </div>
    </section>
  )
}
