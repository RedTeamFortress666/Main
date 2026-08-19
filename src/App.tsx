import { lazy, Suspense, useState } from 'react'
import './App.css'
import './qr/qr.css'
import { TaskList } from './TaskList'

const TransferPanel = lazy(() =>
  import('./qr/TransferPanel').then((module) => ({ default: module.TransferPanel })),
)

type AppView = 'tasks' | 'transfer'

export default function App() {
  const [view, setView] = useState<AppView>('tasks')

  return (
    <div className="app-shell">
      <nav className="app-nav" aria-label="Primary">
        <button
          type="button"
          aria-current={view === 'tasks' ? 'page' : undefined}
          onClick={() => setView('tasks')}
        >
          Tasks
        </button>
        <button
          type="button"
          aria-current={view === 'transfer' ? 'page' : undefined}
          onClick={() => setView('transfer')}
        >
          QR Transfer
        </button>
      </nav>
      {view === 'tasks' ? (
        <main className="app">
          <TaskList />
        </main>
      ) : (
        <main className="app app--transfer">
          <Suspense fallback={<p className="app__subtitle">Loading QR transfer…</p>}>
            <TransferPanel />
          </Suspense>
        </main>
      )}
    </div>
  )
}
