import { onCleanup } from 'solid-js'

export interface NuiMessage<T = unknown> {
  action: string
  data: T
}

export const isEnvBrowser = (): boolean => !(window as any).invokeNative

export function getResourceName(): string {
  const host = window as any

  return typeof host.GetParentResourceName === 'function' ? host.GetParentResourceName() : 'mengazo-horizon'
}

export async function fetchNui<T = unknown>(event: string, data: unknown = {}, mockData?: T): Promise<T | null> {
  if (isEnvBrowser()) {
    console.log(`[nui] ${event}`, data)
    return mockData ?? null
  }

  try {
    const response = await fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })

    return (await response.json()) as T
  } catch (error) {
    console.error(`[nui] ${event} failed`, error)
    return null
  }
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void): void {
  const listener = (event: MessageEvent<NuiMessage<T>>) => {
    if (event.data && event.data.action === action) {
      handler(event.data.data)
    }
  }

  window.addEventListener('message', listener)
  onCleanup(() => window.removeEventListener('message', listener))
}

export function dispatchDebugMessages(events: NuiMessage[], timer = 500): void {
  if (!isEnvBrowser()) {
    return
  }

  events.forEach((event, index) => {
    setTimeout(() => {
      window.dispatchEvent(new MessageEvent('message', { data: event }))
    }, timer * (index + 1))
  })
}
