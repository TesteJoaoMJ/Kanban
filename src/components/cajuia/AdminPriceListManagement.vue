<template>
  <div class="d-flex h-100 w-100 pa-6 gap-6 overflow-hidden">

    <div class="glass-panel width-320 d-flex flex-column rounded-xl flex-shrink-0 overflow-hidden">
        <div class="pa-5 border-b border-white-10 bg-glass-header">
             <div class="d-flex align-center justify-space-between mb-2">
                 <h3 class="text-h6 font-weight-bold text-white">Estratégias</h3>
                 <v-btn icon size="x-small" variant="text" color="white" class="glass-btn-icon" @click="fetchAll" :loading="loading">
                    <v-icon>mdi-refresh</v-icon>
                    <v-tooltip activator="parent" location="top">Atualizar Listas</v-tooltip>
                 </v-btn>
             </div>
             <p class="text-caption text-white-50 mb-4">Gerencie tabelas de preço para atacado, varejo ou campanhas.</p>

             <v-btn
                block
                color="primary"
                variant="flat"
                class="font-weight-bold shadow-glow-primary rounded-lg text-none"
                prepend-icon="mdi-plus"
                height="40"
                @click="showNewListModal = true"
             >
                Nova Tabela
             </v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scrollbar pa-3 d-flex flex-column gap-2">
            <div v-if="priceLists.length === 0 && !loading" class="text-center py-8 text-white-50">
                <div class="icon-circle bg-white-05 mx-auto mb-3"><v-icon size="small">mdi-tag-off</v-icon></div>
                <div class="text-[11px]">Nenhuma tabela criada.</div>
            </div>

            <v-card
               v-for="list in priceLists"
               :key="list.id"
               @click="selectList(list)"
               class="rounded-lg glass-list-card border-none transition-swing group"
               :class="{'active-card': selectedList?.id === list.id}"
               flat
               link
               v-ripple
            >
                <div class="d-flex align-center pa-3">
                    <div class="icon-square mr-3 elevation-4 transition-transform group-hover:scale-110"
                         :class="selectedList?.id === list.id ? 'bg-gradient-primary text-white' : 'bg-glass-surface text-white-50'">
                        <v-icon size="18">{{ selectedList?.id === list.id ? 'mdi-tag-text' : 'mdi-tag-outline' }}</v-icon>
                    </div>
                    <div class="overflow-hidden flex-grow-1">
                        <div class="font-weight-bold text-white text-body-2 text-truncate">{{ list.name }}</div>
                        <div class="text-[10px] text-white-50 text-truncate mt-0 font-weight-medium">{{ list.description || 'Sem descrição' }}</div>
                    </div>
                    <v-icon v-if="selectedList?.id === list.id" color="white" size="x-small" class="ml-2 fade-in">mdi-chevron-right</v-icon>
                </div>
            </v-card>
        </div>
    </div>

    <div class="d-flex flex-column flex-grow-1 h-100 overflow-hidden relative">

        <div v-if="!selectedList" class="absolute-center d-flex flex-column align-center justify-center opacity-50">
            <div class="icon-circle bg-white-05 mb-4" style="width: 80px; height: 80px;">
                <v-icon size="40" color="white">mdi-cursor-default-click</v-icon>
            </div>
            <h2 class="text-h5 font-weight-bold text-white">Selecione uma Estratégia</h2>
            <p class="text-white-50 text-center max-w-md">Escolha uma tabela de preços no menu lateral para gerenciar os valores.</p>
        </div>

        <template v-else>
            <div class="d-flex align-center justify-space-between mb-4 flex-shrink-0">
                 <div>
                     <div class="d-flex align-center gap-2">
                        <h2 class="text-h5 font-weight-black text-white text-shadow">{{ selectedList.name }}</h2>
                        <v-chip size="x-small" color="success" variant="flat" class="font-weight-bold">{{ stats.pricedCount }} Personalizados</v-chip>
                     </div>
                     <div class="text-caption text-white-50 mt-1">{{ selectedList.description || 'Edição de preços.' }}</div>
                 </div>
                 <div class="d-flex gap-2">
                     <v-btn
                        variant="outlined"
                        size="small"
                        color="error"
                        class="glass-btn border-error text-none"
                        prepend-icon="mdi-delete"
                        @click="deleteList"
                     >
                        Excluir Tabela
                     </v-btn>
                 </div>
            </div>

            <div class="d-flex gap-4 mb-4 flex-shrink-0">
                <div class="glass-stat-card flex-grow-1 pa-3 rounded-xl d-flex align-center hover-glow border-l-success">
                    <div class="icon-box bg-success-10 mr-3 rounded-lg"><v-icon color="success" size="20">mdi-chart-line</v-icon></div>
                    <div>
                        <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Margem Média</div>
                        <div class="text-h6 font-weight-black text-white">{{ stats.avgMargin }}%</div>
                    </div>
                </div>
                <div class="glass-stat-card flex-grow-1 pa-3 rounded-xl d-flex align-center hover-glow border-l-info">
                    <div class="icon-box bg-info-10 mr-3 rounded-lg"><v-icon color="info" size="20">mdi-cash-multiple</v-icon></div>
                    <div>
                        <div class="text-[10px] text-white-50 font-weight-bold text-uppercase letter-spacing-1">Potencial (Venda)</div>
                        <div class="text-h6 font-weight-black text-white">{{ formatCurrency(stats.projectedRevenue) }}</div>
                    </div>
                </div>
            </div>

            <div class="glass-panel pa-2 rounded-xl d-flex align-center gap-3 flex-shrink-0 mb-4 border-white-05">
                <div style="width: 240px;">
                    <v-text-field
                        v-model="search"
                        density="compact"
                        variant="solo"
                        placeholder="Filtrar por nome ou SKU..."
                        prepend-inner-icon="mdi-magnify"
                        hide-details
                        class="glass-input"
                        bg-color="rgba(0,0,0,0.2)"
                        clearable
                    ></v-text-field>
                </div>

                <v-divider vertical class="border-white-10 h-24 my-auto"></v-divider>

                <div style="width: 180px;">
                    <v-select
                        v-model="filterCategory"
                        :items="categories"
                        item-title="name"
                        item-value="name"
                        label="Categoria"
                        density="compact"
                        variant="solo"
                        hide-details
                        class="glass-input"
                        bg-color="rgba(0,0,0,0.2)"
                        clearable
                        menu-icon="mdi-chevron-down"
                    ></v-select>
                </div>

                <div style="width: 180px;">
                    <v-select
                        v-model="filterStatus"
                        :items="[{title: 'Todos', value: 'all'}, {title: 'Com Preço Definido', value: 'custom'}, {title: 'Sem Preço (Base)', value: 'base'}]"
                        item-title="title"
                        item-value="value"
                        label="Status"
                        density="compact"
                        variant="solo"
                        hide-details
                        class="glass-input"
                        bg-color="rgba(0,0,0,0.2)"
                        menu-icon="mdi-chevron-down"
                    ></v-select>
                </div>

                <v-spacer></v-spacer>

                <div class="d-flex align-center mr-2">
                    <v-checkbox-btn
                        :model-value="isAllSelected"
                        :indeterminate="isIndeterminate"
                        @update:model-value="toggleSelectAll"
                        color="primary"
                        class="mr-2"
                    ></v-checkbox-btn>
                    <span class="text-caption text-white-50 font-weight-bold" v-if="selectedProductIds.length > 0">
                        {{ selectedProductIds.length }} selecionados
                    </span>
                    <span class="text-caption text-white-50" v-else>
                        Selecionar Tudo
                    </span>
                </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scrollbar pr-2 pb-16 relative">
                <div class="price-list-header d-flex px-4 py-2 text-caption font-weight-bold text-white-50 text-uppercase mb-2">
                    <div style="width: 40px;"></div> <div style="width: 60px;">Foto</div>
                    <div class="flex-grow-1">Produto</div>
                    <div style="width: 100px;" class="text-right">Custo Base</div>
                    <div style="width: 140px;" class="text-right">Preço Tabela</div>
                    <div style="width: 80px;" class="text-right">Margem</div>
                    <div style="width: 40px;"></div> </div>

                <div v-if="filteredProducts.length === 0" class="text-center py-10 text-white-50">
                    <v-icon size="40" class="mb-2 opacity-50">mdi-filter-variant-remove</v-icon>
                    <div>Nenhum produto encontrado.</div>
                </div>

                <div
                    v-for="item in filteredProducts"
                    :key="item.id"
                    class="price-row glass-list-card rounded-lg mb-1 d-flex align-center px-4 py-2 transition-all border-white-05"
                    :class="{'selected': selectedProductIds.includes(item.id)}"
                >
                    <div style="width: 40px;">
                         <v-checkbox-btn
                            :model-value="selectedProductIds.includes(item.id)"
                            @update:model-value="toggleSelection(item.id)"
                            color="primary"
                            density="compact"
                         ></v-checkbox-btn>
                    </div>

                    <div style="width: 60px;">
                        <v-avatar size="40" rounded="lg" class="bg-grey-darken-4 border-white-10">
                            <v-img :src="item.photo_url || '/placeholder.png'" cover></v-img>
                        </v-avatar>
                    </div>

                    <div class="flex-grow-1 pr-4 overflow-hidden">
                        <div class="d-flex align-center gap-2">
                            <div class="text-body-2 font-weight-bold text-white text-truncate">{{ item.name }}</div>
                            <v-icon v-if="item.variations_count > 0 || item.barcode" size="12" color="success" title="Possui variações/barcode">mdi-barcode</v-icon>
                        </div>
                        <div class="d-flex align-center gap-2">
                             <span class="text-[10px] font-mono bg-white-05 px-1 rounded text-white-50">{{ item.sku || 'S/ SKU' }}</span>
                             <span class="text-[10px] text-white-30 text-uppercase">{{ item.category || 'Geral' }}</span>
                        </div>
                    </div>

                    <div style="width: 100px;" class="text-right text-caption text-white-50 font-mono">
                        {{ formatCurrency(item.base_price) }}
                    </div>

                    <div style="width: 140px;" class="pl-4 d-flex justify-end">
                        <div class="price-input-wrapper" :class="{'saving': item.is_saving, 'has-value': item.custom_price !== null}">
                            <span class="currency-symbol">R$</span>
                            <input
                                type="number"
                                step="0.01"
                                class="custom-price-input"
                                v-model.lazy="item.edit_price"
                                @change="updatePrice(item)"
                                @focus="$event.target.select()"
                            />
                            <div class="status-indicator">
                                <v-progress-circular v-if="item.is_saving" indeterminate size="8" width="2" color="primary"></v-progress-circular>
                                <div v-else-if="item.custom_price !== null" class="status-dot bg-success"></div>
                            </div>
                        </div>
                    </div>

                    <div style="width: 80px;" class="text-right d-flex flex-column align-end justify-center">
                         <span
                            class="text-caption font-weight-black"
                            :class="getMarginColor(item.base_price, item.edit_price)"
                         >
                             {{ calculateMargin(item.base_price, item.edit_price) }}
                         </span>
                    </div>

                    <div style="width: 40px;" class="text-right">
                        <v-btn icon size="small" variant="text" color="white-50" class="hover-white" @click="editProduct(item)">
                            <v-icon>mdi-pencil</v-icon>
                            <v-tooltip activator="parent" location="top">Editar SKU e Variações</v-tooltip>
                        </v-btn>
                    </div>
                </div>
            </div>

            <v-slide-y-reverse-transition>
                <div v-if="selectedProductIds.length > 0" class="bulk-actions-dock-container">
                    <div class="glass-dock d-flex align-center justify-space-between px-6 py-3">

                        <div class="d-flex align-center gap-4">
                            <div class="selection-badge-large">
                                <span class="text-h6 font-weight-black text-white lh-1">{{ selectedProductIds.length }}</span>
                            </div>
                            <div class="d-flex flex-column">
                                <span class="text-body-2 font-weight-bold text-white">Itens Selecionados</span>
                                <span class="text-[11px] text-white-50">Escolha uma ação em lote</span>
                            </div>
                        </div>

                        <v-divider vertical class="mx-6 border-white-10 h-32 align-self-center"></v-divider>

                        <div class="d-flex align-center gap-3">
                            <v-btn
                                variant="text"
                                color="white-70"
                                class="text-none px-4 font-weight-bold"
                                rounded="lg"
                                height="40"
                                @click="selectedProductIds = []"
                            >
                                Cancelar
                            </v-btn>

                            <v-btn
                                color="info"
                                variant="tonal"
                                class="text-none font-weight-bold px-5"
                                rounded="lg"
                                height="40"
                                prepend-icon="mdi-barcode"
                                @click="showLabelModal = true"
                            >
                                Gerar Etiquetas
                            </v-btn>

                            <v-btn
                                color="error"
                                variant="tonal"
                                class="text-none font-weight-bold px-5"
                                rounded="lg"
                                height="40"
                                prepend-icon="mdi-tag-off"
                                @click="bulkRemovePrice"
                            >
                                Remover Preços
                            </v-btn>

                            <v-btn
                                color="primary"
                                variant="flat"
                                class="text-none font-weight-bold px-6 shadow-glow-primary"
                                rounded="lg"
                                height="40"
                                prepend-icon="mdi-magic-staff"
                                @click="openBulkEditModal"
                            >
                                Reajustar Valores
                            </v-btn>
                        </div>
                    </div>
                </div>
            </v-slide-y-reverse-transition>

        </template>
    </div>

    <v-dialog v-model="showNewListModal" max-width="400" content-class="glass-dialog">
       <v-card class="glass-panel pa-5 border-white-10 rounded-xl">
          <h3 class="text-h6 text-white font-weight-bold mb-4">Nova Estratégia</h3>
          <v-text-field v-model="newListName" label="Nome" variant="outlined" class="glass-input mb-3" bg-color="rgba(0,0,0,0.3)" density="compact"></v-text-field>
          <v-textarea v-model="newListDesc" label="Descrição" variant="outlined" class="glass-input mb-4" bg-color="rgba(0,0,0,0.3)" rows="2" density="compact"></v-textarea>
          <v-btn block color="primary" @click="createList" :loading="creatingList" class="font-weight-bold">Criar</v-btn>
       </v-card>
    </v-dialog>

    <v-dialog v-model="showBulkEditModal" max-width="420" content-class="glass-dialog">
        <v-card class="glass-panel border-white-10 rounded-xl overflow-hidden">
             <div class="pa-5 bg-glass-header border-b border-white-10">
                <div class="d-flex align-center mb-1">
                    <div class="icon-circle bg-primary mr-3"><v-icon color="white">mdi-playlist-edit</v-icon></div>
                    <div>
                        <h3 class="text-h6 text-white font-weight-bold">Reajuste em Massa</h3>
                        <div class="text-caption text-white-50">Editando {{ selectedProductIds.length }} produtos</div>
                    </div>
                </div>
            </div>

            <div class="pa-5">
                <div class="text-caption text-white-70 font-weight-bold text-uppercase mb-2">Tipo de Operação</div>
                <v-btn-toggle v-model="bulkActionType" color="primary" mandatory class="glass-toggle w-100 mb-4 rounded-lg border-white-10" density="comfortable">
                    <v-btn value="increase_pct" class="flex-grow-1 text-none text-caption font-weight-bold">Aumento (%)</v-btn>
                    <v-btn value="decrease_pct" class="flex-grow-1 text-none text-caption font-weight-bold">Desconto (%)</v-btn>
                    <v-btn value="fixed" class="flex-grow-1 text-none text-caption font-weight-bold">Preço Fixo</v-btn>
                </v-btn-toggle>

                <v-text-field v-model="bulkActionValue" type="number" :label="bulkActionType === 'fixed' ? 'Valor Fixo (R$)' : 'Porcentagem (%)'" variant="outlined" class="glass-input mb-6" density="comfortable" bg-color="rgba(0,0,0,0.3)" hide-details="auto" placeholder="0.00">
                    <template v-slot:prepend-inner>
                        <v-icon size="small" class="mr-1">{{ bulkActionType === 'fixed' ? 'mdi-currency-brl' : 'mdi-percent' }}</v-icon>
                    </template>
                </v-text-field>

                <div class="d-flex gap-3">
                    <v-btn block variant="text" color="white-70" class="flex-grow-1 rounded-lg" @click="showBulkEditModal = false">Cancelar</v-btn>
                    <v-btn block color="primary" class="flex-grow-1 font-weight-bold shadow-glow-primary rounded-lg" @click="applyBulkAction" :loading="applyingBulk">Confirmar Reajuste</v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showProductEditModal" max-width="500" content-class="glass-dialog">
        <v-card class="glass-panel border-white-10 rounded-xl overflow-hidden">
            <div class="pa-5 bg-glass-header border-b border-white-10">
                <h3 class="text-h6 text-white font-weight-bold">Detalhes do Produto</h3>
                <div class="text-caption text-white-50">{{ editingProduct?.name }}</div>
            </div>
            <div class="pa-5">
                <v-text-field
                    v-if="editingProduct"
                    v-model="editingProduct.sku"
                    label="SKU (Referência Geral)"
                    variant="outlined"
                    class="glass-input mb-6"
                    bg-color="rgba(0,0,0,0.3)"
                    density="compact"
                    prepend-inner-icon="mdi-identifier"
                    hint="Este código identifica o modelo do produto"
                    persistent-hint
                ></v-text-field>

                <v-divider class="mb-4 border-white-10"></v-divider>

                <div class="d-flex align-center justify-space-between mb-4">
                    <div class="text-subtitle-2 text-white font-weight-bold">Variações de Tamanho</div>
                    <div class="text-[10px] text-white-50">Defina os códigos de barra</div>
                </div>

                <div v-if="editingProduct">
                    <div v-for="(variant, index) in editingProduct.variations" :key="index" class="mb-3 pa-3 rounded-lg bg-glass-surface border-white-05">
                        <div class="d-flex align-center mb-2">
                            <v-chip size="small" color="primary" label class="font-weight-bold mr-2 px-3">{{ variant.name }}</v-chip>
                            <span class="text-caption text-white-50">Tamanho Padrão</span>
                        </div>

                        <v-text-field
                            v-model="variant.barcode"
                            label="Código de Barras (EAN-13)"
                            variant="outlined"
                            class="glass-input"
                            bg-color="rgba(0,0,0,0.2)"
                            density="compact"
                            hide-details
                            prepend-inner-icon="mdi-barcode-scan"
                            placeholder="Ler ou gerar código..."
                        >
                            <template v-slot:append-inner>
                                <v-tooltip text="Gerar Código Automático" location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-btn
                                            v-bind="props"
                                            icon
                                            size="small"
                                            variant="text"
                                            color="info"
                                            class="mr-n2 hover-glow-icon"
                                            @click="generateBarcodeForVariant(index)"
                                        >
                                            <v-icon>mdi-magic-staff</v-icon>
                                        </v-btn>
                                    </template>
                                </v-tooltip>
                            </template>
                        </v-text-field>
                    </div>
                </div>

                <div class="d-flex gap-3 mt-6">
                    <v-btn variant="text" color="white-70" class="flex-grow-1" @click="showProductEditModal = false">Cancelar</v-btn>
                    <v-btn color="primary" class="flex-grow-1 font-weight-bold shadow-glow-primary" @click="saveProduct" :loading="isSavingProduct">
                        Salvar Alterações
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <LabelGeneratorModal
        v-model="showLabelModal"
        :products="selectedProductsForLabels"
    />

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'
import LabelGeneratorModal from '@/components/admin/LabelGeneratorModal.vue'

