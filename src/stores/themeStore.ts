import { ref } from 'vue'
import { defineStore } from 'pinia'
import { useTheme } from 'vuetify'

export const useThemeStore = defineStore('themeStore', () => {
  const theme = useTheme()

  // Define os modos aceitos
  const currentMode = ref<'light' | 'dark' | 'glass'>('light')

  function setMode(newMode: 'light' | 'dark' | 'glass') {
    currentMode.value = newMode

    // Atualiza o tema do Vuetify
    // 'glass' usa a base 'dark' no Vuetify
    const vuetifyTheme = newMode === 'light' ? 'light' : 'dark'
    theme.global.name.value = vuetifyTheme

    // Atributo para CSS global (controla o background glass/solid)
    const styleMode = newMode === 'glass' ? 'glass' : 'solid'
    document.body.setAttribute('data-style-mode', styleMode)

    // Salva na persistência
    localStorage.setItem('theme-mode', newMode)
  }

  function initTheme() {
    const saved = localStorage.getItem('theme-mode') as 'light' | 'dark' | 'glass' | null
    if (saved && ['light', 'dark', 'glass'].includes(saved)) {
      setMode(saved)
    } else {
      setMode('light') // Padrão se não houver salvo
    }
  }

  return { currentMode, setMode, initTheme }
})
