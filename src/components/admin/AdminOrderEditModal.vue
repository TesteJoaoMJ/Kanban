<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    width="1300"
    max-width="96vw"
    height="90vh"
    class="glass-modal-wrapper font-sans"
    transition="dialog-bottom-transition"
    scrollable
    persistent
  >
    <div class="d-flex flex-column h-100 overflow-hidden relative rounded-lg border-thin shadow-2xl transition-all" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-grey-lighten-5 text-grey-darken-4'">

      <div v-if="isLoading" class="absolute-fill d-flex flex-column justify-center align-center z-50 glass-overlay" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
          <v-progress-circular indeterminate color="info" size="64" width="4"></v-progress-circular>
          <div class="mt-6 text-subtitle-2 font-weight-black tracking-wide text-uppercase opacity-70">Sincronizando Dados...</div>
      </div>

      <div v-else-if="!localOrder && !isLoading" class="absolute-fill d-flex flex-column justify-center align-center z-50 glass-overlay" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
          <div class="pa-6 rounded-circle mb-4" :class="isDark ? 'bg-red-darken-4' : 'bg-red-lighten-5'">
              <v-icon color="error" size="64">mdi-database-remove-outline</v-icon>
          </div>
          <div class="text-h5 font-weight-black tracking-tight">Pedido não localizado</div>
          <div class="text-body-2 font-weight-medium opacity-70 mb-8 mt-2">O identificador fornecido não consta nas bases ativas do sistema.</div>
          <v-btn color="primary" variant="flat" class="font-weight-black btn-3d px-10 text-body-1" height="48" @click="$emit('close')">Retornar</v-btn>
      </div>

      <template v-else>
        <div class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex align-center justify-space-between flex-shrink-0 z-30 relative shadow-sm" :class="isDark ? 'bg-glass-header border-bottom-white-05' : 'bg-white border-b border-grey-lighten-2'">
          <div class="d-flex align-center gap-4">
              <div class="rounded-lg d-flex align-center justify-center shadow-sm" style="width: 48px; height: 48px;" :class="isStoreSale ? 'bg-teal-darken-3' : 'bg-indigo-darken-3'">
                <v-icon size="24" color="white">{{ isStoreSale ? 'mdi-storefront-outline' : 'mdi-domain' }}</v-icon>
              </div>
              <div class="d-flex flex-column justify-center">
                <div class="d-flex align-center gap-2 mb-1">
                    <v-chip size="small" :color="isStoreSale ? 'teal-darken-2' : 'indigo-darken-2'" variant="flat" class="font-weight-black text-uppercase tracking-wide px-2 text-[10px] chip-3d">
                        {{ isStoreSale ? 'Venda Balcão (PDV)' : 'Corporativo (B2B)' }}
                    </v-chip>
                    <span class="text-[11px] font-weight-bold font-mono opacity-60">
                        REF: {{ safeId }}
                    </span>
                </div>
                <h2 class="text-h5 font-weight-black lh-1 tracking-tight" :class="isDark ? 'text-white' : 'text-grey-darken-4'">
                    Pedido #{{ safeOrderNumber }}
                </h2>
              </div>
          </div>
          <v-btn icon variant="text" class="btn-3d" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'" @click="$emit('close')">
              <v-icon size="24">mdi-close</v-icon>
          </v-btn>
        </div>

        <div class="d-flex flex-column flex-md-row flex-grow-1 overflow-hidden relative z-20">

            <div class="sidebar-panel d-flex flex-column h-100 border-r" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'" style="width: 340px; flex-shrink: 0;">
                <div class="flex-grow-1 overflow-y-auto custom-scroll pa-5 d-flex flex-column gap-4">

                    <v-card class="kpi-card bg-gradient-success hover-elevate py-4 px-5 rounded-lg shadow-sm position-relative overflow-hidden" elevation="2">
                      <div class="kpi-bg-icon"><v-icon>mdi-cash-register</v-icon></div>
                      <div class="position-relative z-10 text-center text-white">
                          <div class="text-[11px] font-weight-black text-uppercase tracking-widest mb-1 opacity-80">Valor Total Faturado</div>
                          <div class="text-h3 font-weight-black lh-1 tracking-tighter mb-2">
                              {{ formatCurrencySafe(localOrder?.total_value || localOrder?.value) }}
                          </div>
                          <div class="d-inline-flex align-center justify-center gap-1 text-[10px] font-weight-bold font-mono px-3 py-1 rounded-pill bg-black-20">
                              <v-icon size="12">mdi-calendar-check</v-icon> {{ formatDateSafe(localOrder?.date_sale || localOrder?.created_at) }}
                          </div>
                      </div>
                    </v-card>

                    <div class="mt-2 text-[11px] font-weight-black text-uppercase tracking-widest opacity-60 d-flex align-center gap-2 px-1">
                        <v-icon size="16">mdi-shield-search</v-icon> Painel de Auditoria
                    </div>

                    <div class="d-flex flex-column gap-3">
                        <div class="pa-3 rounded-lg border-thin d-flex align-center gap-3 shadow-sm transition-all" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white border-grey-lighten-2'">
                            <v-avatar size="38" :color="financialSeal.color" variant="tonal" class="rounded-lg shadow-inner"><v-icon size="20">{{ financialSeal.icon }}</v-icon></v-avatar>
                            <div class="d-flex flex-column">
                                <span class="text-[9px] text-uppercase font-weight-black opacity-60 tracking-widest">Financeiro</span>
                                <span class="text-body-2 font-weight-black" :class="`text-${financialSeal.color}`">{{ financialSeal.label }}</span>
                            </div>
                        </div>

                        <div class="pa-3 rounded-lg border-thin d-flex align-center gap-3 shadow-sm transition-all" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white border-grey-lighten-2'">
                            <v-avatar size="38" :color="fiscalSeal.color" variant="tonal" class="rounded-lg shadow-inner"><v-icon size="20">{{ fiscalSeal.icon }}</v-icon></v-avatar>
                            <div class="d-flex flex-column overflow-hidden w-100">
                                <span class="text-[9px] text-uppercase font-weight-black opacity-60 tracking-widest">Documento Fiscal</span>
                                <span class="text-body-2 font-weight-black text-truncate" :class="`text-${fiscalSeal.color}`">{{ fiscalSeal.label }}</span>
                                <span v-if="fiscalSeal.key" class="text-[9px] font-mono opacity-60 text-truncate mt-1" :title="fiscalSeal.key">{{ fiscalSeal.key }}</span>
                            </div>
                        </div>

                        <div class="pa-3 rounded-lg border-thin d-flex align-center gap-3 shadow-sm transition-all" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white border-grey-lighten-2'">
                            <v-avatar size="38" :color="bankSeal.color" variant="tonal" class="rounded-lg shadow-inner"><v-icon size="20">{{ bankSeal.icon }}</v-icon></v-avatar>
                            <div class="d-flex flex-column">
                                <span class="text-[9px] text-uppercase font-weight-black opacity-60 tracking-widest">Banco Central</span>
                                <span class="text-body-2 font-weight-black" :class="`text-${bankSeal.color}`">{{ bankSeal.label }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="pa-5 border-t mt-auto shadow-up" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white border-grey-lighten-2'">
                    <v-btn
                      block
                      size="large"
                      class="btn-3d font-weight-black text-white tracking-widest shadow-button"
                      height="52"
                      @click="goToManagementScreen"
                      :color="isStoreSale ? 'teal-darken-2' : 'indigo-darken-2'"
                    >
                        <v-icon start size="20">mdi-pencil-box-multiple</v-icon>
                        EDITAR NO MÓDULO
                    </v-btn>
                </div>
            </div>

            <div class="d-flex flex-column relative flex-grow-1 h-100 min-w-0" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">

                <div class="px-6 pt-3 pb-0 flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-b border-white-10' : 'bg-white border-b border-grey-lighten-2'">
                    <v-tabs v-model="activeTab" :color="isStoreSale ? 'teal' : 'indigo'" density="comfortable" class="font-weight-bold" slider-color="current">
                        <v-tab value="overview" class="text-[11px] text-uppercase tracking-wide"><v-icon start size="small" class="mr-2">mdi-text-box-search-outline</v-icon> Dossiê Geral</v-tab>
                        <v-tab value="items" class="text-[11px] text-uppercase tracking-wide"><v-icon start size="small" class="mr-2">mdi-package-variant-closed</v-icon> Escopo ({{ normalizedItems.length }})</v-tab>
                        <v-tab value="finance" class="text-[11px] text-uppercase tracking-wide"><v-icon start size="small" class="mr-2">mdi-bank-transfer</v-icon> Fluxo ({{ receivablesData.length }})</v-tab>
                    </v-tabs>
                </div>

                <v-window v-model="activeTab" class="flex-grow-1 overflow-hidden h-100 window-fade">

                    <v-window-item value="overview" class="h-100">
                        <div class="h-100 overflow-y-auto custom-scroll pa-6 d-flex flex-column gap-6">

                            <div class="d-flex flex-column gap-3">
                                <div class="d-flex align-center gap-2 px-1">
                                    <div class="title-indicator" :class="isStoreSale ? 'bg-teal' : 'bg-indigo'"></div>
                                    <span class="text-[12px] font-weight-black text-uppercase tracking-widest opacity-80">Qualificação do Cliente</span>
                                </div>
                                <v-card class="pa-5 rounded-lg border-thin shadow-sm" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white'" elevation="0">
                                    <div class="d-flex align-center gap-4 mb-4">
                                        <v-avatar size="56" :color="isDark ? 'blue-grey-darken-3' : 'blue-grey-lighten-4'" class="text-blue-grey-darken-1 font-weight-black text-h5 shadow-inner">
                                            {{ safeAvatarLetter }}
                                        </v-avatar>
                                        <div>
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-60 tracking-widest mb-1">Razão Social / Nome</div>
                                            <div class="text-h6 font-weight-black lh-1">{{ customerData?.nome || localOrder?.customer_name || 'Consumidor Final / Não Vinculado' }}</div>
                                        </div>
                                    </div>
                                    <v-divider class="my-4 border-dashed" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'"></v-divider>
                                    <v-row dense class="mt-2 row-gap">
                                        <v-col cols="12" md="6">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-50 tracking-widest mb-1">Documento Oficial</div>
                                            <div class="text-body-2 font-mono font-weight-bold d-flex align-center gap-2">
                                                <v-icon size="16" class="opacity-70">mdi-identifier</v-icon> {{ customerData?.cnpj || customerData?.cpf || 'Não Informado' }}
                                            </div>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-50 tracking-widest mb-1">Contato Principal</div>
                                            <div class="text-body-2 font-weight-bold d-flex align-center gap-2">
                                                <v-icon size="16" class="opacity-70">mdi-phone</v-icon> {{ customerData?.telefone || customerData?.celular || 'Não Informado' }}
                                            </div>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-50 tracking-widest mb-1">Endereço de Faturamento</div>
                                            <div v-if="customerData?.endereco" class="text-body-2 font-weight-medium lh-1-5 d-flex align-start gap-2">
                                                <v-icon size="16" class="opacity-70 mt-1">mdi-map-marker-radius</v-icon>
                                                <div>
                                                    <span class="font-weight-black">{{ customerData.endereco }}, {{ customerData.numero || 'S/N' }}</span><br>
                                                    <span class="opacity-80">{{ customerData.bairro || 'Bairro S/N' }}</span><br>
                                                    <span class="opacity-80">{{ customerData.cidade || 'Cidade S/N' }} - {{ customerData.estado || 'UF' }}</span><br>
                                                    <span class="font-mono text-[11px] font-weight-bold opacity-60 mt-1 d-block">CEP: {{ customerData.cep || '00000-000' }}</span>
                                                </div>
                                            </div>
                                            <div v-else class="text-body-2 font-weight-bold opacity-50 font-italic mt-1 d-flex align-center gap-2">
                                                <v-icon size="16">mdi-map-marker-off</v-icon> Endereço não cadastrado.
                                            </div>
                                        </v-col>
                                        <v-col cols="12" md="6">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-50 tracking-widest mb-1">E-mail</div>
                                            <div class="text-body-2 font-weight-bold d-flex align-center gap-2">
                                                <v-icon size="16" class="opacity-70">mdi-email-outline</v-icon> {{ customerData?.email || 'Não Informado' }}
                                            </div>
                                        </v-col>
                                    </v-row>
                                </v-card>
                            </div>

                            <div class="d-flex flex-column gap-3">
                                <div class="d-flex align-center gap-2 px-1">
                                    <div class="title-indicator" :class="isStoreSale ? 'bg-teal' : 'bg-indigo'"></div>
                                    <span class="text-[12px] font-weight-black text-uppercase tracking-widest opacity-80">Detalhes da Operação</span>
                                </div>
                                <v-row dense class="row-gap">
                                    <v-col cols="12" md="6">
                                        <v-card class="pa-4 rounded-lg border-thin shadow-sm h-100" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white'" elevation="0">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-60 tracking-widest mb-2">Vendedor / Emissor</div>
                                            <div class="d-flex align-center gap-3">
                                                <v-avatar size="32" :color="isStoreSale ? 'teal-darken-3' : 'indigo-darken-3'" class="text-white font-weight-black shadow-sm"><v-icon size="16">mdi-tie</v-icon></v-avatar>
                                                <span class="text-body-2 font-weight-black">{{ sellerName }}</span>
                                            </div>
                                        </v-card>
                                    </v-col>
                                    <v-col cols="12" md="6">
                                        <v-card class="pa-4 rounded-lg border-thin shadow-sm h-100" :class="isDark ? 'bg-white-05 border-white-10' : 'bg-white'" elevation="0">
                                            <div class="text-[10px] text-uppercase font-weight-black opacity-60 tracking-widest mb-2">Observações Internas</div>
                                            <div class="text-[13px] font-weight-medium rounded pa-3" :class="isDark ? 'bg-black-20 text-white-70' : 'bg-grey-lighten-5 text-grey-darken-3'" style="white-space: pre-wrap; min-height: 48px;">
                                                {{ localOrder?.observation || localOrder?.notes || 'Nenhuma observação ou instrução especial registrada.' }}
                                            </div>
                                        </v-card>
                                    </v-col>
                                </v-row>
                            </div>

                        </div>
                    </v-window-item>

                    <v-window-item value="items" class="h-100">
                        <div class="h-100 overflow-y-auto custom-scroll d-flex flex-column pa-6">
                            <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden shadow-sm" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white'" elevation="0">

                                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
                                    <div class="grid-header sticky-head" :class="[isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2']" style="grid-template-columns: minmax(200px, 2fr) 120px 90px 90px 120px 140px;">
                                        <div class="cell header-text">Produto Base / Variação</div>
                                        <div class="cell center header-text">SKU / NCM</div>
                                        <div class="cell center header-text">Tamanho</div>
                                        <div class="cell center header-text">QTD (UN)</div>
                                        <div class="cell right header-text">V. Unitário</div>
                                        <div class="cell right header-text">Subtotal</div>
                                    </div>

                                    <div v-if="normalizedItems.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
                                        <v-icon size="48" color="grey-lighten-1">mdi-package-variant-closed</v-icon>
                                        <span class="text-body-2 font-weight-medium">Nenhum item faturado.</span>
                                    </div>

                                    <div v-else v-for="(item, i) in normalizedItems" :key="i" class="grid-row" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(i)]" style="grid-template-columns: minmax(200px, 2fr) 120px 90px 90px 120px 140px;">
                                        <div class="cell">
                                            <span class="text-body-2 font-weight-black tracking-tight" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ item.name }}</span>
                                        </div>
                                        <div class="cell center flex-column align-center justify-center">
                                            <span class="text-[11px] font-weight-black font-mono" :class="isDark ? 'text-white' : 'text-grey-darken-3'">{{ item.sku }}</span>
                                            <span class="text-[9px] font-weight-bold font-mono opacity-50">{{ item.ncm }}</span>
                                        </div>
                                        <div class="cell center">
                                            <v-chip size="x-small" variant="tonal" :color="isDark ? 'grey-lighten-1' : 'grey-darken-2'" class="font-weight-black px-2 shadow-sm font-mono chip-3d">{{ item.size }}</v-chip>
                                        </div>
                                        <div class="cell center">
                                            <span class="text-body-1 font-weight-black font-mono" :class="isStoreSale ? 'text-teal-darken-2' : 'text-indigo-darken-2'">{{ item.qty }} {{ item.uom }}</span>
                                        </div>
                                        <div class="cell right">
                                            <span class="text-[13px] font-mono font-weight-bold opacity-70">{{ formatCurrencySafe(item.unit_price) }}</span>
                                        </div>
                                        <div class="cell right">
                                            <span class="text-subtitle-1 font-weight-black font-mono" :class="isDark ? 'text-success-lighten-1' : 'text-success-darken-2'">{{ formatCurrencySafe(item.total) }}</span>
                                        </div>
                                    </div>
                                </div>

                                <div class="px-6 py-3 d-flex justify-end align-center flex-shrink-0 border-t z-20" :class="isDark ? 'bg-glass-header border-white-05' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                                    <div class="d-flex align-center gap-4">
                                        <span class="text-[11px] text-uppercase font-weight-black tracking-widest opacity-60">Soma dos Itens</span>
                                        <span class="text-h5 font-weight-black font-mono" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ formatCurrencySafe(localOrder?.total_value || 0) }}</span>
                                    </div>
                                </div>
                            </v-card>
                        </div>
                    </v-window-item>

                    <v-window-item value="finance" class="h-100">
                        <div class="h-100 overflow-y-auto custom-scroll d-flex flex-column pa-6">

                            <v-card class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden shadow-sm" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-white'" elevation="0">
                                <div class="grid-header sticky-head" :class="[isDark ? 'grid-surface-dark border-bottom-white-05' : 'grid-surface-light border-b border-grey-lighten-2']" style="grid-template-columns: minmax(200px, 2fr) 100px 100px 100px 100px 140px;">
                                    <div class="cell header-text">Descrição / Método</div>
                                    <div class="cell center header-text">Vencimento</div>
                                    <div class="cell center header-text">Recebimento</div>
                                    <div class="cell center header-text">Status</div>
                                    <div class="cell center header-text">Conciliado</div>
                                    <div class="cell right header-text">Valor (R$)</div>
                                </div>

                                <div class="grid-scroll flex-grow-1 overflow-y-auto custom-scroll relative">
                                    <div v-if="receivablesData.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
                                        <v-icon size="48" color="grey-lighten-1">mdi-cash-remove</v-icon>
                                        <span class="text-body-2 font-weight-medium">Nenhum título financeiro gerado.</span>
                                    </div>

                                    <div v-else v-for="(rec, i) in receivablesData" :key="i" class="grid-row" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(i)]" style="grid-template-columns: minmax(200px, 2fr) 100px 100px 100px 100px 140px;">
                                        <div class="cell flex-column align-start justify-center">
                                            <div class="text-[12px] font-weight-black tracking-tight text-truncate w-100" :title="rec.description">{{ rec.description || 'Lançamento Genérico' }}</div>
                                            <div class="d-inline-flex align-center mt-1 px-1 rounded text-[9px] font-weight-black text-uppercase tracking-widest" :class="isDark ? 'bg-black-40 text-white-50' : 'bg-grey-lighten-3 text-grey-darken-2'">
                                                <v-icon size="10" class="mr-1">mdi-credit-card-outline</v-icon> {{ rec.payment_method || 'A DEFINIR' }}
                                            </div>
                                        </div>
                                        <div class="cell center">
                                            <span class="text-[12px] font-mono font-weight-bold" :class="isDark ? 'text-white-70' : 'text-grey-darken-3'">{{ formatDatesOnly(rec.due_date) }}</span>
                                        </div>
                                        <div class="cell center">
                                            <span v-if="rec.payment_date" class="text-[12px] font-mono text-success font-weight-black">{{ formatDatesOnly(rec.payment_date) }}</span>
                                            <span v-else class="opacity-40">-</span>
                                        </div>
                                        <div class="cell center">
                                            <span class="solid-chip chip-3d" :class="rec.status === 'pago' ? 'chip-success' : 'chip-warning'" style="font-size: 9px; height: 22px; padding: 0 8px;">
                                                {{ rec.status === 'pago' ? 'PAGO' : 'ABERTO' }}
                                            </span>
                                        </div>
                                        <div class="cell center">
                                            <div v-if="rec.reconciliation_status === 'CONCILIATED'" class="d-inline-flex align-center justify-center pa-1 rounded-circle bg-teal-lighten-5 border border-teal-lighten-3" title="Conciliado com Banco">
                                                <v-icon size="14" color="teal-darken-3">mdi-check-decagram</v-icon>
                                            </div>
                                            <v-icon v-else size="18" class="opacity-20">mdi-minus</v-icon>
                                        </div>
                                        <div class="cell right">
                                            <span class="text-subtitle-1 font-weight-black font-mono" :class="rec.status === 'pago' ? (isDark ? 'text-success-lighten-1' : 'text-success-darken-2') : (isDark ? 'text-white' : 'text-grey-darken-4')">
                                                {{ formatCurrencySafe(rec.value) }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </v-card>

                        </div>
                    </v-window-item>

                </v-window>
            </div>

        </div>
      </template>
    </div>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';

const props = defineProps<{
  show: boolean;
  orderId?: string;
}>();

const emit = defineEmits<{ (e: 'close'): void; }>();

const themeStore = useThemeStore();
const appStore = useAppStore();
const isDark = computed(() => themeStore.currentMode !== 'light');

// ESTADOS GLOBAIS DO MODAL
const localOrder = ref<any>(null);
const customerData = ref<any>(null);
const receivablesData = ref<any[]>([]);

const isLoading = ref(false);
const isStoreSale = ref(false);
const activeTab = ref('overview');
const sellerName = ref('Desconhecido');

// FUNÇÕES SEGURAS (BLINDADAS CONTRA UNDEFINED)
const safeId = computed(() => {
    try { return String(localOrder.value?.id || '00000000').substring(0,8).toUpperCase(); }
    catch(e) { return 'S/N'; }
});

const safeOrderNumber = computed(() => {
    try { return String(localOrder.value?.order_number || '0').padStart(4, '0'); }
    catch(e) { return 'S/N'; }
});

const safeAvatarLetter = computed(() => {
    try { return String(customerData.value?.nome || localOrder.value?.customer_name || 'C').charAt(0).toUpperCase(); }
    catch(e) { return 'C'; }
});

const formatCurrencySafe = (val: any) => {
    try { return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val) || 0); }
    catch(e) { return 'R$ 0,00'; }
};

