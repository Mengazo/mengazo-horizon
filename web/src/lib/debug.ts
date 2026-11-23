import { isEnvBrowser } from './nui'
import { POINT_STATE_EDGE_LEFT, POINT_STATE_EDGE_RIGHT, POINT_STATE_HIDDEN, POINT_STATE_VISIBLE } from '../types'
import type { FramePoint, HorizonPoint, OpenPayload } from '../types'

interface DebugPoint extends HorizonPoint {
  bearing: number
  elevation: number
  distance: number
}

const DEBUG_OPEN: OpenPayload = {
  theme: '#e83e8c',
  blipImages: true,
  controls: { setDestination: 'M1', viewOnMap: 'M2' },
  texts: {
    markers: 'Markers',
    noMarkers: 'No markers nearby',
    aimHint: 'Aim at a marker to see its details',
    distance: '{distance} away',
    currentDestination: 'Current destination · {distance}',
    viewOnMap: 'View on map',
    setDestination: 'Set destination',
    removeDestination: 'Remove destination',
    decimalSeparator: '.',
  },
}

const DEBUG_POINTS: DebugPoint[] = [
  { id: 'point:mission', label: 'Get another weapon', location: 'Vinewood Blvd · Downtown Vinewood', description: 'Working for Brian takes better gear. Buy a rifle at the nearest gun store.', color: '#e83e8c', icon: 'weapon', image: '', sprite: false, bearing: 4, elevation: 0.47, distance: 193 },
  { id: 'blip:12', label: false, previewLabel: 'Garage', location: 'Alta St · Alta', description: '', color: '#5db6e5', icon: 'pin', image: '', sprite: 357, bearing: -19, elevation: 0.5, distance: 86 },
  { id: 'blip:70', label: false, previewLabel: 'Clothes Store', location: 'Innocence Blvd · Strawberry', description: '', color: '#f0c850', icon: 'pin', image: '', sprite: 366, bearing: -10, elevation: 0.5, distance: 203 },
  { id: 'blip:18',label: false, previewLabel: 'Convenience Store', location: 'Clinton Ave · Vinewood', description: '', color: '#72cc72', icon: 'pin', image: '', sprite: 52, bearing: 27, elevation: 0.44, distance: 412 },
  { id: 'blip:31', label: false, previewLabel: 'Hospital', location: 'Elgin Ave · Pillbox Hill', description: '', color: '#e03232', icon: 'pin', image: '', sprite: 80, bearing: -41, elevation: 0.42, distance: 1340 },
  { id: 'blip:44', label: false, previewLabel: 'Mechanic', location: 'Carson Ave · Burton', description: '', color: '#f0c850', icon: 'pin', image: '', sprite: 402, bearing: 96, elevation: 0.5, distance: 655 },
  { id: 'blip:52', label: false, previewLabel: 'Car Dealer', location: 'Power St · Pillbox Hill', description: '', color: '#c1a9f5', icon: 'pin', image: '', sprite: 225, bearing: -118, elevation: 0.5, distance: 2210 },
  { id: 'blip:60', label: false, previewLabel: 'Police Station', location: 'Sinner St · Mission Row', description: '', color: '#5db6e5', icon: 'pin', image: '', sprite: 60, bearing: 170, elevation: 0.5, distance: 978 },
]

const HORIZONTAL_FIELD_OF_VIEW = 90
const FOCUS_RADIUS = 0.05
const EDGE_SPACING = 0.055
const EDGE_MAX_PER_SIDE = 4
const EDGE_MARGIN = 0.035

function sendDebugMessage(action: string, data: unknown): void {
  window.dispatchEvent(new MessageEvent('message', { data: { action, data } }))
}

function formatRelativeBearing(bearing: number, cameraHeading: number): number {
  return ((((bearing - cameraHeading + 180) % 360) + 360) % 360) - 180
}

export function startDebugPreview(): void {
  if (!isEnvBrowser()) {
    return
  }

  let cameraHeading = 0
  let focusedId: string | false = false
  let destinationId: string | false = false

  document.body.classList.add('browser-preview')

  window.addEventListener('mousemove', (event) => {
    cameraHeading = (event.clientX / window.innerWidth - 0.5) * 240
  })

  window.addEventListener('click', () => {
    if (!focusedId) {
      return
    }

    destinationId = destinationId === focusedId ? false : focusedId
    sendDebugMessage('destination', { id: destinationId })
  })

  const renderFrame = () => {
    const aspectRatio = window.innerWidth / window.innerHeight
    const edgeCounts = { [POINT_STATE_EDGE_LEFT]: 0, [POINT_STATE_EDGE_RIGHT]: 0 }
    let focusedDistance = FOCUS_RADIUS

    focusedId = false

    const framePoints: FramePoint[] = DEBUG_POINTS.map((point) => {
      const relativeBearing = formatRelativeBearing(point.bearing, cameraHeading)

      if (Math.abs(relativeBearing) <= HORIZONTAL_FIELD_OF_VIEW * (0.5 - EDGE_MARGIN)) {
        const screenX = 0.5 + relativeBearing / HORIZONTAL_FIELD_OF_VIEW
        const centerDistance = Math.hypot((screenX - 0.5) * aspectRatio, point.elevation - 0.5)

        if (centerDistance <= focusedDistance) {
          focusedDistance = centerDistance
          focusedId = point.id
        }

        return [point.id, screenX, point.elevation, point.distance, POINT_STATE_VISIBLE]
      }

      const edgeState = relativeBearing < 0 ? POINT_STATE_EDGE_LEFT : POINT_STATE_EDGE_RIGHT

      if (edgeCounts[edgeState] >= EDGE_MAX_PER_SIDE) {
        return [point.id, 0, 0, point.distance, POINT_STATE_HIDDEN]
      }

      edgeCounts[edgeState] += 1

      const screenX = edgeState === POINT_STATE_EDGE_LEFT ? 0.014 : 0.986
      const screenY = 0.5 + (edgeCounts[edgeState] - (EDGE_MAX_PER_SIDE + 1) / 2) * EDGE_SPACING

      return [point.id, screenX, screenY, point.distance, edgeState]
    })

    sendDebugMessage('frame', { focused: focusedId, points: framePoints })
    window.requestAnimationFrame(renderFrame)
  }

  window.setTimeout(() => {
    sendDebugMessage('open', DEBUG_OPEN)
    sendDebugMessage('points', { list: DEBUG_POINTS.map(({ bearing, elevation, distance, ...point }) => point), destination: false })
    window.requestAnimationFrame(renderFrame)
  }, 300)
}