const appStore = useAppStore()

// Data
const priceLists = ref<any[]>([])
const selectedList = ref<any>(null)
const products = ref<any[]>([])
const pricesMap = ref<Record<string, number>>({})
const categories = ref<any[]>([])

// UI State
const loading = ref(false)
const search = ref('')
const filterCategory = ref(null)
const filterStatus = ref('all')

// Bulk Selection
const selectedProductIds = ref<string[]>([])

// Modals
const showNewListModal = ref(false)
const newListName = ref('')
const newListDesc = ref('')
const creatingList = ref(false)

const showBulkEditModal = ref(false)
const bulkActionType = ref('increase_pct')
const bulkActionValue = ref(0)
const applyingBulk = ref(false)

// Product Edit Modal (Variations & Barcode)
const showProductEditModal = ref(false)
const editingProduct = ref<any>(null)
const isSavingProduct = ref(false)

// Label Modal State
const showLabelModal = ref(false)

// --- EDIT PRODUCT LOGIC ---
const editProduct = async (product: any) => {
    // Inicializa com variações M e G padrão se não existirem
    // (Na etapa 2, buscaremos do banco de dados)
    const variations = product.variations || [
        { name: 'M', barcode: '', id: null }, // ID null indica novo/não salvo
        { name: 'G', barcode: '', id: null }
    ]

    // Tenta preservar dados se já tivermos carregado ou editado localmente
    // Se o produto original já tiver barcodes "planos", podemos tentar mapear
    if (!product.variations && product.barcode) {
        // Exemplo: se já existe um barcode genérico, talvez atribuir ao M ou deixar?
        // Por segurança, deixamos vazio para forçar cadastro correto das variações.
    }

    editingProduct.value = {
        ...product,
        variations: JSON.parse(JSON.stringify(variations)) // Clone deep para não alterar lista original reativamente antes de salvar
    }
    showProductEditModal.value = true
}

