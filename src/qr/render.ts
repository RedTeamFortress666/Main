import jsQR from 'jsqr'
import { encode, renderSVG } from 'uqr'

export interface QrRenderOptions {
  cssSize?: number
  ecc?: 'L' | 'M' | 'Q' | 'H'
  border?: number
}

const DEFAULTS = {
  cssSize: 280,
  ecc: 'M' as const,
  border: 2,
}

export function renderQrSvg(text: string, options: QrRenderOptions = {}): string {
  return renderSVG(text, {
    ecc: options.ecc ?? DEFAULTS.ecc,
    border: options.border ?? DEFAULTS.border,
    pixelSize: 4,
    blackColor: '#000000',
    whiteColor: '#FFFFFF',
  })
}

export function renderQrToCanvas(
  canvas: HTMLCanvasElement,
  text: string,
  options: QrRenderOptions = {},
): boolean {
  try {
    const ctx = canvas.getContext('2d')
    if (!ctx) return false

    const qr = encode(text, {
      ecc: options.ecc ?? DEFAULTS.ecc,
      border: options.border ?? DEFAULTS.border,
    })
    const cssSize = options.cssSize ?? DEFAULTS.cssSize
    const scale = Math.max(2, Math.floor(cssSize / qr.size) || 2)
    const px = qr.size * scale

    canvas.width = px
    canvas.height = px
    canvas.style.width = `${cssSize}px`
    canvas.style.height = `${cssSize}px`

    ctx.fillStyle = '#FFFFFF'
    ctx.fillRect(0, 0, px, px)
    ctx.fillStyle = '#000000'
    for (let y = 0; y < qr.size; y++) {
      for (let x = 0; x < qr.size; x++) {
        if (qr.data[y][x]) {
          ctx.fillRect(x * scale, y * scale, scale, scale)
        }
      }
    }
    return true
  } catch {
    return false
  }
}

export function decodeQrFromCanvas(canvas: HTMLCanvasElement): string | null {
  try {
    const ctx = canvas.getContext('2d')
    if (!ctx || canvas.width === 0 || canvas.height === 0) return null
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    const result = jsQR(imageData.data, imageData.width, imageData.height, {
      inversionAttempts: 'dontInvert',
    })
    return result?.data ?? null
  } catch {
    return null
  }
}
