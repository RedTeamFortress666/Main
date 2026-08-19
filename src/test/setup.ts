import '@testing-library/jest-dom'
import { afterEach, beforeEach } from 'vitest'

beforeEach(() => {
  localStorage.clear()
})

afterEach(() => {
  localStorage.clear()
})

// jsdom logs a noisy "not implemented" error unless the canvas package is installed.
HTMLCanvasElement.prototype.getContext = () => null
