import { defineStore } from 'pinia'
import { supabase } from '@/api/supabase'
import { format, subDays, startOfMonth, endOfMonth, parseISO } from 'date-fns'
import { useUserStore } from './user'

export type DashboardWidget = {
  id: string
  title: string
  type: 'kpi' | 'chart' | 'list'
  config: any
  cols: number
  visible: boolean
  value?: any
  series?: any[]
  options?: any
  listData?: any[]
  loading?: boolean
  comparison?: number
  activeMetric?: string
}

const parseNum = (val: any): number => {
    if (val === null || val === undefined || val === '') return 0
    if (typeof val === 'number') return isNaN(val) ? 0 : val
    if (typeof val === 'string') {
        const clean = val.replace('R$', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
        const num = parseFloat(clean)
        return isNaN(num) ? 0 : num
    }
    return 0
}

export const useCajuiaDashboardStore = defineStore('cajuiaDashboard', {
  state: () => ({
    widgets: [] as DashboardWidget[],
    availableWidgets: [] as DashboardWidget[],
    selectedPeriod: 'month' as 'today' | 'week' | 'month',
    lastSync: '--:--',
    isLoading: false,
    editMode: false,
  }),

  actions: {
    toggleEditMode() { this.editMode = !this.editMode },

    async loadDashboard() {
      this.isLoading = true
      const userStore = useUserStore()
      try {
        const { data: definitions, error: defError } = await supabase
            .from('cajuia_widgets')
            .select('*')
            .or(`is_system.eq.true,created_by.eq.${userStore.user?.id}`)

        if (defError) throw defError

        this.availableWidgets = (definitions || []).map((def: any) => ({
          id: def.id,
          title: def.title,
          type: def.type,
          config: def.config,
          cols: def.default_cols || 3,
          visible: true,
          loading: false,
          activeMetric: 'value'
        }))

        const { data: layoutData } = await supabase
          .from('cajuia_dashboard_layouts')
          .select('layout')
          .eq('user_id', userStore.user?.id)
          .maybeSingle() // Use maybeSingle para evitar erros 406 se não existir

        if (layoutData?.layout) {
            const layout = layoutData.layout
            this.widgets = layout.map((item: any) => {
                const def = this.availableWidgets.find(w => w.id === item.widget_id)
                if (!def) return null
                return { ...def, cols: item.cols || def.cols, visible: item.visible }
            }).filter(Boolean) as DashboardWidget[]

            const existingIds = new Set(this.widgets.map(w => w.id))
            const newWidgets = this.availableWidgets.filter(w => !existingIds.has(w.id))
            this.widgets = [...this.widgets, ...newWidgets]
        } else {
            this.widgets = [...this.availableWidgets]
        }
        await this.refreshAllData()
      } catch (e) {
        console.error('Erro ao carregar dashboard:', e)
      } finally {
        this.isLoading = false
      }
    },

    async saveLayout() {
      const userStore = useUserStore()
      if (!userStore.user?.id) return
      const layout = this.widgets.map(w => ({ widget_id: w.id, cols: w.cols, visible: w.visible }))

      // Upsert garantindo que salva para o usuário atual
      await supabase.from('cajuia_dashboard_layouts').upsert({
        user_id: userStore.user.id,
        layout: layout,
        updated_at: new Date().toISOString()
      }, { onConflict: 'user_id' })
    },

    async createCustomWidget(widgetData: any) {
        const userStore = useUserStore()
        if (!userStore.user?.id) return
        const configToSave = { ...widgetData.config, filters: widgetData.config.filters || [], height: widgetData.config.height || null }
        const { data, error } = await supabase.from('cajuia_widgets').insert({
            title: widgetData.title, type: widgetData.type, config: configToSave,
            default_cols: widgetData.cols, created_by: userStore.user.id, is_system: false
        }).select().single()
        if (error) throw error
        const newWidget = { id: data.id, title: data.title, type: data.type, config: data.config, cols: data.default_cols, visible: true, loading: false }
        this.widgets.push(newWidget)
        await this.saveLayout()
        await this.processWidgetData(newWidget, this.getDateRange(this.selectedPeriod))
        return newWidget
    },

    async deleteWidget(id: string) {
        const index = this.widgets.findIndex(w => w.id === id)
        if (index === -1) return
        const widget = this.widgets[index]
        this.widgets.splice(index, 1)
        await this.saveLayout()
        if (!widget.config?.is_system) await supabase.from('cajuia_widgets').delete().eq('id', id)
    },

    async refreshAllData() {
      const dates = this.getDateRange(this.selectedPeriod)
      await Promise.all(this.widgets.filter(w => w.visible).map(w => this.processWidgetData(w, dates)))
      this.lastSync = format(new Date(), 'HH:mm')
    },

    // --- ENVELOPAMENTO DE DADOS AQUI ---
    async processWidgetData(widget: DashboardWidget, dates: any) {
        const userStore = useUserStore()
        widget.loading = true

        try {
            const { source, operation, column, filters, chart_type, group_by, list_type, sort_col, limit, multiplier } = widget.config

            let selectCols = '*'
            let query = supabase.from(source).select(selectCols, { count: 'exact' })

            // --- SEGURANÇA: ENVELOPAMENTO DE DADOS ---
            // Se o usuário NÃO for Admin Global e NÃO for Admin Cajuia, filtra pelo ID dele
            const restrictedTables = ['cajuia_orders', 'cajuia_sales', 'cajuia_order_items', 'cajuia_clients']
            const isRestricted = restrictedTables.includes(source)

            if (isRestricted && !userStore.isGlobalAdmin && !userStore.isCajuiaAdmin && userStore.user?.id) {
                // Para clientes o campo é created_by, para vendas é user_id
                const userField = source === 'cajuia_clients' ? 'created_by' : 'user_id'
                query = query.eq(userField, userStore.user.id)
            }
            // ------------------------------------------

            const isTransactional = ['cajuia_orders', 'cajuia_sales', 'cajuia_order_items'].includes(source);
            if (isTransactional) {
                query = query.gte('created_at', dates.start).lte('created_at', dates.end)
            }

            if (filters && Array.isArray(filters)) {
                filters.forEach((f: any) => {
                    if (f.column && f.operator && f.value !== undefined && f.value !== '') {
                         const isNumericCol = ['price', 'quantity', 'total_value', 'quantity_in_stock', 'id', 'total_price'].includes(f.column);
                         let val = f.value;
                         if (isNumericCol) { val = Number(f.value); if (isNaN(val)) return; }
                         let op = f.operator;
                         if (isNumericCol && op === 'ilike') op = 'eq';

                         switch(op) {
                             case 'eq': query = query.eq(f.column, val); break;
                             case 'neq': query = query.neq(f.column, val); break;
                             case 'gt': query = query.gt(f.column, val); break;
                             case 'gte': query = query.gte(f.column, val); break;
                             case 'lt': query = query.lt(f.column, val); break;
                             case 'lte': query = query.lte(f.column, val); break;
                             case 'ilike': query = query.ilike(f.column, `%${val}%`); break;
                             case 'is': if(f.value === 'null') query = query.is(f.column, null); else query = query.is(f.column, f.value === 'true'); break;
                         }
                    }
                })
            }

            if (sort_col && sort_col !== 'total_value') query = query.order(sort_col, { ascending: false })
            if (limit && list_type !== 'ranking' && widget.type !== 'kpi') query = query.limit(limit)

            const { data, count, error } = await query
            if (error) throw error

            const rows = data || []

            const getRowValue = (row: any) => {
                if (source === 'cajuia_products' && (column === 'total_value' || column === 'price')) {
                    if(column === 'total_value') return parseNum(row.price) * parseNum(row.quantity_in_stock)
                    return parseNum(row[column])
                }
                if (source === 'cajuia_order_items') {
                    if (column === 'total_value' || column === 'total_price') return parseNum(row.total_price)
                    if (column === 'quantity') return parseNum(row.quantity)
                }
                if (source === 'cajuia_orders' && (column === 'total_value' || column === 'value')) {
                    return parseNum(row.total_value)
                }
                return parseNum(row[column])
            }

            const processedList = rows.map(row => {
                const val = getRowValue(row)
                return {
                    ...row,
                    _val: val,
                    value: val,
                    displayName: row.customer_name || row.product_name || row.name || `Item ${row.id}`,
                    quantity: parseNum(row.quantity || row.quantity_in_stock),
                    total_price: parseNum(row.total_price || row.total_value || (parseNum(row.price) * parseNum(row.quantity_in_stock)))
                }
            })

            if (widget.type === 'kpi') {
                let val = 0
                if (operation === 'count') {
                    val = count || 0
                }
                else if (operation === 'sum') {
                    val = rows.reduce((acc, curr) => acc + getRowValue(curr), 0)
                }
                else if (operation === 'avg' && (count || 0) > 0) {
                    val = rows.reduce((acc, curr) => acc + getRowValue(curr), 0) / count!
                }
                else if (operation === 'count_distinct') {
                    val = new Set(rows.map(r => r[column]).filter(Boolean)).size
                }

                if (multiplier) val = val * multiplier
                widget.value = val
                widget.listData = processedList.slice(0, 100)

                if (source === 'cajuia_orders') await this.calcComparison(widget, dates)
            }

            if (widget.type === 'chart') {
                const grouped: Record<string, number> = {}
                rows.forEach(row => {
                    let key = row[group_by]
                    if (group_by === 'created_at') {
                        if (!key) key = 'N/A'
                        else try { key = this.selectedPeriod === 'today' ? format(parseISO(key), 'HH:00') : format(parseISO(key), 'dd/MM') } catch(e) { key = 'N/A' }
                    }
                    key = key || 'Outros'
                    const val = (operation === 'count') ? 1 : getRowValue(row)
                    grouped[key] = (grouped[key] || 0) + val
                })
                const categories = Object.keys(grouped).sort()
                const seriesData = categories.map(k => grouped[k])
                const color = widget.config.color || '#2962FF'

                const commonOptions = {
                    chart: { background: 'transparent', toolbar: { show: false }, fontFamily: 'Roboto, sans-serif', animations: { enabled: true } },
                    theme: { mode: 'dark' },
                    stroke: { show: true, width: 3, curve: 'smooth', colors: [chart_type === 'area' ? color : '#1e1e24'] },
                    grid: { show: true, borderColor: 'rgba(255,255,255,0.05)', strokeDashArray: 4, xaxis: { lines: { show: false } }, padding: { top: 0, right: 10, bottom: 0, left: 10 } },
                    dataLabels: { enabled: false }
                }

                if (chart_type === 'area') {
                    widget.options = {
                        ...commonOptions,
                        xaxis: { categories, labels: { style: { colors: '#666', fontSize: '10px', fontWeight: 600 } }, axisBorder: { show: false }, axisTicks: { show: false }, tooltip: { enabled: false } },
                        yaxis: { labels: { style: { colors: '#666', fontSize: '10px', fontFamily: 'Roboto Mono' }, formatter: (val:number) => val >= 1000 ? `${(val/1000).toFixed(1)}k` : val.toFixed(0) } },
                        tooltip: { theme: 'dark', y: { formatter: (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 }).format(val) }, marker: { show: true } },
                        colors: [color],
                        fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.05 } }
                    }
                    widget.series = [{ name: widget.config.y_label || 'Valor', data: seriesData }]
                } else {
                    widget.options = { ...commonOptions, labels: categories, plotOptions: { pie: { donut: { size: '75%', labels: { show: false } } } }, legend: { position: 'bottom', labels: { colors: '#fff' }, fontSize: '11px', markers: { radius: 3 } }, colors: widget.config.colors || ['#00E676', '#2962FF', '#FFC107', '#FF3D00', '#AA00FF'], tooltip: { theme: 'dark', y: { formatter: (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 }).format(val) } } }
                    widget.series = seriesData
                }
            }

            if (widget.type === 'list') {
                if (list_type === 'ranking') {
                      const map: Record<string, any> = {}
                      processedList.forEach(row => {
                          let groupCol = widget.config.group_col
                          if (!groupCol && source === 'cajuia_order_items') groupCol = 'product_name'
                          else if (!groupCol) groupCol = 'name'

                          const key = row[groupCol] || row.displayName || 'Outros'
                          if(!map[key]) map[key] = { ...row, _val: 0, value: 0, _count: 0, quantity: 0, total_price: 0 }

                          map[key]._val += row._val
                          map[key].value += row._val
                          map[key]._count += 1
                          map[key].quantity += parseNum(row.quantity || row.quantity_in_stock)

                          if (source === 'cajuia_products') {
                              map[key].total_price += (parseNum(row.price) * parseNum(row.quantity_in_stock))
                          } else {
                              map[key].total_price += parseNum(row.total_price || row.total_value)
                          }
                      })
                      widget.listData = Object.values(map).sort((a:any, b:any) => b._val - a._val).slice(0, limit || 5)
                } else {
                    widget.listData = processedList.slice(0, limit || 10)
                }
            }
        } catch (e) {
            console.error(`Erro widget ${widget.title}:`, e)
            widget.value = 0
            widget.listData = []
        } finally {
            widget.loading = false
        }
    },

    async calcComparison(widget: DashboardWidget, dates: any) {
        // Correção para aplicar o mesmo filtro de segurança no cálculo de comparação
        const userStore = useUserStore()
        const { source, column, operation } = widget.config

        if (['cajuia_products', 'cajuia_order_items'].includes(source)) { widget.comparison = 0; return }

        let query = supabase.from(source).select(column).gte('created_at', dates.prevStart).lte('created_at', dates.prevEnd)

        // --- SEGURANÇA NA COMPARAÇÃO ---
        const restrictedTables = ['cajuia_orders', 'cajuia_sales']
        if (restrictedTables.includes(source) && !userStore.isGlobalAdmin && !userStore.isCajuiaAdmin && userStore.user?.id) {
            query = query.eq('user_id', userStore.user.id)
        }
        // -------------------------------

        const { data } = await query

        let prevVal = 0
        if (operation === 'count') prevVal = data?.length || 0
        else if (operation === 'sum') prevVal = data?.reduce((acc: any, curr: any) => acc + parseNum(curr[column]), 0) || 0
        else if (operation === 'avg') { const total = data?.reduce((acc: any, curr: any) => acc + parseNum(curr[column]), 0) || 0; prevVal = data?.length ? total / data.length : 0 }

        const current = Number(widget.value) || 0
        if (prevVal === 0) widget.comparison = current > 0 ? 100 : 0
        else widget.comparison = ((current - prevVal) / prevVal) * 100
    },

    getDateRange(period: string) {
        const now = new Date()
        let start: Date, end: Date, prevStart: Date, prevEnd: Date
        if (period === 'today') { start = new Date(); start.setHours(0,0,0,0); end = new Date(); end.setHours(23,59,59,999); prevStart = subDays(start, 1); prevEnd = subDays(end, 1); }
        else if (period === 'week') { start = subDays(now, 7); end = now; prevStart = subDays(start, 7); prevEnd = subDays(end, 7); }
        else { start = startOfMonth(now); end = endOfMonth(now); prevStart = subDays(start, 30); prevEnd = subDays(end, 30); }
        return { start: start.toISOString(), end: end.toISOString(), prevStart: prevStart.toISOString(), prevEnd: prevEnd.toISOString() }
    }
  }
})
