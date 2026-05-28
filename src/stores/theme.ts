import { defineStore } from 'pinia'
import { useTheme } from 'vuetify'
import { ref } from 'vue'

export const useThemeStore = defineStore('theme', () => {
  const theme = useTheme()

  // 1. Inicia como 'light' para evitar flash de conteúdo escuro/glass
  const currentMode = ref<'glass' | 'light' | 'dark'>('light')

  function setMode(mode: 'glass' | 'light' | 'dark') {
    currentMode.value = mode

    // Aplica no HTML e Body para garantir que o CSS global (Tailwind/SCSS) pegue o tema
    document.documentElement.setAttribute('data-style-mode', mode)
    document.body.setAttribute('data-style-mode', mode)

    // Define o tema base do Vuetify
    // O modo 'glass' e 'dark' usam a base 'dark' do Vuetify
    // O modo 'light' usa a base 'light'
    theme.global.name.value = mode === 'light' ? 'light' : 'dark'

    localStorage.setItem('mjprocess-theme-mode', mode)
  }

  function init() {
    const saved = localStorage.getItem('mjprocess-theme-mode') as 'glass' | 'light' | 'dark' | null

    if (saved) {
      setMode(saved)
    } else {
      // 2. Se não houver nada salvo, força o padrão ser Light
      setMode('light')
    }
  }

  return { currentMode, setMode, init }
})
