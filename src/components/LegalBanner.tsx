import type { ReactNode } from 'react'
import './LegalBanner.css'

export function LegalBanner({ children }: { children?: ReactNode }) {
  return (
    <aside className="legal-banner" role="note">
      {children ?? (
        <>
          FOR AUTHORIZED SECURITY RESEARCH ONLY. Unauthorized use may violate
          computer crime laws. Obtain explicit written permission before testing.
        </>
      )}
    </aside>
  )
}
