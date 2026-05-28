import { ref, reactive } from 'vue'
import jsPDF from 'jspdf'
import JsBarcode from 'jsbarcode'

export interface LabelFilters {
  hue?: number
  saturation?: number
  brightness?: number
  contrast?: number
}

export interface LabelElement {
  id: string
  label: string
  type: 'text' | 'barcode' | 'image'
  x: number
  y: number
  width?: number
  height?: number
  fontSize?: number
  fontFamily?: string
  bold?: boolean
  italic?: boolean
  visible: boolean
  showNum?: boolean
  color: string
  src?: string
  opacity: number
  rotation?: number
  folderId?: string | null
  filters?: LabelFilters
  locked?: boolean
}

export interface Folder {
  id: string
  label: string
  visible: boolean
  collapsed: boolean
}

export function useLabelStudio(initialElements: LabelElement[]) {
  const zoom = ref(6)
  const activeElementId = ref<string | null>(null)
  const elements = ref<LabelElement[]>(JSON.parse(JSON.stringify(initialElements)).map((e: any) => ({
    ...e,
    opacity: e.opacity ?? 1,
    rotation: e.rotation ?? 0,
    folderId: e.folderId ?? null,
    filters: e.filters ?? { hue: 0, saturation: 100, brightness: 100, contrast: 100 }
  })))
  const folders = ref<Folder[]>([])

  const pdfUrl = ref<string | null>(null)
  const isGenerating = ref(false)

  const snappingEnabled = ref(true)
  const showGrid = ref(true)
  const showPdfGrid = ref(true) // Ativado por padrão para facilitar a visualização centralizada
  const activeGuides = reactive({ x: [] as number[], y: [] as number[] })

  const draggingElement = ref<LabelElement | null>(null)
  const resizingElement = ref<LabelElement | null>(null)
  const resizeHandle = ref<string | null>(null)
  const dragOffset = reactive({ x: 0, y: 0 })
  const startDims = reactive({ x: 0, y: 0, w: 0, h: 0 })

  const processImageWithBackgroundRemoval = (file: File): Promise<string> => {
    return new Promise((resolve) => {
        const reader = new FileReader()
        reader.onload = (e) => {
            const img = new Image()
            img.onload = () => {
                const canvas = document.createElement('canvas')
                canvas.width = img.width
                canvas.height = img.height
                const ctx = canvas.getContext('2d')
                if (!ctx) return resolve(e.target?.result as string)

                ctx.drawImage(img, 0, 0)
                const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height)
                const data = imgData.data

                for (let i = 0; i < data.length; i += 4) {
                    const r = data[i], g = data[i + 1], b = data[i + 2]
                    if (r > 240 && g > 240 && b > 240) {
                        data[i + 3] = 0
                    }
                }

                ctx.putImageData(imgData, 0, 0)
                resolve(canvas.toDataURL('image/png'))
            }
            img.src = e.target?.result as string
        }
        reader.readAsDataURL(file)
    })
  }

  const addImage = async (file: File, removeBackground: boolean = false) => {
    let src = removeBackground ? await processImageWithBackgroundRemoval(file) : await new Promise<string>((resolve) => {
        const reader = new FileReader()
        reader.onload = (e) => resolve(e.target?.result as string)
        reader.readAsDataURL(file)
    })

    if (src) {
        const id = `img_${Date.now()}`
        elements.value.push({
            id, label: 'Imagem', type: 'image', x: 5, y: 5, width: 20, height: 20,
            visible: true, color: '#000000', opacity: 1, rotation: 0, src, folderId: null
        })
        activeElementId.value = id
    }
  }

  const addText = () => {
      const id = `txt_${Date.now()}`
      elements.value.push({
          id, label: 'Novo Texto', type: 'text', x: 2, y: 2, fontSize: 8, visible: true,
          color: '#000000', opacity: 1, fontFamily: 'helvetica', bold: false, italic: false,
          rotation: 0, folderId: null
      })
      activeElementId.value = id
  }

  const addBarcode = () => {
      const id = `bar_${Date.now()}`
      elements.value.push({
          id, label: 'Código de Barras', type: 'barcode', x: 2, y: 15, width: 30, height: 10,
          visible: true, showNum: true, color: '#000000', opacity: 1, rotation: 0, folderId: null
      })
      activeElementId.value = id
  }

  const duplicateElement = (id: string) => {
    const original = elements.value.find(e => e.id === id)
    if (original) {
      const copy = JSON.parse(JSON.stringify(original))
      copy.id = `${original.type}_${Date.now()}`
      copy.x += 2; copy.y += 2; copy.label += ' (Cópia)'
      elements.value.push(copy)
      activeElementId.value = copy.id
    }
  }

  const deleteElement = (id: string) => {
    elements.value = elements.value.filter(e => e.id !== id)
    if (activeElementId.value === id) activeElementId.value = null
  }

  const createFolder = (name: string) => {
      const id = `folder_${Date.now()}`
      folders.value.push({ id, label: name, visible: true, collapsed: false })
      return id
  }

  const deleteFolder = (id: string) => {
      elements.value.forEach(el => { if(el.folderId === id) el.folderId = null })
      folders.value = folders.value.filter(f => f.id !== id)
  }

  const addToFolder = (elementId: string, folderId: string) => {
      const el = elements.value.find(e => e.id === elementId)
      if (el) el.folderId = folderId
  }

  const moveLayer = (fromIndex: number, toIndex: number) => {
    if (toIndex < 0 || toIndex >= elements.value.length) return
    const item = elements.value[fromIndex]
    const newArr = elements.value.filter((_, i) => i !== fromIndex)
    newArr.splice(toIndex, 0, item)
    elements.value = newArr
  }

  const bringForward = (id: string) => {
      const idx = elements.value.findIndex(e => e.id === id)
      if (idx !== -1 && idx < elements.value.length - 1) moveLayer(idx, idx + 1)
  }

  const sendBackward = (id: string) => {
      const idx = elements.value.findIndex(e => e.id === id)
      if (idx !== -1 && idx > 0) moveLayer(idx, idx - 1)
  }

  const handleWheelZoom = (e: WheelEvent) => {
    if (e.ctrlKey || e.metaKey) {
        e.preventDefault()
        const delta = e.deltaY > 0 ? 0.9 : 1.1
        zoom.value = Math.min(Math.max(zoom.value * delta, 2), 20)
    }
  }

  const startDrag = (event: MouseEvent, element: LabelElement) => {
    if (element.locked) return
    event.stopPropagation(); event.preventDefault()
    activeElementId.value = element.id; draggingElement.value = element
    dragOffset.x = event.clientX; dragOffset.y = event.clientY
  }

  const startResize = (event: MouseEvent, element: LabelElement, handle: string) => {
    if (element.locked) return
    event.stopPropagation(); event.preventDefault()
    activeElementId.value = element.id; resizingElement.value = element; resizeHandle.value = handle
    dragOffset.x = event.clientX; dragOffset.y = event.clientY
    startDims.x = element.x; startDims.y = element.y
    startDims.w = element.width || 0; startDims.h = element.height || 0
  }

  const handleMouseMove = (event: MouseEvent, canvasWidth: number, canvasHeight: number) => {
    if (resizingElement.value && resizeHandle.value) {
        const el = resizingElement.value
        const deltaXmm = (event.clientX - dragOffset.x) / zoom.value
        const deltaYmm = (event.clientY - dragOffset.y) / zoom.value
        let newW = startDims.w, newH = startDims.h, newX = startDims.x, newY = startDims.y

        if (resizeHandle.value.includes('r')) newW = Math.max(1, startDims.w + deltaXmm)
        if (resizeHandle.value.includes('l')) { const diff = startDims.w - deltaXmm; if (diff > 1) { newW = diff; newX = startDims.x + deltaXmm } }
        if (resizeHandle.value.includes('b')) newH = Math.max(1, startDims.h + deltaYmm)
        if (resizeHandle.value.includes('t')) { const diff = startDims.h - deltaYmm; if (diff > 1) { newH = diff; newY = startDims.y + deltaYmm } }

        el.width = newW; el.height = newH; el.x = newX; el.y = newY
        return
    }

    if (draggingElement.value) {
        const el = draggingElement.value
        const deltaXmm = (event.clientX - dragOffset.x) / zoom.value
        const deltaYmm = (event.clientY - dragOffset.y) / zoom.value
        let newX = el.x + deltaXmm, newY = el.y + deltaYmm
        const guidesX: number[] = [], guidesY: number[] = []

        if (snappingEnabled.value) {
            const SNAP = 0.5, midX = newX + (el.width || 0) / 2, midY = newY + (el.height || 0) / 2
            const cMidX = canvasWidth / 2, cMidY = canvasHeight / 2

            if (Math.abs(newX - 0) < SNAP) { newX = 0; guidesX.push(0) }
            else if (Math.abs(newX - (canvasWidth - (el.width||0))) < SNAP) { newX = canvasWidth - (el.width||0); guidesX.push(canvasWidth) }
            else if (Math.abs(midX - cMidX) < SNAP) { newX = cMidX - (el.width||0)/2; guidesX.push(cMidX) }

            if (Math.abs(newY - 0) < SNAP) { newY = 0; guidesY.push(0) }
            else if (Math.abs(newY - (canvasHeight - (el.height||0))) < SNAP) { newY = canvasHeight - (el.height||0); guidesY.push(canvasHeight) }
            else if (Math.abs(midY - cMidY) < SNAP) { newY = cMidY - (el.height||0)/2; guidesY.push(cMidY) }
        }

        el.x = newX; el.y = newY
        activeGuides.x = guidesX; activeGuides.y = guidesY
        dragOffset.x = event.clientX; dragOffset.y = event.clientY
    }
  }

  const stopInteraction = () => {
    if (draggingElement.value) { draggingElement.value.x = Number(draggingElement.value.x.toFixed(2)); draggingElement.value.y = Number(draggingElement.value.y.toFixed(2)) }
    if (resizingElement.value) { resizingElement.value.width = Number(resizingElement.value.width!.toFixed(2)); resizingElement.value.height = Number(resizingElement.value.height!.toFixed(2)); resizingElement.value.x = Number(resizingElement.value.x.toFixed(2)); resizingElement.value.y = Number(resizingElement.value.y.toFixed(2)) }
    draggingElement.value = null; resizingElement.value = null; resizeHandle.value = null
    activeGuides.x = []; activeGuides.y = []
  }

  // --- MOTOR DO PDF ---
  const createPdfDoc = (config: any, printOptions: any, products: any[]) => {
    // Força o formato A4 caso não seja etiqueta customizada
    let format: any = (config.pageSize || 'a4').toLowerCase()
    if (format === 'letter' || format === 'custom') format = 'a4'

    const { labelWidth, labelHeight, colGap = 0, rowGap = 0, cols, rows, marginTop = 0, marginLeft = 0 } = config
    const isThermal = (cols === 1 && rows === 1)

    // Se for bobina térmica, usamos o tamanho exato da etiqueta
    if (isThermal) format = [labelWidth, labelHeight]

    const doc = new jsPDF({ orientation: 'p', unit: 'mm', format })
    const { copies = 1, start = 0, showPdfGrid = false } = printOptions

    const pageWidth = doc.internal.pageSize.getWidth()
    const pageHeight = doc.internal.pageSize.getHeight()

    // LÓGICA DE ALINHAMENTO NATURAL AO CENTRO DO PDF
    let startX = 0
    let startY = 0

    if (!isThermal) {
        // Agora o PDF vai respeitar as margens Topo e Esquerda do painel
        startX = Number(marginLeft) || 0
        startY = Number(marginTop) || 0
    }

    const drawGrid = () => {
        if (!showPdfGrid) return
        try {
            // Estilo da Grade: Linha fina, pontilhada, vermelha com opacidade suave
            doc.setGState(new doc.GState({ opacity: 0.3 }))
            doc.setDrawColor(255, 50, 50)
            doc.setLineWidth(0.2)
            doc.setLineDashPattern([2, 2], 0)

            if (isThermal) {
                // Bobina térmica não tem grid multiplicada
                doc.rect(0, 0, labelWidth, labelHeight)
            } else {
                // Desenha a malha da página perfeitamente centralizada
                for (let r = 0; r < rows; r++) {
                    for (let c = 0; c < cols; c++) {
                        const cellX = startX + (c * (labelWidth + colGap))
                        const cellY = startY + (r * (labelHeight + rowGap))
                        doc.rect(cellX, cellY, labelWidth, labelHeight)
                    }
                }
            }
            doc.setGState(new doc.GState({ opacity: 1.0 }))
            doc.setLineDashPattern([], 0)
            doc.setDrawColor(0, 0, 0)
        } catch (e) {
            console.warn("Erro ao desenhar grade de simulação:", e)
        }
    }

    // Desenha na primeira página
    drawGrid()

    let itemsToPrint: any[] = []

    if (!isThermal && start > 0) {
        for(let i = 0; i < start; i++) itemsToPrint.push(null)
    }

    products.forEach(p => {
        for(let i = 0; i < copies; i++) itemsToPrint.push(p)
    })

    let currentPos = 0
    const maxLabelsPerPage = isThermal ? 1 : (cols * rows)

    itemsToPrint.forEach((product, index) => {
        if (currentPos >= maxLabelsPerPage && index > 0) {
            doc.addPage()
            drawGrid() // Redesenha a grade centralizada na página nova
            currentPos = 0
        }

        if (!product) { currentPos++; return }

        let cellX = 0, cellY = 0
        if (!isThermal) {
            const col = currentPos % cols
            const row = Math.floor(currentPos / cols)
            // Usa as âncoras centralizadas
            cellX = startX + (col * (labelWidth + colGap))
            cellY = startY + (row * (labelHeight + rowGap))
        }

        elements.value.forEach(el => {
            if (!el.visible) return

            if (el.folderId) {
                const folder = folders.value.find(f => f.id === el.folderId)
                if (folder && !folder.visible) return
            }

            const finalX = cellX + el.x
            const finalY = cellY + el.y

            if (el.opacity < 1) {
                try { doc.setGState(new doc.GState({ opacity: el.opacity })) } catch {}
            }

            doc.setTextColor(el.color || '#000000')

            if (el.type === 'text') {
                // SOLUÇÃO DO ERRO DO JSPDF: "Invalid Combination"
                let fontStyle = 'normal'
                if (el.bold && el.italic) fontStyle = 'bolditalic'
                else if (el.bold) fontStyle = 'bold'
                else if (el.italic) fontStyle = 'italic'

                doc.setFont(el.fontFamily || 'helvetica', fontStyle)
                doc.setFontSize(el.fontSize || 10)

                let text = el.label
                if (el.id === 'name') text = (product.name || product.description || 'Produto Sem Nome').substring(0, 45)
                else if (el.id === 'price') {
                    const price = product.sale_price || product.price || product.active_price || product.base_price || 0
                    text = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(price)
                }
                else if (el.id === 'sku') text = `${product.sku || product.code || '-'}`
                else if (el.id === 'barcode') text = product.barcode || product.ean || product.sku || ''

                const textOpts: any = { baseline: 'top' }
                if (el.rotation) textOpts.angle = el.rotation

                doc.text(text, finalX, finalY, textOpts)
            }
            else if (el.type === 'barcode') {
                 const code = product.barcode || product.ean || product.sku || '123456789'
                 if (code) {
                     try {
                        const canvas = document.createElement('canvas')
                        JsBarcode(canvas, code, {
                            format: "CODE128",
                            displayValue: el.showNum,
                            fontSize: 14,
                            margin: 0,
                            height: 50,
                            width: 2,
                            lineColor: el.color || '#000000',
                            background: '#ffffff'
                        })
                        const imgData = canvas.toDataURL('image/jpeg', 1.0)
                        let angle = el.rotation || 0
                        doc.addImage(imgData, 'JPEG', finalX, finalY, el.width || 30, el.height || 10, undefined, 'FAST', angle)
                     } catch (err) {}
                 }
            }
            else if (el.type === 'image' && el.src) {
                try {
                    let angle = el.rotation || 0
                    doc.addImage(el.src, 'PNG', finalX, finalY, el.width || 10, el.height || 10, undefined, 'FAST', angle)
                } catch (err) {}
            }

            if (el.opacity < 1) {
                try { doc.setGState(new doc.GState({ opacity: 1.0 })) } catch {}
            }
        })
        currentPos++
    })
    return doc
  }

  const generatePdfPreview = async (config: any, printOptions: any, products: any[]) => {
      isGenerating.value = true

      const mergedOptions = { ...printOptions, showPdfGrid: showPdfGrid.value }

      await new Promise(r => setTimeout(r, 50))
      try {
          const doc = createPdfDoc(config, mergedOptions, products)
          const blob = doc.output('blob')
          if (pdfUrl.value) URL.revokeObjectURL(pdfUrl.value)
          pdfUrl.value = URL.createObjectURL(blob)
      } catch (e) {
          console.error(e)
      } finally {
          isGenerating.value = false
      }
  }

  return {
    zoom, activeElementId, elements, folders, pdfUrl, isGenerating, draggingElement, resizingElement, activeGuides,
    snappingEnabled, showGrid, showPdfGrid,
    addImage, addText, addBarcode, duplicateElement, deleteElement, moveLayer, bringForward, sendBackward,
    createFolder, deleteFolder, addToFolder,
    handleWheelZoom, startDrag, startResize, handleMouseMove, stopInteraction, generatePdfPreview, createPdfDoc
  }
}
