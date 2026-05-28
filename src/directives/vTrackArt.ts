import type { DirectiveBinding, ObjectDirective } from 'vue'
import { useProtectionStore } from '@/stores/protectionStore'

const trackingMap = new WeakMap<HTMLElement, {
  observer: IntersectionObserver,
  artId: string,
  enterTime: number | null
}>()

export const vTrackArt: ObjectDirective<HTMLElement, string> = {
  mounted(el: HTMLElement, binding: DirectiveBinding<string>) {
    const artId = binding.value
    if (!artId) return

    const store = useProtectionStore()

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        const data = trackingMap.get(el)
        if (!data) return

        if (entry.isIntersecting) {
          data.enterTime = Date.now()
          // LOG: Descomente se quiser ver o exato milissegundo que a arte entra na tela
          // console.log(`[Sensor] Arte ${data.artId} ENTROU na tela.`);
        } else {
          if (data.enterTime) {
            const visibleDurationMs = Date.now() - data.enterTime

            if (visibleDurationMs >= 30) {
              console.log(`[Sensor] Arte ${data.artId} FICOU VISÍVEL por ${visibleDurationMs}ms.`);
              store.logExposure(data.artId, visibleDurationMs)
            } else {
              console.warn(`[Sensor] Arte ${data.artId} ignorada (MUITO RÁPIDO: ${visibleDurationMs}ms)`);
            }
            data.enterTime = null
          }
        }
      })
    }, {
      threshold: 0.15
    })

    trackingMap.set(el, {
      observer,
      artId,
      enterTime: null
    })

    observer.observe(el)
  },

  updated(el: HTMLElement, binding: DirectiveBinding<string>) {
    const data = trackingMap.get(el)
    if (data && data.artId !== binding.value) {
      if (data.enterTime) {
        const store = useProtectionStore()
        const visibleDurationMs = Date.now() - data.enterTime
        if (visibleDurationMs >= 30) {
          console.log(`[Sensor] Arte atualizada (Saiu ${data.artId}): ${visibleDurationMs}ms`);
          store.logExposure(data.artId, visibleDurationMs)
        }
      }
      data.artId = binding.value
      data.enterTime = null
    }
  },

  unmounted(el: HTMLElement) {
    const data = trackingMap.get(el)
    if (data) {
      if (data.enterTime) {
        const store = useProtectionStore()
        const visibleDurationMs = Date.now() - data.enterTime
        if (visibleDurationMs >= 30) {
          console.log(`[Sensor] Arte desmontada (${data.artId}): ${visibleDurationMs}ms`);
          store.logExposure(data.artId, visibleDurationMs)
        }
      }
      data.observer.disconnect()
      trackingMap.delete(el)
    }
  }
}