const formatDateSafe = (d: any) => {
    if (!d) return '-';
    try {
        const parts = String(d).split('T')[0].split('-');
        if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
        return '-';
    }
    catch(e) { return '-'; }
};

const formatDatesOnly = (d: any) => {
    if (!d) return '-';
    try {
        const parts = String(d).substring(0, 10).split('-');
        if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
        return '-';
    }
    catch(e) { return '-'; }
};

// COMPUTEDS DE SELOS
const fiscalSeal = computed(() => {
    try {
        if (!localOrder.value) return { label: 'Aguardando', icon: 'mdi-minus-circle-outline', color: 'grey', key: '' };
        const key = localOrder.value.nfe_key || localOrder.value.nfe_number;
        const type = localOrder.value.fiscal_type || (key?.length === 44 && key.substring(20, 22) === '55' ? 'NFe' : (key?.length === 44 ? 'NFCe' : ''));

        if (key && key.includes('MANUAL')) return { label: `Selo Manual (${type})`, icon: 'mdi-tag-check', color: 'blue-grey', key: key };
        if (key) return { label: `Autorizado: ${type || 'Doc'}`, icon: 'mdi-check-decagram', color: 'success', key: key };

        return { label: 'Sem Emissão', icon: 'mdi-alert-circle-outline', color: 'orange-darken-2', key: '' };
    } catch(e) { return { label: 'Erro Leitura', icon: 'mdi-alert', color: 'red', key: '' }; }
});

