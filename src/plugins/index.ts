/**
 * plugins/index.ts
 *
 * Automatically included in `./src/main.ts`
 */

// Plugins
import vuetify from './vuetify'
import pinia from '../stores'
import router from '../router'
import { registerApexCharts } from './apexcharts'
import { vTrackArt } from '@/directives/vTrackArt'

// Types
import type { App } from 'vue'

export function registerPlugins (app: App) {
  app
    .use(vuetify)
    .use(router)
    .use(pinia)

  registerApexCharts(app)
  app.directive('track-art', vTrackArt)
}
