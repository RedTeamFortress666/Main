import { useState } from 'react'
import { APP_NAME, APP_ORG, authenticate, type OperatorAccount } from '../auth/operators'
import './LoginScreen.css'

interface LoginScreenProps {
  onLogin: (operator: OperatorAccount) => void
}

export function LoginScreen({ onLogin }: LoginScreenProps) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [shake, setShake] = useState(false)

  function submit(e: React.FormEvent) {
    e.preventDefault()
    const op = authenticate(username, password)
    if (!op) {
      setError('ACCESS DENIED — invalid fortress credentials')
      setShake(true)
      window.setTimeout(() => setShake(false), 450)
      return
    }
    setError(null)
    onLogin(op)
  }

  return (
    <div className={shake ? 'login login--shake' : 'login'}>
      <div className="login__coil" aria-hidden>
        <img src="/icons/tesla-coil-icon.png" alt="" width={96} height={96} />
      </div>
      <p className="login__org">{APP_ORG}</p>
      <h1 className="login__title">{APP_NAME}</h1>
      <p className="login__sub">Authorized operators only · air-gapped vault beyond the gate</p>

      <form className="login__form" onSubmit={submit}>
        <label className="login__field">
          <span>USERNAME</span>
          <input
            autoComplete="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Operator ID"
          />
        </label>
        <label className="login__field">
          <span>PASSWORD</span>
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••••••"
          />
        </label>
        {error && (
          <p className="login__error" role="alert">
            {error}
          </p>
        )}
        <button type="submit" className="login__cta">
          ENTER FORTRESS
        </button>
      </form>

      <p className="login__legal">
        FOR AUTHORIZED SECURITY RESEARCH ONLY. Unauthorized access is prohibited.
      </p>
    </div>
  )
}