const bankSeal = computed(() => {
    try {
        if (receivablesData.value.length === 0) return { label: 'Sem Lançamentos', icon: 'mdi-bank-minus', color: 'grey' };
        const hasConciliated = receivablesData.value.some(r => r.reconciliation_status === 'CONCILIATED');
        if (hasConciliated) return { label: '100% Conciliado', icon: 'mdi-bank-check', color: 'teal' };
        return { label: 'Pendente de Extrato', icon: 'mdi-bank-outline', color: 'orange-darken-2' };
    } catch(e) { return { label: 'Erro', icon: 'mdi-alert', color: 'red' }; }
});

const financialSeal = computed(() => {
    try {
        if (!localOrder.value) return { label: 'Desconhecido', icon: 'mdi-help-circle', color: 'grey' };
        const st = String(localOrder.value.financial_status || localOrder.value.status).toLowerCase();
        if (st === 'faturado' || st === 'pago' || st === 'completed') return { label: 'Liquidação Total', icon: 'mdi-cash-check', color: 'success' };
        if (st.includes('parcial')) return { label: 'Amortização Parcial', icon: 'mdi-cash-multiple', color: 'warning' };
        return { label: 'Títulos Pendentes', icon: 'mdi-cash-clock', color: 'error' };
    } catch(e) { return { label: 'Erro', icon: 'mdi-alert', color: 'red' }; }
});

