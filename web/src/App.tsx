import { createMemo, createSignal, For, Show } from 'solid-js'
import { createStore, reconcile } from 'solid-js/store'
import FocusCard from './components/FocusCard'
import Marker from './components/Marker'
import { hexToRgb, setDecimalSeparator } from './lib/format'
import { useNuiEvent } from './lib/nui'
import { POINT_STATE_COVERED, POINT_STATE_VISIBLE } from './types'
import type { DestinationPayload, FramePayload, HorizonPoint, OpenPayload, PointsPayload, ScreenBounds } from './types'

const ROOT_FONT_RATIO = 0.014815
const COVER_MARGIN_SIDE = 1.6
const COVER_MARGIN_TOP = 2.9

const DEFAULT_SETTINGS: OpenPayload = {
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

export default function App() {
  const [visible, setVisible] = createSignal(false)
  const [settings, setSettings] = createSignal<OpenPayload>(DEFAULT_SETTINGS)
  const [focusedId, setFocusedId] = createSignal<string | null>(null)
  const [destinationId, setDestinationId] = createSignal<string | null>(null)
  const [pointStore, setPointStore] = createStore<{ list: HorizonPoint[] }>({ list: [] })
  const [distances, setDistances] = createStore<Record<string, number>>({})

  const markerElements = new Map<string, HTMLDivElement>()

  let titleSlotBounds: ScreenBounds | null = null

  const focusedPoint = createMemo(() => pointStore.list.find((point) => point.id === focusedId()))

  const applyTheme = (color: string) => {
    document.documentElement.style.setProperty('--main', hexToRgb(color, '232, 62, 140'))
  }

  const setTitleSlotBounds = (bounds: ScreenBounds | null) => {
    if (!bounds) {
      titleSlotBounds = null

      return
    }

    const remHeight = ROOT_FONT_RATIO
    const remWidth = (ROOT_FONT_RATIO * window.innerHeight) / window.innerWidth

    titleSlotBounds = {
      left: bounds.left - remWidth * COVER_MARGIN_SIDE,
      top: bounds.top - remHeight * COVER_MARGIN_TOP,
      right: bounds.right + remWidth * COVER_MARGIN_SIDE,
      bottom: bounds.bottom + remHeight * COVER_MARGIN_SIDE,
    }
  }

  const isCoveredByTitle = (pointId: string, screenX: number, screenY: number, state: number, focused: string | false) => {
    if (!titleSlotBounds || state !== POINT_STATE_VISIBLE || pointId === focused) {
      return false
    }

    return screenX > titleSlotBounds.left && screenX < titleSlotBounds.right && screenY > titleSlotBounds.top && screenY < titleSlotBounds.bottom
  }

  const registerMarker =(pointId: string, element: HTMLDivElement) => {
    markerElements.set(pointId, element)
  }

  const unregisterMarker = (pointId: string) => {
    markerElements.delete(pointId)
  }

  useNuiEvent<OpenPayload>('open', (payload) => {
    const nextSettings = {
      ...DEFAULT_SETTINGS,
      ...payload,
      controls: { ...DEFAULT_SETTINGS.controls, ...payload?.controls },
      texts: { ...DEFAULT_SETTINGS.texts, ...payload?.texts },
    }

    applyTheme(nextSettings.theme)
    setDecimalSeparator(nextSettings.texts.decimalSeparator)
    setSettings(nextSettings)
    setFocusedId(null)
    setVisible(true)
  })

  useNuiEvent<PointsPayload>('points', (payload) => {
    const pointList = Array.isArray(payload?.list) ? payload.list : []

    setPointStore('list', reconcile(pointList, { key: 'id' }))
    setDestinationId(payload?.destination || null)
  })

  useNuiEvent<FramePayload>('frame', (frame) => {
    const framePoints = Array.isArray(frame?.points) ? frame.points : []

    for (const [pointId, screenX, screenY, distance, state] of framePoints) {
      const element = markerElements.get(pointId)

      if (!element) {
        continue
      }

      const nextState = String(isCoveredByTitle(pointId, screenX, screenY, state, frame.focused) ? POINT_STATE_COVERED : state)

      element.style.transform = `translate3d(${(screenX * 100).toFixed(3)}vw, ${(screenY * 100).toFixed(3)}vh, 0)`

      if (element.dataset.state !== nextState) {
        element.dataset.state = nextState
      }

      if (distances[pointId] !== distance) {
        setDistances(pointId, distance)
      }
    }

    setFocusedId(frame?.focused || null)
  })

  useNuiEvent<DestinationPayload>('destination', (payload) => {
    setDestinationId(payload?.id || null)
  })

  useNuiEvent('close', () => {
    setVisible(false)
    setFocusedId(null)
    setPointStore('list', [])
  })

  return (
    <Show when={visible()}>
      <div class="horizon">
        <div class="veil" />

        <For each={pointStore.list}>
          {(point) => (
            <Marker
              point={point}
              distance={distances[point.id]}
              focused={focusedId() === point.id}
              destination={destinationId() === point.id}
              blipImages={settings().blipImages}
              onMount={registerMarker}
              onUnmount={unregisterMarker}
            />
          )}
        </For>

        <div class="reticle" classList={{ locked: focusedId() !== null }} />

        <Show when={focusedPoint()} keyed>
          {(point) => (
            <FocusCard point={point} distance={distances[point.id]} destination={destinationId() === point.id} controls={settings().controls} texts={settings().texts} blipImages={settings().blipImages} onTitleSlot={setTitleSlotBounds} />
          )}
        </Show>

        <div class="legend">
          <span class="micro-label">{settings().texts.markers}</span>
          <span class="legend-count">{pointStore.list.length}</span>
        </div>

        <Show when={pointStore.list.length === 0}>
          <div class="empty-hint">{settings().texts.noMarkers}</div>
        </Show>

        <Show when={pointStore.list.length > 0 && focusedId() === null}>
          <div class="empty-hint">{settings().texts.aimHint}</div>
        </Show>
      </div>
    </Show>
  )
}