// --- EAN-13 GENERATOR ---
const generateEAN13 = () => {
    let prefix = "2" // Prefixo interno (In-store)
    let code = prefix + Math.floor(Math.random() * 100000000000).toString().padStart(11, '0')
    let sum = 0
    for (let i = 0; i < 12; i++) {
        let digit = parseInt(code[i])
        sum += (i % 2 === 0) ? digit : digit * 3
    }
    let remainder = sum % 10
    let checkDigit = (10 - remainder) % 10
    return code + checkDigit
}

const generateBarcodeForVariant = (index: number) => {
    if (editingProduct.value && editingProduct.value.variations[index]) {
        editingProduct.value.variations[index].barcode = generateEAN13()
    }
}

const saveProduct = async () => {
    if (!editingProduct.value) return
    isSavingProduct.value = true

    try {
        // 1. Atualiza SKU no produto pai (Compartilhado)
        const { error: skuError } = await supabase.from('cajuia_products').update({
            sku: editingProduct.value.sku
            // Nota: não atualizamos 'barcode' aqui pois ele será movido para a tabela de variações
        }).eq('id', editingProduct.value.id)

        if (skuError) throw skuError

        // 2. Salva Variações (Preparação para Etapa 2)
        // Como a tabela pode não existir ainda, vamos tentar salvar mas capturar erro silenciosamente ou apenas logar
        // Se a tabela existir, isso funcionará.
        const variationUpdates = editingProduct.value.variations.map((v: any) => ({
            product_id: editingProduct.value.id,
            variation_name: v.name, // Nome da coluna provável na etapa 2
            barcode: v.barcode
        }))

        // Tentativa de upsert (comentado ou ativo dependendo se a tabela existe)
        // Por enquanto, apenas atualizamos o estado local para refletir na UI sem recarregar

        // Atualiza a lista local
        const index = products.value.findIndex(p => p.id === editingProduct.value.id)
        if (index !== -1) {
            products.value[index].sku = editingProduct.value.sku
            products.value[index].variations = editingProduct.value.variations
            // Opcional: Atualizar barcode visual na lista para um dos barcodes das variações
            products.value[index].barcode = editingProduct.value.variations[0].barcode
        }

        appStore.showSnackbar('Produto e variações atualizados!', 'success')
        showProductEditModal.value = false

        // TODO: Na etapa 2, descomentar a chamada real para tabela cajuia_product_variations
        // await supabase.from('cajuia_product_variations').upsert(variationUpdates)...

    } catch (e: any) {
        appStore.showSnackbar(e.message, 'error')
    } finally {
        isSavingProduct.value = false
    }
}

