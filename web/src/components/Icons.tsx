import { createSignal, Match, Show, Switch } from 'solid-js'
import type { JSX } from 'solid-js'

interface IconProps {
  name: string
}

interface PointIconProps {
  icon: string
  image?: string
  spriteImage?: string
}

function IconFrame(props: { children: JSX.Element }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      {props.children}
    </svg>
  )
}

export function Icon(props: IconProps) {
  return (
    <IconFrame>
      <Switch
        fallback={
          <>
            <path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0" />
            <circle cx="12" cy="10" r="3" />
          </>
        }
      >
        <Match when={props.name === 'store'}>
          <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" />
          <line x1="3" y1="6" x2="21" y2="6" />
          <path d="M16 10a4 4 0 0 1-8 0" />
        </Match>
        <Match when={props.name === 'weapon'}>
          <circle cx="12" cy="12" r="10" />
          <line x1="22" y1="12" x2="18" y2="12" />
          <line x1="6" y1="12" x2="2" y2="12" />
          <line x1="12" y1="6" x2="12" y2="2" />
          <line x1="12" y1="22" x2="12" y2="18" />
        </Match>
        <Match when={props.name === 'car'}>
          <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2" />
          <circle cx="7" cy="17" r="2" />
          <path d="M9 17h6" />
          <circle cx="17" cy="17" r="2" />
        </Match>
        <Match when={props.name === 'garage'}>
          <path d="M3 21V9l9-6 9 6v12" />
          <path d="M7 21v-8h10v8" />
          <line x1="7" y1="17" x2="17" y2="17" />
        </Match>
        <Match when={props.name === 'medical'}>
          <rect x="3" y="3" width="18" height="18" rx="4" />
          <line x1="12" y1="8" x2="12" y2="16" />
          <line x1="8" y1="12" x2="16" y2="12" />
        </Match>
        <Match when={props.name === 'police'}>
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        </Match>
        <Match when={props.name === 'money'}>
          <line x1="12" y1="1" x2="12" y2="23" />
          <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
        </Match>
        <Match when={props.name === 'home'}>
          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
          <polyline points="9 22 9 12 15 12 15 22" />
        </Match>
        <Match when={props.name === 'star'}>
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
        </Match>
        <Match when={props.name === 'flag'}>
          <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
          <line x1="4" y1="22" x2="4" y2="15" />
        </Match>
        <Match when={props.name === 'tool'}>
          <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z" />
        </Match>
        <Match when={props.name === 'user'}>
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </Match>
        <Match when={props.name === 'work'}>
          <rect x="2" y="7" width="20" height="14" rx="2" />
          <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" />
        </Match>
        <Match when={props.name === 'map'}>
          <polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6" />
          <line x1="8" y1="2" x2="8" y2="18" />
          <line x1="16" y1="6" x2="16" y2="22" />
        </Match>
        <Match when={props.name === 'navigation'}>
          <polygon points="3 11 22 2 13 21 11 13 3 11" />
        </Match>
        <Match when={props.name === 'check'}>
          <polyline points="20 6 9 17 4 12" />
        </Match>
      </Switch>
    </IconFrame>
  )
}

export function PointIcon(props: PointIconProps) {
  const [failedImage, setFailedImage] = createSignal('')

  return (
    <Show
      when={props.image && props.image !== failedImage()}
      fallback={
        <Show when={props.spriteImage} fallback={<Icon name={props.icon} />}>
          <span class="sprite-icon" style={{ '-webkit-mask-image': `url(${props.spriteImage})` }}>
            <img src={props.spriteImage} alt="" draggable={false} />
          </span>
        </Show>
      }
    >
      <img src={props.image} alt="" draggable={false} onError={() => setFailedImage(props.image ?? '')} />
    </Show>
  )
}