// BUSCA DE DADOS
const loadOrderData = async (id: string) => {
    isLoading.value = true;
    localOrder.value = null;
    customerData.value = null;
    receivablesData.value = [];
    sellerName.value = 'Desconhecido';

    try {
        if (!id || id === 'undefined' || id === 'null') throw new Error('ID fornecido é inválido.');

        const { data: ord } = await supabase.from('orders').select('*, order_items(*)').eq('id', id).maybeSingle();
        if (ord) {
            localOrder.value = ord;
            isStoreSale.value = false;
            if (ord.created_by) await fetchSellerName(ord.created_by);
        } else {
            const { data: stSale } = await supabase.from('store_sales').select('*').eq('id', id).maybeSingle();
            if (stSale) {
                localOrder.value = stSale;
                isStoreSale.value = true;
                if (stSale.seller_name) sellerName.value = stSale.seller_name;
                else if (stSale.seller_id) await fetchSellerName(stSale.seller_id);
            } else {
                throw new Error('Pedido não localizado.');
            }
        }

        if (localOrder.value.customer_id) {
            const { data: cust } = await supabase.from('customers_mj').select('*').eq('id', localOrder.value.customer_id).maybeSingle();
            if (cust) customerData.value = cust;
        }

        const recColumn = isStoreSale.value ? 'store_sale_id' : 'order_id';
        const { data: recs } = await supabase.from('finance_receivables')
            .select('id, description, value, status, due_date, payment_date, reconciliation_status, bank_fitid, payment_method')
            .eq(recColumn, localOrder.value.id)
            .order('due_date', { ascending: true });

        if (recs) receivablesData.value = recs;

    } catch(e: any) {
        appStore.showSnackbar('Erro: ' + e.message, 'error');
        emit('close');
    } finally {
        isLoading.value = false;
    }
};