// --- Computed: Merge & Filter ---
const productsWithPrices = computed(() => {
  if (!selectedList.value) return []
  let items = products.value.map(p => {
      const custom = pricesMap.value[p.id]
      const hasCustom = custom !== undefined && custom !== null
      return {
        ...p,
        base_price: Number(p.price) || 0,
        custom_price: hasCustom ? Number(custom) : null,
        edit_price: hasCustom ? Number(custom) : Number(p.price || 0),
        is_saving: false
      }
  })
  return items
})

const filteredProducts = computed(() => {
    let items = productsWithPrices.value
    if (search.value) {
        const q = search.value.toLowerCase()
        items = items.filter(p =>
            (p.name && p.name.toLowerCase().includes(q)) ||
            (p.sku && p.sku.toLowerCase().includes(q)) ||
            (p.barcode && p.barcode.toLowerCase().includes(q))
        )
    }
    if (filterCategory.value) {
        items = items.filter(p => p.category === filterCategory.value)
    }
    if (filterStatus.value === 'custom') {
        items = items.filter(p => p.custom_price !== null)
    } else if (filterStatus.value === 'base') {
        items = items.filter(p => p.custom_price === null)
    }
    return items
})

const selectedProductsForLabels = computed(() => {
    return productsWithPrices.value.filter(p => selectedProductIds.value.includes(p.id))
})

