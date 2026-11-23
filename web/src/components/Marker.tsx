import { onCleanup, Show } from 'solid-js'
import { Icon, PointIcon } from './Icons'
import { getSpriteImage } from '../lib/blipSprites'
import { formatDistance, hexToRgb } from '../lib/format'
import { POINT_STATE_HIDDEN } from '../types'
import type { HorizonPoint } from '../types'

interface MarkerProps {
  point: HorizonPoint
  distance: number | undefined
  focused: boolean
  destination: boolean
  blipImages: boolean
  onMount: (pointId: string, element: HTMLDivElement) => void
  onUnmount: (pointId: string) => void
}

export default function Marker(props: MarkerProps) {
  const pointId = props.point.id

  onCleanup(() => props.onUnmount(pointId))

  return (
    <div
      ref={(element) => props.onMount(pointId, element)}
      class="marker"
      classList={{ focused: props.focused, destination: props.destination }}
      data-state={POINT_STATE_HIDDEN}
      style={{ '--point': hexToRgb(props.point.color) }}
    >
      <div class="marker-icon">
        <PointIcon icon={props.point.icon} spriteImage={props.blipImages ? getSpriteImage(props.point.sprite) : ''} />

        <Show when={props.destination}>
          <span class="marker-check">
            <Icon name="check" />
          </span>
        </Show>
      </div>

      <span class="marker-distance">{formatDistance(props.distance)}</span>
    </div>
  )
}