const fetchSellerName = async (userId: string) => {
    try {
        const { data } = await supabase.from('profiles').select('full_name').eq('id', userId).single();
        if (data) sellerName.value = data.full_name;
    } catch(e) { }
};

onMounted(() => {
    activeTab.value = 'overview';
    if (props.orderId && props.orderId !== 'undefined') {
        loadOrderData(props.orderId);
    } else {
        appStore.showSnackbar('ID do pedido ausente na abertura.', 'error');
        emit('close');
    }
});

// NORMALIZADOR DE ITENS
const normalizedItems = computed(() => {
    if (!localOrder.value) return [];
    try {
        if (isStoreSale.value) {
            let rawItems = localOrder.value.items || [];
            if (typeof rawItems === 'string') rawItems = JSON.parse(rawItems);

            return rawItems.map((i: any) => {
                const prod = i.produto || i;
                let uom = prod.unit_of_measure || prod.unidade || 'UN';
                if (String(prod.nome_produto).toLowerCase().includes('metro') || String(prod.fabric_type).toLowerCase().includes('metro')) uom = 'MT';
                if (String(prod.nome_produto).toLowerCase().includes('kg')) uom = 'KG';

                return {
                    name: String(prod.nome_produto || prod.descricao || prod.fabric_type || prod.name || 'Item Diverso'),
                    size: String(prod.tamanho || prod.size || 'U'),
                    qty: Number(prod.quantidade || prod.quantity_meters || prod.quantity || 1),
                    unit_price: Number(prod.valor_unitario || prod.unit_price || 0),
                    total: Number(prod.valor_total || prod.total_value_items || 0),
                    sku: String(prod.codigo || prod.sku || 'S/N'),
                    ncm: String(prod.ncm || 'S/N'),
                    uom: String(uom).toUpperCase()
                }
            });
        } else {
            const rawItems = localOrder.value.order_items || localOrder.value.items || [];
            return rawItems.map((i: any) => {
                let uom = i.unit_of_measure || 'MT';
                if (String(i.fabric_type).toLowerCase().includes('unidade') || String(i.fabric_type).toLowerCase().includes('peça')) uom = 'UN';

                return {
                    name: String(i.fabric_type || i.description || 'Produto Produção'),
                    size: String(i.size || 'U'),
                    qty: Number(i.quantity_meters || i.quantity || 1),
                    unit_price: Number(i.unit_price || 0),
                    total: Number(i.total_value_items || i.total_value || 0),
                    sku: String(i.codigo || i.sku || 'S/N'),
                    ncm: String(i.ncm || 'S/N'),
                    uom: String(uom).toUpperCase()
                }
            });
        }
    } catch (err) {
        console.error('Erro ao processar itens', err);
        return [];
    }
});