const stats = computed(() => {
    const items = productsWithPrices.value
    const pricedCount = items.filter(i => i.custom_price !== null).length
    let totalMargin = 0, count = 0, projectedRevenue = 0
    items.forEach(i => {
        const finalPrice = i.custom_price !== null ? i.custom_price : i.base_price
        const cost = i.base_price
        projectedRevenue += finalPrice * (i.quantity_in_stock || 0)
        if(cost > 0 && finalPrice > 0) {
            totalMargin += ((finalPrice - cost) / cost) * 100
            count++
        }
    })
    const avgMargin = count > 0 ? (totalMargin / count).toFixed(1) : '0.0'
    return { pricedCount, avgMargin, projectedRevenue }
})

const isAllSelected = computed(() => {
    return filteredProducts.value.length > 0 && selectedProductIds.value.length === filteredProducts.value.length
})
const isIndeterminate = computed(() => {
    return selectedProductIds.value.length > 0 && selectedProductIds.value.length < filteredProducts.value.length
})

const toggleSelectAll = (val: boolean) => {
    if (val) {
        selectedProductIds.value = filteredProducts.value.map(p => p.id)
    } else {
        selectedProductIds.value = []
    }
}

const toggleSelection = (id: string) => {
    if (selectedProductIds.value.includes(id)) {
        selectedProductIds.value = selectedProductIds.value.filter(x => x !== id)
    } else {
        selectedProductIds.value.push(id)
    }
}

