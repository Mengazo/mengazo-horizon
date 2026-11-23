import { render } from 'solid-js/web'
import './index.css'
import App from './App'
import { startDebugPreview } from './lib/debug'

render(() => <App />, document.getElementById('root') as HTMLElement)

startDebugPreview()