const zebraClass = (index: number) => isDark.value ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

const goToManagementScreen = () => {
    // Salva o número do pedido em cache para preencher o campo de busca
    if (localOrder.value?.order_number) {
        localStorage.setItem('mj_auto_search_order', String(localOrder.value.order_number));
    }

    // Força o NAVEGADOR a fazer o redirect nativo (Evita a falha do Vue Router com Transitions em andamento)
    const url = isStoreSale.value ? '/admin/store-sales' : '/admin/orders';
    window.location.href = url;
};

</script>

<style scoped lang="scss">
.absolute-fill { position: absolute; top: 0; left: 0; right: 0; bottom: 0; }
.lh-1 { line-height: 1; }
.lh-1-5 { line-height: 1.5; }
.tracking-tight { letter-spacing: -0.5px; }
.tracking-tighter { letter-spacing: -1px; }
.tracking-wide { letter-spacing: 0.5px; }
.tracking-widest { letter-spacing: 1px; }

/* Tipografia Micro */
.text-\[9px\] { font-size: 9px !important; }
.text-\[10px\] { font-size: 10px !important; }
.text-\[11px\] { font-size: 11px !important; }
.text-\[12px\] { font-size: 12px !important; }
.text-\[13px\] { font-size: 13px !important; }

/* CORES E BORDAS */
.bg-white-05 { background-color: rgba(255,255,255,0.05); }
.bg-black-20 { background-color: rgba(0,0,0,0.2); }
.bg-glass-dark { background: rgba(10,10,12,0.85); backdrop-filter: blur(14px); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }

.border-b-dark { border-bottom: 1px solid rgba(255,255,255,0.08) !important; }
.border-b-light { border-bottom: 1px solid rgba(0,0,0,0.08) !important; }
.border-r { border-right: 1px solid rgba(0,0,0,0.12) !important; }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.12) !important; }

/* GRID SYSTEM REPLICA DO ADMINMJRECEIVABLES */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.08); }
.grid-header { border-bottom-width: 2px; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); min-height: 56px; overflow: hidden; transition: background-color 0.2s ease; }
.cell:last-child { border-right: none; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 11px !important; }
.center { justify-content: center; text-align: center; }
.right { justify-content: flex-end; text-align: right; }

.grid-surface-light { background: #f5f7fa; color: rgba(0,0,0,0.9); }
.grid-surface-light .cell { border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; }
.grid-surface-dark .cell { border-color: rgba(255,255,255,0.10) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f8f9fa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }

.sticky-head { position: sticky; top: 0; z-index: 10; }

/* WIDGETS & CONTAINERS */
.title-indicator { width: 4px; height: 24px; border-radius: 4px; }

/* KPI VALOR GIGANTE */
.bg-gradient-success { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; border-radius: 8px;}
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }

/* BOTÕES PREMIUM */
.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 2px 4px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 26px; padding: 0 12px; border-radius: 6px; font-size: 11px; font-weight: 900; color: #fff; white-space: nowrap; text-transform: uppercase; }
.chip-success { background: #2e7d32; }
.chip-warning { background: #f57f17; }

/* UTILITÁRIOS GERAIS */
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.shadow-up { box-shadow: 0 -4px 10px rgba(0,0,0,0.05); }
.shadow-inner { box-shadow: inset 0 2px 5px rgba(0,0,0,0.1); }
.glass-modal-wrapper { backdrop-filter: blur(12px); }
.glass-overlay { background: rgba(0,0,0,0.6); backdrop-filter: blur(8px); }

/* ANIMATIONS */
.window-fade-enter-active, .window-fade-leave-active { transition: opacity 0.3s ease; }
.window-fade-enter-from, .window-fade-leave-to { opacity: 0; }
</style>