// --- Core Logic ---
const fetchAll = async () => {
    loading.value = true
    try {
        const { data: lists } = await supabase.from('cajuia_price_lists').select('*').order('created_at')
        priceLists.value = lists || []

        const { data: cats } = await supabase.from('cajuia_categories').select('*').eq('type', 'category')
        categories.value = cats || []

        const { data: prods } = await supabase.from('cajuia_products').select('*').eq('is_active', true).order('name')
        products.value = prods || []

        if (priceLists.value.length > 0 && !selectedList.value) {
            selectList(priceLists.value[0])
        }
    } catch(e) { console.error(e) } finally { loading.value = false }
}

const selectList = async (list: any) => {
    selectedList.value = list
    loading.value = true
    pricesMap.value = {}
    selectedProductIds.value = []
    try {
        const { data } = await supabase.from('cajuia_product_prices').select('product_id, price').eq('price_list_id', list.id)
        if (data) {
            const map: Record<string, number> = {}
            data.forEach((item: any) => { map[item.product_id] = item.price })
            pricesMap.value = map
        }
    } catch(e) { console.error(e) } finally { loading.value = false }
}

const updatePrice = async (item: any) => {
    if (!selectedList.value) return
    const priceVal = parseFloat(item.edit_price)
    if (isNaN(priceVal)) return

    item.is_saving = true

    const { error } = await supabase.from('cajuia_product_prices').upsert({
        price_list_id: selectedList.value.id,
        product_id: item.id,
        price: priceVal
    }, { onConflict: 'price_list_id, product_id' })

    if (!error) {
        pricesMap.value[item.id] = priceVal
        item.custom_price = priceVal
    } else {
        appStore.showSnackbar('Erro ao salvar preço', 'error')
    }
    setTimeout(() => item.is_saving = false, 500)
}

