import { useCallback, useMemo, useState } from 'react'
import './App.css'

interface Task {
  id: number
  text: string
  done: boolean
}

const STORAGE_KEY = 'first-app.tasks'

function loadTasks(): Task[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as Task[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

function nextTaskId(tasks: Task[]) {
  return tasks.reduce((max, task) => Math.max(max, task.id), 0) + 1
}

export default function App() {
  const [tasks, setTasks] = useState<Task[]>(() => loadTasks())
  const [draft, setDraft] = useState('')
  const [persistError, setPersistError] = useState(false)

  const remaining = useMemo(
    () => tasks.filter((t) => !t.done).length,
    [tasks],
  )

  const commit = useCallback((next: Task[]) => {
    setTasks(next)
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next))
      setPersistError(false)
    } catch {
      setPersistError(true)
    }
  }, [])

  function addTask() {
    const text = draft.trim()
    if (!text) return
    commit([{ id: nextTaskId(tasks), text, done: false }, ...tasks])
    setDraft('')
  }

  function toggleTask(id: number) {
    commit(tasks.map((t) => (t.id === id ? { ...t, done: !t.done } : t)))
  }

  function removeTask(id: number) {
    commit(tasks.filter((t) => t.id !== id))
  }

  return (
    <main className="app">
      <header className="app__header">
        <h1>My Tasks</h1>
        <p className="app__subtitle">
          {tasks.length === 0
            ? 'Nothing here yet — add your first task.'
            : `${remaining} of ${tasks.length} remaining`}
        </p>
      </header>

      {persistError && (
        <p className="app__error" role="alert">
          Couldn’t save your tasks — changes may be lost when you close the page.
        </p>
      )}

      <form
        className="composer"
        onSubmit={(e) => {
          e.preventDefault()
          addTask()
        }}
      >
        <input
          className="composer__input"
          aria-label="New task"
          placeholder="What needs to be done?"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        />
        <button className="composer__button" type="submit">
          Add
        </button>
      </form>

      <ul className="task-list">
        {tasks.map((task) => (
          <li key={task.id} className="task">
            <label className="task__label">
              <input
                type="checkbox"
                checked={task.done}
                onChange={() => toggleTask(task.id)}
              />
              <span className={task.done ? 'task__text task__text--done' : 'task__text'}>
                {task.text}
              </span>
            </label>
            <button
              className="task__delete"
              aria-label={`Delete ${task.text}`}
              onClick={() => removeTask(task.id)}
            >
              ×
            </button>
          </li>
        ))}
      </ul>
    </main>
  )
}
