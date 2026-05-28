/**
 * main.ts
 *
 * Bootstraps Vuetify and other plugins then mounts the App
 */

// Plugins
import { registerPlugins } from '@/plugins'

// Components
import App from './App.vue'

// Composables
import { createApp } from 'vue'

// Styles
import 'unfonts.css'
import 'leaflet/dist/leaflet.css';
import '@/styles/settings.scss'; // <--- ADICIONADO: Importação dos estilos globais

const app = createApp(App)

registerPlugins(app)

app.mount('#app')