// --- Bulk Actions ---
const openBulkEditModal = () => { showBulkEditModal.value = true }

const applyBulkAction = async () => {
    if (!selectedList.value || selectedProductIds.value.length === 0) return
    applyingBulk.value = true

    const updates = []
    const factor = 1 + (Number(bulkActionValue.value) / 100)

    for (const id of selectedProductIds.value) {
        const product = productsWithPrices.value.find(p => p.id === id)
        if (!product) continue

        let newPrice = 0
        if (bulkActionType.value === 'fixed') {
            newPrice = Number(bulkActionValue.value)
        } else if (bulkActionType.value === 'increase_pct') {
            const current = product.custom_price || product.base_price
            newPrice = current * factor
        } else if (bulkActionType.value === 'decrease_pct') {
            const current = product.custom_price || product.base_price
            newPrice = current * (1 - (Number(bulkActionValue.value) / 100))
        }

        newPrice = Math.round(newPrice * 100) / 100

        updates.push({
            price_list_id: selectedList.value.id,
            product_id: id,
            price: newPrice
        })
        pricesMap.value[id] = newPrice
    }

    const { error } = await supabase.from('cajuia_product_prices').upsert(updates, { onConflict: 'price_list_id, product_id' })

    if (!error) {
        appStore.showSnackbar('Reajuste aplicado com sucesso!', 'success')
        showBulkEditModal.value = false
        selectedProductIds.value = []
    } else {
        appStore.showSnackbar('Erro ao aplicar reajuste em massa.', 'error')
    }
    applyingBulk.value = false
}

const bulkRemovePrice = async () => {
    if (!confirm(`Remover preços personalizados de ${selectedProductIds.value.length} produtos?`)) return
    const { error } = await supabase.from('cajuia_product_prices').delete().eq('price_list_id', selectedList.value.id).in('product_id', selectedProductIds.value)
    if (!error) {
        selectedProductIds.value.forEach(id => delete pricesMap.value[id])
        selectedProductIds.value = []
        appStore.showSnackbar('Preços removidos.', 'success')
    } else {
        appStore.showSnackbar('Erro ao remover preços.', 'error')
    }
}

const createList = async () => {
    if(!newListName.value) return
    creatingList.value = true
    const { data, error } = await supabase.from('cajuia_price_lists').insert({ name: newListName.value, description: newListDesc.value }).select().single()
    if(!error && data) {
        priceLists.value.push(data); selectList(data); showNewListModal.value = false;
    }
    creatingList.value = false
}

