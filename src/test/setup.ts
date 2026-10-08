import '@testing-library/jest-dom'
import { afterEach, beforeEach } from 'vitest'

beforeEach(() => {
  if (typeof localStorage !== 'undefined') localStorage.clear()
})

afterEach(() => {
  if (typeof localStorage !== 'undefined') localStorage.clear()
})
