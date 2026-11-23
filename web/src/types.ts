export interface HorizonPoint {
  id: string
  label: string | false
  location: string
  description: string
  color: string
  icon: string
  image: string
  sprite: number | false
  previewLabel?: string
}

export interface HorizonControls {
  setDestination: string
  viewOnMap: string
}

export interface OpenPayload {
  theme: string
  blipImages: boolean
  controls: HorizonControls
}

export interface PointsPayload {
  list: HorizonPoint[]
  destination: string | false
}

export interface DestinationPayload {
  id: string | false
}

export type FramePoint = [id: string, screenX: number, screenY: number, distance: number, state: number]

export interface FramePayload {
  focused: string | false
  points: FramePoint[]
}

export const POINT_STATE_VISIBLE = 0
export const POINT_STATE_EDGE_LEFT = 1
export const POINT_STATE_EDGE_RIGHT = 2
export const POINT_STATE_HIDDEN = 3
export const POINT_STATE_COVERED = 4

export interface ScreenBounds {
  left: number
  top: number
  right: number
  bottom: number
}