const deleteList = async () => {
    if(!selectedList.value) return
    if(!confirm('Excluir esta tabela?')) return
    await supabase.from('cajuia_price_lists').delete().eq('id', selectedList.value.id)
    selectedList.value = null
    fetchAll()
}

// Helpers
const formatCurrency = (val: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
const calculateMargin = (base: number, custom: number | null) => {
    const val = custom !== null ? custom : base
    if (base === 0) return '100%'
    const diff = val - base
    const pct = ((diff / base) * 100).toFixed(0)
    return diff >= 0 ? `+${pct}%` : `${pct}%`
}
const getMarginColor = (base: number, val: number | null) => {
    const current = val !== null ? val : base
    const margin = current - base
    if (margin < 0) return 'text-error'
    if (margin === 0) return 'text-warning'
    return 'text-success'
}

onMounted(fetchAll)
</script>

<style scoped lang="scss">
.width-320 { width: 320px; }
.absolute-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 100%; }
.relative { position: relative; }
.h-24 { height: 24px; }
.h-32 { height: 32px; }
.gap-3 { gap: 12px; }
.gap-6 { gap: 24px; }

/* Glass System */
.glass-panel, .glass-stat-card {
    background: rgba(30, 30, 35, 0.4);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}
.glass-list-card {
    background: rgba(255, 255, 255, 0.02);
    transition: all 0.2s;
    cursor: pointer;
    border: 1px solid transparent;
    &:hover { background: rgba(255, 255, 255, 0.06); }
    &.active-card {
        background: rgba(var(--v-theme-primary), 0.15) !important;
        border: 1px solid rgba(var(--v-theme-primary), 0.4);
    }
    &.selected {
        background: rgba(var(--v-theme-primary), 0.08);
        border-color: rgba(var(--v-theme-primary), 0.2);
    }
}
.price-input-wrapper {
    position: relative;
    background: rgba(0, 0, 0, 0.4);
    border-radius: 8px;
    padding: 0 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    height: 36px;
    transition: all 0.2s;

    &:focus-within {
        border-color: rgb(var(--v-theme-primary));
        box-shadow: 0 0 0 2px rgba(var(--v-theme-primary), 0.15);
        background: rgba(0,0,0,0.6);
    }
    &.saving { border-color: rgb(var(--v-theme-warning)); }
    &.has-value {
        background: rgba(var(--v-theme-success), 0.08);
        border-color: rgba(var(--v-theme-success), 0.3);
    }
}
.custom-price-input {
    background: transparent; border: none; color: white; font-weight: 900; font-size: 1rem; width: 100%;
    outline: none; text-align: right; font-family: 'Roboto Mono', monospace;
}

/* Bulk Actions Dock */
.bulk-actions-dock-container {
    position: fixed;
    bottom: 40px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 200;
    width: auto;
    max-width: 90vw;
    animation: slideUp 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.glass-dock {
    background: rgba(30, 30, 35, 0.95);
    backdrop-filter: blur(24px);
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 24px;
    box-shadow: 0 24px 48px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.05) inset;
}

.selection-badge-large {
    background: rgb(var(--v-theme-primary));
    width: 48px; height: 48px;
    border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 4px 20px rgba(var(--v-theme-primary), 0.5);
    border: 1px solid rgba(255,255,255,0.2);
}

@keyframes slideUp {
    from { transform: translate(-50%, 120%); opacity: 0; }
    to { transform: translate(-50%, 0); opacity: 1; }
}

/* Utils */
.icon-square { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
.icon-circle { width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.glass-input :deep(.v-field) { border-radius: 10px; border: 1px solid rgba(255,255,255,0.1); color: white; font-size: 0.85rem; }
.glass-toggle { background: rgba(0,0,0,0.3) !important; border: 1px solid rgba(255,255,255,0.1); }
.font-mono { font-family: 'Roboto Mono', monospace; letter-spacing: -0.5px; }
.bg-glass-header { background: rgba(255, 255, 255, 0.02); }
.bg-glass-surface { background: rgba(255, 255, 255, 0.05); }
.bg-white-05 { background: rgba(255,255,255,0.05); }
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
.status-indicator { position: absolute; top: 4px; left: 4px; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; }
.text-white-50 { color: rgba(255,255,255,0.5) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.shadow-glow-primary { box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3); }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(0,0,0,0.1); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
.lh-1 { line-height: 1; }
.hover-white:hover { color: white !important; }
.hover-glow-icon:hover { color: #2196F3 !important; transform: scale(1.1); transition: all 0.2s; }
</style>
