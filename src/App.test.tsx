import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import App from './App'

describe('App', () => {
  it('renders the empty state', () => {
    render(<App />)
    expect(
      screen.getByText(/add your first task/i),
    ).toBeInTheDocument()
  })

  it('adds a task and updates the counter', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.type(screen.getByLabelText(/new task/i), 'Buy milk')
    await user.click(screen.getByRole('button', { name: /add/i }))

    expect(screen.getByText('Buy milk')).toBeInTheDocument()
    expect(screen.getByText(/1 of 1 remaining/i)).toBeInTheDocument()
  })

  it('toggles a task as done', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.type(screen.getByLabelText(/new task/i), 'Write tests')
    await user.click(screen.getByRole('button', { name: /add/i }))
    await user.click(screen.getByRole('checkbox'))

    expect(screen.getByText(/0 of 1 remaining/i)).toBeInTheDocument()
  })

  it('deletes a task', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.type(screen.getByLabelText(/new task/i), 'Temporary')
    await user.click(screen.getByRole('button', { name: /add/i }))
    await user.click(screen.getByRole('button', { name: /delete temporary/i }))

    expect(screen.queryByText('Temporary')).not.toBeInTheDocument()
  })
})
