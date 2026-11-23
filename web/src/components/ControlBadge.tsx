import { Match, Switch } from 'solid-js'

interface ControlBadgeProps {
  label: string
}

interface MouseIconProps {
  button: 'left' | 'right'
}

const MOUSE_LEFT_LABEL = 'M1'
const MOUSE_RIGHT_LABEL = 'M2'

function MouseIcon(props: MouseIconProps) {
  return (
    <svg class="mouse-icon" viewBox="0 0 24 30" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
      <path class="mouse-button" classList={{ pressed: props.button === 'left' }} d="M12 2.8V12H4.8V10A7.2 7.2 0 0 1 12 2.8Z" />
      <path class="mouse-button" classList={{ pressed: props.button === 'right' }} d="M12 2.8V12H19.2V10A7.2 7.2 0 0 0 12 2.8Z" />
      <rect x="4.8" y="2.8" width="14.4" height="24.4" rx="7.2" />
      <line x1="12" y1="2.8" x2="12" y2="12" />
      <line x1="4.8" y1="12" x2="19.2" y2="12" />
    </svg>
  )
}

export default function ControlBadge(props: ControlBadgeProps) {
  return (
    <Switch fallback={<span class="key-badge">{props.label}</span>}>
      <Match when={props.label === MOUSE_LEFT_LABEL}>
        <MouseIcon button="left" />
      </Match>
      <Match when={props.label === MOUSE_RIGHT_LABEL}>
        <MouseIcon button="right" />
      </Match>
    </Switch>
  )
}
