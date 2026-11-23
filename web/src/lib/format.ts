const DEFAULT_RGB = '255, 255, 255'

export function hexToRgb(color: string | undefined, fallback = DEFAULT_RGB): string {
  const match = /^#?([0-9a-f]{6})$/i.exec(color ?? '')

  if (!match) {
    return fallback
  }

  const value = match[1]

  return [0, 2, 4].map((offset) => parseInt(value.slice(offset, offset + 2), 16)).join(', ')
}

let decimalSeparator = '.'

/** Decimal separator of the language picked in config/lang.lua. */
export function setDecimalSeparator(separator: string | undefined): void {
  decimalSeparator = separator || '.'
}

export function formatDistance(meters: number | undefined): string {
  if (meters === undefined) {
    return ''
  }

  if (meters < 1000) {
    return `${Math.round(meters)} m`
  }

  return `${(meters / 1000).toFixed(1).replace('.', decimalSeparator)} km`
}

/** Puts the formatted distance in a text from config/lang.lua, in place of {distance}. */
export function withDistance(text: string, meters: number | undefined): string {
  return text.replace('{distance}', formatDistance(meters))
}
