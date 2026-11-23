import { createEffect, createSignal, on, onCleanup, onMount, Show } from 'solid-js'
import ControlBadge from './ControlBadge'
import { Icon, PointIcon } from './Icons'
import { getSpriteImage } from '../lib/blipSprites'
import { hexToRgb, withDistance } from '../lib/format'
import { fetchNui, isEnvBrowser } from '../lib/nui'
import type { HorizonControls, HorizonPoint, HorizonTexts, ScreenBounds } from '../types'

interface FocusCardProps {
  point: HorizonPoint
  distance: number | undefined
  destination: boolean
  controls: HorizonControls
  texts: HorizonTexts
  blipImages: boolean
  onTitleSlot: (bounds: ScreenBounds | null) => void
}

const CONFIRMATION_TIME = 450

export default function FocusCard(props: FocusCardProps) {
  let cardElement: HTMLDivElement | undefined
  let slotElement: HTMLDivElement | undefined

  const usesGameTitle = props.point.label === false

  const [destinationConfirmed, setDestinationConfirmed] = createSignal(false)

  let confirmationTimer: number | undefined

  createEffect(
    on(
      () => props.destination,
      () => {
        window.clearTimeout(confirmationTimer)
        setDestinationConfirmed(true)

        confirmationTimer = window.setTimeout(() => setDestinationConfirmed(false), CONFIRMATION_TIME)
      },
      { defer: true },
    ),
  )

  onCleanup(() => {
    window.clearTimeout(confirmationTimer)
    props.onTitleSlot(null)
  })

  onMount(() => {
    if (!usesGameTitle || !cardElement || !slotElement) {
      return
    }

    const cardBounds = cardElement.getBoundingClientRect()
    const slotBounds = slotElement.getBoundingClientRect()

    cardElement.style.setProperty('--slot-left', `${slotBounds.left - cardBounds.left}px`)
    cardElement.style.setProperty('--slot-top', `${slotBounds.top - cardBounds.top}px`)
    cardElement.style.setProperty('--slot-right', `${slotBounds.right - cardBounds.left}px`)
    cardElement.style.setProperty('--slot-bottom', `${slotBounds.bottom - cardBounds.top}px`)

    props.onTitleSlot({
      left: slotBounds.left / window.innerWidth,
      top: slotBounds.top / window.innerHeight,
      right: slotBounds.right / window.innerWidth,
      bottom: slotBounds.bottom / window.innerHeight,
    })

    fetchNui('titleSlot', {
      pointId: props.point.id,
      x: slotBounds.left / window.innerWidth,
      y: slotBounds.top / window.innerHeight,
      width: slotBounds.width / window.innerWidth,
      height: slotBounds.height / window.innerHeight,
    })
  })

  return (
    <div ref={cardElement} class="focus-card" style={{ '--point': hexToRgb(props.point.color) }}>
      <div class="focus-backdrop" classList={{ 'with-slot': usesGameTitle }} />

      <div class="focus-content">
        <div class="focus-head">
          <div class="focus-avatar">
            <PointIcon icon={props.point.icon} image={props.point.image} spriteImage={props.blipImages ? getSpriteImage(props.point.sprite) : ''} />
          </div>

          <div class="focus-title">
            <span class="micro-label">
              <Show when={props.destination} fallback={withDistance(props.texts.distance, props.distance)}>
                {withDistance(props.texts.currentDestination, props.distance)}
              </Show>
            </span>

            <div ref={slotElement} class="focus-title-slot">
              <Show when={!usesGameTitle}>
                <h2>{props.point.label}</h2>
              </Show>

              <Show when={usesGameTitle && isEnvBrowser()}>
                <span class="game-title-preview">{props.point.previewLabel}</span>
              </Show>
            </div>
          </div>
        </div>

        <Show when={props.point.location}>
          <div class="focus-location">
            <Icon name="pin" />
            <span>{props.point.location}</span>
          </div>
        </Show>

        <Show when={props.point.description}>
          <p class="focus-description">{props.point.description}</p>
        </Show>

        <div class="focus-actions">
          <div class="focus-action">
            <ControlBadge label={props.controls.viewOnMap} />
            <Icon name="map" />
            <span>{props.texts.viewOnMap}</span>
          </div>

          <div class="focus-action" classList={{ active: props.destination, confirmed: destinationConfirmed() }}>
            <ControlBadge label={props.controls.setDestination} />
            <Icon name={props.destination ? 'check' : 'navigation'} />
            <span>{props.destination ? props.texts.removeDestination : props.texts.setDestination}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
