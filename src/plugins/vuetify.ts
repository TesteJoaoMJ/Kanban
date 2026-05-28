/**
 * plugins/vuetify.ts
 * Framework documentation: https://vuetifyjs.com
 */
import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import { VForm } from 'vuetify/components/VForm'
import { dateAdapter } from './date-adapter'

export default createVuetify({
  date: {
    adapter: dateAdapter,
  },
  theme: {
    defaultTheme: 'dark',
    themes: {
      // Configuração EXPLÍCITA do modo Light "Raiz"
      light: {
        dark: false,
        colors: {
          background: '#F4F5FA', // Fundo cinza escritório (Enterprise Standard)
          surface: '#FFFFFF',    // Paineis brancos puros
          'surface-variant': '#F4F5FA',
          primary: '#1976D2',    // Azul corporativo
          secondary: '#424242',
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
        }
      },
      // Configuração do modo Dark/Glass
      dark: {
        dark: true,
        colors: {
          background: '#121212',
          surface: '#1E1E1E',
          primary: '#2196F3',
        }
      }
    }
  },
  components: {
    VForm,
  },
})
