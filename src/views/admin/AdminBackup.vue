<template>
  <div class="enterprise-layout d-flex flex-column h-100 w-100 overflow-hidden" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-background text-high-emphasis'" style="height: 100vh;">

    <div class="header-bar px-6 py-4 d-flex align-center justify-space-between flex-shrink-0 border-b z-10" :class="isDark ? 'bg-surface-dark border-white-10' : 'bg-white border-grey-lighten-2'">
      <div class="d-flex align-center gap-4">
        <div class="icon-box rounded-lg d-flex align-center justify-center border shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-20 text-white' : 'bg-primary-lighten-5 border-primary-lighten-4 text-primary'" style="width: 48px; height: 48px;">
          <v-icon size="28">mdi-shield-server</v-icon>
        </div>
        <div class="d-flex flex-column">
          <div class="text-[10px] font-weight-black text-uppercase tracking-widest opacity-70 ls-1">Administração & SRE</div>
          <div class="text-h5 font-weight-black lh-1 mt-1" :class="isDark ? 'text-white' : 'text-primary-darken-2'">Auditoria e Restauração</div>
        </div>
      </div>
      <div class="d-flex gap-3">
        <v-btn size="large" variant="outlined" prepend-icon="mdi-upload-network" class="btn-3d font-weight-bold" :color="isDark ? 'white' : 'grey-darken-3'" @click="showImportModal = true">
          Restaurar Sistema (.mj)
        </v-btn>
        <v-btn size="large" color="primary" variant="flat" prepend-icon="mdi-cloud-download" class="btn-3d font-weight-black tracking-wide" @click="showExportModal = true">
          Extrair Novo Backup
        </v-btn>
      </div>
    </div>

    <div class="flex-grow-1 overflow-y-auto custom-scroll d-flex flex-column pa-6" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">

      <v-row dense class="mb-5">
        <v-col cols="12" md="3">
          <v-card class="pa-5 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between h-100 transition-all hover-card" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div>
              <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-1">Exportações Realizadas</div>
              <div class="text-h4 font-weight-black font-mono" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">{{ totalBackupsGenerated }}</div>
            </div>
            <v-avatar :color="isDark ? 'grey-darken-4' : 'primary-lighten-5'" size="56" class="rounded-lg border-thin">
              <v-icon color="primary" size="28">mdi-database-export</v-icon>
            </v-avatar>
          </v-card>
        </v-col>
        <v-col cols="12" md="3">
          <v-card class="pa-5 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between h-100 transition-all hover-card" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div>
              <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-1">Restaurações (Imports)</div>
              <div class="text-h4 font-weight-black font-mono" :class="isDark ? 'text-error-lighten-1' : 'text-error'">{{ totalRestoresPerformed }}</div>
            </div>
            <v-avatar :color="isDark ? 'grey-darken-4' : 'error-lighten-5'" size="56" class="rounded-lg border-thin">
              <v-icon color="error" size="28">mdi-database-import</v-icon>
            </v-avatar>
          </v-card>
        </v-col>
        <v-col cols="12" md="3">
          <v-card class="pa-5 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between h-100 transition-all hover-card" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div>
              <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-1">Protocolo Segurança</div>
              <div class="text-h6 font-weight-black font-mono mt-1" :class="isDark ? 'text-warning-lighten-1' : 'text-warning-darken-2'">AES-256-GCM</div>
            </div>
            <v-avatar :color="isDark ? 'grey-darken-4' : 'warning-lighten-5'" size="56" class="rounded-lg border-thin">
              <v-icon color="warning" size="28">mdi-shield-check</v-icon>
            </v-avatar>
          </v-card>
        </v-col>
        <v-col cols="12" md="3">
          <v-card class="pa-5 rounded-xl border-thin shadow-sm d-flex align-center justify-space-between h-100 transition-all hover-card" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div>
              <div class="text-caption font-weight-black text-uppercase opacity-70 tracking-widest mb-1">Módulos Conectados</div>
              <div class="text-h4 font-weight-black font-mono" :class="isDark ? 'text-success-lighten-1' : 'text-success'">{{ totalSubmodules }}</div>
            </div>
            <v-avatar :color="isDark ? 'grey-darken-4' : 'success-lighten-5'" size="56" class="rounded-lg border-thin">
              <v-icon color="success" size="28">mdi-server-network</v-icon>
            </v-avatar>
          </v-card>
        </v-col>
      </v-row>

      <v-row dense class="mb-5">
        <v-col cols="12" lg="8">
          <v-card class="rounded-xl border-thin shadow-sm h-100 d-flex flex-column" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div class="pa-4 border-b border-dashed d-flex align-center justify-space-between" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
              <div class="d-flex align-center gap-2">
                <v-icon color="primary" size="20">mdi-chart-areaspline-variant</v-icon>
                <span class="text-subtitle-2 font-weight-black text-uppercase tracking-widest">Tráfego de I/O de Banco (Mock Analytics)</span>
              </div>
              <v-chip size="small" color="success" variant="tonal" class="font-weight-bold font-mono chip-3d">
                <v-icon start size="14" class="icon-pulse">mdi-record-circle</v-icon> Ao Vivo
              </v-chip>
            </div>
            <div class="flex-grow-1 pa-4">
              <apexchart type="area" height="280" :options="areaChartOptions" :series="areaChartSeries"></apexchart>
            </div>
          </v-card>
        </v-col>
        <v-col cols="12" lg="4">
          <v-card class="rounded-xl border-thin shadow-sm h-100 d-flex flex-column" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
            <div class="pa-4 border-b border-dashed d-flex align-center gap-2" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
              <v-icon color="warning" size="20">mdi-chart-donut</v-icon>
              <span class="text-subtitle-2 font-weight-black text-uppercase tracking-widest">Distribuição de Operações</span>
            </div>
            <div class="flex-grow-1 d-flex align-center justify-center pa-4">
              <apexchart type="donut" width="100%" height="280" :options="operationsChartOptions" :series="operationsChartSeries"></apexchart>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <v-card class="d-flex flex-column rounded-xl border-thin shadow-sm overflow-hidden flex-grow-1" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-white'">
        <div class="pa-4 border-b d-flex align-center justify-space-between" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
          <div class="d-flex align-center gap-3">
            <v-avatar :color="isDark ? 'grey-darken-3' : 'white'" size="40" class="border-thin shadow-sm">
              <v-icon size="20" color="primary">mdi-history</v-icon>
            </v-avatar>
            <div>
              <div class="text-subtitle-2 font-weight-black text-uppercase tracking-widest lh-1">Registro de Auditoria de Backup</div>
              <div class="text-[10px] font-weight-bold opacity-70 mt-1">Sincronizado com operation_events</div>
            </div>
          </div>

          <div class="d-flex gap-3 align-center">
            <div class="d-flex align-center rounded-lg border-thin px-3 bg-white shadow-sm" :class="isDark ? 'bg-grey-darken-4 border-white-20' : 'bg-white'" style="width: 300px; height: 40px;">
              <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" size="18">mdi-magnify</v-icon>
              <input v-model="historySearch" type="text" placeholder="Buscar operador ou ação..." class="clean-input flex-grow-1 ml-2 text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
            </div>
            <v-btn size="small" variant="flat" color="primary" class="btn-3d rounded-lg" height="40" width="40" icon="mdi-refresh" @click="fetchAuditLogs" :loading="isLoadingHistory"></v-btn>
          </div>
        </div>

        <div class="flex-grow-1 overflow-y-auto custom-scroll">
          <div class="grid-header sticky-head" :class="isDark ? 'grid-surface-dark' : 'grid-surface-light'" style="grid-template-columns: 160px 140px 200px minmax(250px, 1fr) 140px;">
            <div class="cell center header-text">Data / Hora</div>
            <div class="cell center header-text">Tipo Operação</div>
            <div class="cell header-text">Operador Responsável</div>
            <div class="cell header-text">Detalhes da Execução</div>
            <div class="cell center header-text">Tamanho Físico</div>
          </div>

          <div v-if="filteredHistory.length === 0" class="pa-12 text-center opacity-50 d-flex flex-column align-center justify-center h-100">
            <v-icon size="64" class="mb-4 opacity-60">mdi-database-search-outline</v-icon>
            <span class="text-body-2 font-weight-black text-uppercase tracking-widest">Nenhum registro de backup encontrado no servidor.</span>
          </div>

          <div v-for="(log, idx) in filteredHistory" :key="log.id" class="grid-row hover-bg-row transition-all" :class="[isDark ? 'grid-row-dark' : 'grid-row-light', zebraClass(idx)]" style="grid-template-columns: 160px 140px 200px minmax(250px, 1fr) 140px;">
            <div class="cell center text-caption font-weight-bold font-mono">{{ new Date(log.created_at).toLocaleString('pt-BR') }}</div>
            <div class="cell center">
              <v-chip size="x-small" :color="log.action_type === 'BACKUP_EXPORT' ? 'primary' : 'error'" variant="flat" class="font-weight-black px-3 py-1 chip-3d tracking-widest">
                {{ log.action_type === 'BACKUP_EXPORT' ? 'EXPORTAÇÃO' : 'RESTAURAÇÃO' }}
              </v-chip>
            </div>
            <div class="cell d-flex align-center gap-3">
              <v-avatar size="28" :color="isDark ? 'grey-darken-3' : 'grey-lighten-2'" class="border-thin shadow-sm">
                <span class="text-[10px] font-weight-black">{{ log.actor_name?.substring(0,2).toUpperCase() || 'SYS' }}</span>
              </v-avatar>
              <span class="text-caption font-weight-black text-truncate" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ log.actor_name || 'Sistema Automático' }}</span>
            </div>
            <div class="cell">
              <span class="text-caption font-weight-medium line-clamp-2 opacity-80" :title="log.didactic_message">{{ log.didactic_message }}</span>
            </div>
            <div class="cell center font-mono text-caption font-weight-black" :class="isDark ? 'text-blue-lighten-2' : 'text-primary'">
              {{ log.payload?.size_bytes ? formatBytes(log.payload.size_bytes) : 'N/A' }}
            </div>
          </div>
        </div>
      </v-card>
    </div>

    <v-dialog v-model="showExportModal" :max-width="exportPhase === 'preview' ? '1500' : '850'" persistent scrollable transition="dialog-bottom-transition">
      <v-card class="rounded-xl border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" :style="exportPhase === 'preview' ? 'height: 95vh;' : ''">
        <div class="pa-5 border-b d-flex justify-space-between align-center flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light'">
          <div class="text-h6 font-weight-black text-uppercase d-flex align-center gap-3 tracking-widest" :class="isDark ? 'text-blue-lighten-2' : 'text-primary-darken-1'">
            <v-icon color="primary" size="28">mdi-database-export</v-icon> Extração de Backup Criptografado
          </div>
          <v-btn icon="mdi-close" variant="text" @click="closeExportModal" :disabled="isExporting || isGeneratingPreview"></v-btn>
        </div>

        <v-card-text v-if="exportPhase === 'selection'" class="pa-0 custom-scroll" style="max-height: 70vh;">
          <div class="pa-8">
            <v-alert type="info" variant="tonal" class="rounded-lg text-body-2 font-weight-bold mb-6 border-thin shadow-sm" density="comfortable">
              Selecione os dados relacionais e artefatos físicos. O arquivo <strong>.mj</strong> gerado será blindado nativamente (AES-256-GCM) impossibilitando leituras externas.
            </v-alert>

            <v-card class="pa-5 mb-6 border-thin rounded-xl shadow-sm d-flex align-center gap-4" :class="isDark ? 'bg-grey-darken-3 hover-card' : 'bg-grey-lighten-5 hover-card'">
              <v-avatar color="error-lighten-1" size="56" class="shadow-sm rounded-lg"><v-icon color="white" size="28">mdi-database-check</v-icon></v-avatar>
              <div class="flex-grow-1">
                 <div class="text-subtitle-1 font-weight-black">Backup Integral (Full Dump)</div>
                 <div class="text-caption opacity-70 font-weight-bold">Extrair absolutamente todas as tabelas e buckets mapeados.</div>
              </div>
              <v-switch v-model="exportConfig.isFull" color="error" inset hide-details></v-switch>
            </v-card>

            <v-card class="pa-5 mb-6 border-thin rounded-xl shadow-sm" :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'">
              <div class="d-flex align-center justify-space-between gap-4 flex-wrap mb-4">
                <div class="d-flex align-center gap-3">
                  <v-avatar color="primary" size="48" class="rounded-lg shadow-sm">
                    <v-icon color="white" size="26">mdi-calendar-filter</v-icon>
                  </v-avatar>
                  <div>
                    <div class="text-subtitle-1 font-weight-black">Filtro por data para Contas a Pagar</div>
                    <div class="text-caption opacity-70 font-weight-bold">
                      Aplica somente na tabela <strong>finance_payables</strong>. As outras tabelas seguem exportando normalmente.
                    </div>
                  </div>
                </div>
                <v-switch v-model="exportConfig.financePayablesDateFilter.enabled" color="primary" inset hide-details></v-switch>
              </div>

              <v-expand-transition>
                <div v-if="exportConfig.financePayablesDateFilter.enabled">
                  <v-row dense>
                    <v-col cols="12" md="4">
                      <v-select
                        v-model="exportConfig.financePayablesDateFilter.column"
                        :items="financePayablesDateColumns"
                        item-title="label"
                        item-value="value"
                        label="Coluna de data"
                        density="comfortable"
                        variant="outlined"
                        hide-details
                      />
                    </v-col>

                    <v-col cols="12" md="4">
                      <v-select
                        v-model="exportConfig.financePayablesDateFilter.preset"
                        :items="financePayablesDatePresets"
                        item-title="label"
                        item-value="value"
                        label="Período"
                        density="comfortable"
                        variant="outlined"
                        hide-details
                      />
                    </v-col>

                    <v-col cols="12" md="4">
                      <v-alert type="primary" variant="tonal" density="compact" class="rounded-lg h-100 d-flex align-center">
                        <span class="text-caption font-weight-bold">{{ financePayablesDateFilterSummary }}</span>
                      </v-alert>
                    </v-col>

                    <v-col v-if="exportConfig.financePayablesDateFilter.preset === 'custom'" cols="12" md="6">
                      <v-text-field
                        v-model="exportConfig.financePayablesDateFilter.startDate"
                        type="date"
                        label="Data inicial"
                        density="comfortable"
                        variant="outlined"
                        hide-details
                      />
                    </v-col>

                    <v-col v-if="exportConfig.financePayablesDateFilter.preset === 'custom'" cols="12" md="6">
                      <v-text-field
                        v-model="exportConfig.financePayablesDateFilter.endDate"
                        type="date"
                        label="Data final"
                        density="comfortable"
                        variant="outlined"
                        hide-details
                      />
                    </v-col>
                  </v-row>

                  <v-alert type="warning" variant="tonal" density="compact" class="rounded-lg mt-4 font-weight-bold">
                    A data final é exclusiva. Para pegar maio inteiro, use inicial 2026-05-01 e final 2026-06-01.
                  </v-alert>
                </div>
              </v-expand-transition>
            </v-card>

            <v-expand-transition>
              <div v-if="!exportConfig.isFull">
                <div class="text-subtitle-1 font-weight-black text-uppercase tracking-widest mt-6 mb-4 d-flex align-center gap-2 border-b pb-2" :class="isDark ? 'border-white-10 text-white' : 'border-grey-lighten-2 text-grey-darken-3'">
                  <v-icon color="primary" size="24">mdi-table-multiple</v-icon> Módulos Relacionais (Dados)
                </div>

                <v-expansion-panels variant="accordion" class="border-thin rounded-xl shadow-sm overflow-hidden" elevation="0">
                  <v-expansion-panel v-for="module in moduleHierarchy" :key="module.id" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                    <v-expansion-panel-title class="font-weight-black text-body-2 text-uppercase tracking-wide py-4">
                      {{ module.name }}
                    </v-expansion-panel-title>
                    <v-expansion-panel-text :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-5'" class="pa-4">
                      <v-row dense>
                        <v-col cols="12" sm="6" v-for="sub in module.submodules" :key="sub.id">
                          <v-checkbox v-model="exportConfig.selectedSubmodules" :value="sub.id" hide-details density="compact" color="primary">
                             <template v-slot:label><span class="text-caption font-weight-bold">{{ sub.name }}</span></template>
                          </v-checkbox>
                        </v-col>
                      </v-row>
                    </v-expansion-panel-text>
                  </v-expansion-panel>
                </v-expansion-panels>

                <div class="text-subtitle-1 font-weight-black text-uppercase tracking-widest mt-8 mb-4 d-flex align-center gap-2 border-b pb-2" :class="isDark ? 'border-white-10 text-white' : 'border-grey-lighten-2 text-grey-darken-3'">
                  <v-icon color="warning" size="24">mdi-folder-multiple-image</v-icon> Mídias e Arquivos Físicos (Buckets)
                </div>

                <v-card class="border-thin rounded-xl shadow-sm pa-5" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" elevation="0">
                  <v-row dense>
                    <v-col cols="12" sm="6" v-for="bucket in availableBuckets" :key="bucket.id">
                      <v-checkbox v-model="exportConfig.selectedBuckets" :value="bucket.id" hide-details density="compact" color="warning">
                         <template v-slot:label><span class="text-caption font-weight-bold">{{ bucket.name }}</span></template>
                      </v-checkbox>
                    </v-col>
                  </v-row>
                </v-card>
              </div>
            </v-expand-transition>
          </div>
        </v-card-text>

        <v-card-text v-else-if="isGeneratingPreview" class="pa-12 text-center d-flex flex-column align-center justify-center">
          <v-progress-circular indeterminate color="primary" size="100" width="8"></v-progress-circular>
          <div class="mt-8 text-h5 font-weight-black text-uppercase tracking-widest text-primary">Varrendo o Sistema...</div>
          <div class="mt-3 text-body-1 font-weight-bold font-mono opacity-80">{{ previewProgressText }}</div>
        </v-card-text>

        <div v-else-if="exportPhase === 'preview' && exportPreviewData" class="d-flex flex-grow-1 overflow-hidden animate-fade-in" style="height: 100%;">

          <div class="d-flex flex-column border-e overflow-hidden flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light border-grey-lighten-2'" style="width: 350px;">
            <div class="pa-5 border-b border-dashed" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
              <div class="text-caption font-weight-black text-uppercase tracking-widest opacity-70 mb-2">Estrutura Capturada</div>
              <div class="d-flex gap-3">
                <v-card class="pa-2 rounded border-thin flex-grow-1 text-center" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <div class="text-h6 font-weight-black text-primary font-mono">{{ Object.keys(exportPreviewData.data).length }}</div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Tabelas</div>
                </v-card>
                <v-card class="pa-2 rounded border-thin flex-grow-1 text-center" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <div class="text-h6 font-weight-black text-warning font-mono">{{ Object.keys(exportPreviewData.media || {}).length }}</div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Buckets</div>
                </v-card>
              </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scroll py-3">
              <v-list density="compact" bg-color="transparent" class="pa-0">
                <v-list-subheader class="text-caption font-weight-black text-uppercase tracking-widest px-5 mt-2">Dados Relacionais</v-list-subheader>
                <v-list-item v-for="(rows, tableName) in exportPreviewData.data" :key="tableName" @click="selectExportTab('table', String(tableName))" :active="selectedExportType === 'table' && selectedExportKey === String(tableName)" :color="isDark ? 'white' : 'primary'" class="mx-3 rounded-lg mb-1 transition-all">
                  <template v-slot:prepend><v-icon size="small" color="primary">mdi-table</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">{{ tableName }}</v-list-item-title>
                  <template v-slot:append><v-chip size="x-small" color="primary" variant="tonal" class="font-mono font-weight-bold">{{ rows.length }}</v-chip></template>
                </v-list-item>

                <v-list-subheader v-if="Object.keys(exportPreviewData.media || {}).length > 0" class="text-caption font-weight-black text-uppercase tracking-widest px-5 mt-6">Repositórios Físicos</v-list-subheader>
                <v-list-item v-for="(files, bucketName) in exportPreviewData.media" :key="bucketName" @click="selectExportTab('bucket', String(bucketName))" :active="selectedExportType === 'bucket' && selectedExportKey === String(bucketName)" color="warning" class="mx-3 rounded-lg mb-1 transition-all">
                  <template v-slot:prepend><v-icon size="small" color="warning">mdi-folder-image</v-icon></template>
                  <v-list-item-title class="text-body-2 font-weight-bold">{{ bucketName }}</v-list-item-title>
                  <template v-slot:append><v-chip size="x-small" color="warning" variant="tonal" class="font-mono font-weight-bold">{{ files.length }}</v-chip></template>
                </v-list-item>
              </v-list>
            </div>
          </div>

          <div class="d-flex flex-column flex-grow-1 overflow-hidden" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
            <div v-if="!selectedExportKey" class="fill-height d-flex flex-column align-center justify-center opacity-50 pa-8 text-center">
              <v-icon size="80" class="mb-6 opacity-80">mdi-database-search</v-icon>
              <div class="text-h5 font-weight-black text-uppercase tracking-widest mb-3">Auditoria de Dados Brutos</div>
              <p class="text-body-1 font-weight-medium max-w-md">Selecione uma tabela ou bucket à esquerda para visualizar, filtrar e remover registros indesejados antes de consolidar o backup.</p>
            </div>

            <template v-else-if="selectedExportType === 'table'">
              <div class="pa-5 border-b flex-shrink-0 d-flex align-center justify-space-between gap-4" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                <div class="text-h6 font-weight-black font-mono text-primary d-flex align-center gap-3">
                  <v-icon size="28">mdi-table</v-icon> {{ selectedExportKey }}
                </div>

                <div class="d-flex align-center gap-3">
                  <v-btn v-if="selectedExportRows.length > 0" color="error" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="deleteSelectedExportRows">
                    <v-icon start>mdi-delete</v-icon> Remover Selecionados ({{ selectedExportRows.length }})
                  </v-btn>
                  <div class="d-flex align-center rounded-lg border-thin px-3 bg-white shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-5'" style="width: 350px; height: 40px;">
                    <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" size="18">mdi-magnify</v-icon>
                    <input v-model="exportSearch" type="text" placeholder="Filtrar registros..." class="clean-input flex-grow-1 ml-2 text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
                  </div>
                </div>
              </div>

              <div class="flex-grow-1 overflow-auto custom-scroll position-relative">
                <v-table density="compact" class="text-caption font-mono text-no-wrap table-striped" hover>
                  <thead :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'" class="sticky-head shadow-sm">
                    <tr>
                      <th class="text-center" style="width: 50px;">
                        <v-checkbox-btn v-model="selectAllExportPage" color="primary" density="compact"></v-checkbox-btn>
                      </th>
                      <th v-for="col in currentExportTableColumns" :key="col" class="font-weight-black text-uppercase">{{ col }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, idx) in paginatedExportTableData" :key="idx" class="hover-bg-row transition-all" :class="isDark ? 'grid-row-dark' : 'grid-row-light'">
                      <td class="text-center">
                        <v-checkbox-btn v-model="selectedExportRows" :value="row" color="primary" density="compact"></v-checkbox-btn>
                      </td>
                      <td v-for="col in currentExportTableColumns" :key="col" class="text-truncate" style="max-width: 300px;" :title="String(row[col])">
                        {{ formatCellValue(row[col]) }}
                      </td>
                    </tr>
                    <tr v-if="paginatedExportTableData.length === 0">
                      <td :colspan="currentExportTableColumns.length + 1" class="text-center py-10 opacity-50 font-weight-bold text-body-1">
                        <v-icon size="32" class="mb-2 d-block mx-auto">mdi-file-hidden</v-icon>
                        Nenhum registro encontrado nesta exibição.
                      </td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div class="pa-3 border-t d-flex justify-center bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                <v-pagination v-model="exportPage" :length="exportTotalPages" :total-visible="7" density="comfortable" active-color="primary"></v-pagination>
              </div>
            </template>

            <template v-else-if="selectedExportType === 'bucket'">
              <div class="pa-5 border-b flex-shrink-0 d-flex align-center justify-space-between gap-4" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                <div class="text-h6 font-weight-black font-mono text-warning d-flex align-center gap-3">
                  <v-icon size="28">mdi-folder-multiple-image</v-icon> {{ selectedExportKey }}
                </div>
                <div class="d-flex align-center gap-3">
                  <v-btn v-if="selectedExportFiles.length > 0" color="error" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="deleteSelectedExportFiles">
                    <v-icon start>mdi-delete</v-icon> Ignorar Mídias ({{ selectedExportFiles.length }})
                  </v-btn>
                  <div class="d-flex align-center rounded-lg border-thin px-3 bg-white shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-5'" style="width: 350px; height: 40px;">
                    <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" size="18">mdi-magnify</v-icon>
                    <input v-model="exportSearch" type="text" placeholder="Filtrar arquivo por nome..." class="clean-input flex-grow-1 ml-2 text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
                  </div>
                </div>
              </div>

              <div class="flex-grow-1 overflow-auto custom-scroll pa-5">
                 <div class="d-flex align-center justify-space-between mb-4 px-2">
                   <v-checkbox v-model="selectAllExportFilesPage" label="Selecionar Todos na Página" color="warning" hide-details density="compact" class="font-weight-bold text-caption"></v-checkbox>
                   <span class="text-caption font-weight-bold opacity-70 font-mono">{{ currentExportBucketData.length }} Arquivos Totais</span>
                 </div>

                 <v-row dense>
                   <v-col cols="12" sm="6" md="4" lg="3" xl="2" v-for="file in paginatedExportBucketData" :key="file.name">
                     <v-card class="pa-3 rounded-xl border-thin d-flex flex-column gap-3 position-relative transition-all" :class="[isDark ? 'bg-grey-darken-3 hover-card' : 'bg-white hover-card', selectedExportFiles.includes(file) ? 'border-warning shadow-soft' : '']" @click="toggleFileSelection(file, 'export')">

                       <v-checkbox-btn :model-value="selectedExportFiles.includes(file)" color="warning" class="absolute z-10" style="top: 4px; right: 4px;" @click.stop="toggleFileSelection(file, 'export')"></v-checkbox-btn>

                       <div class="d-flex align-center justify-center rounded-lg bg-grey-lighten-4 overflow-hidden border-thin" style="height: 140px;" :class="isDark ? 'bg-grey-darken-4 border-white-10' : ''">
                         <v-img v-if="file.publicUrl && isImage(file.name)" :src="file.publicUrl" cover class="w-100 h-100" lazy-src="/placeholder.png"></v-img>
                         <v-icon v-else size="48" color="grey">mdi-file-document-outline</v-icon>
                       </div>

                       <div class="overflow-hidden w-100 px-1">
                         <div class="text-caption font-weight-black text-truncate lh-1" :title="file.name">{{ file.name }}</div>
                         <div class="text-[10px] opacity-70 font-mono mt-1 d-flex justify-space-between">
                            <span>{{ file.metadata?.mimetype || 'Desconhecido' }}</span>
                            <span class="font-weight-bold text-warning">{{ file.metadata ? formatBytes(file.metadata.size) : '--' }}</span>
                         </div>
                       </div>
                     </v-card>
                   </v-col>
                   <v-col cols="12" v-if="paginatedExportBucketData.length === 0">
                     <div class="text-center py-12 opacity-50 font-weight-bold text-body-1">
                       <v-icon size="48" class="mb-3 d-block mx-auto">mdi-folder-open-outline</v-icon>
                       Nenhum arquivo listado ou filtro restritivo.
                     </div>
                   </v-col>
                 </v-row>
              </div>
              <div class="pa-3 border-t d-flex justify-center bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                <v-pagination v-model="exportPage" :length="exportBucketTotalPages" :total-visible="7" density="comfortable" active-color="warning"></v-pagination>
              </div>
            </template>
          </div>
        </div>

        <v-card-text v-else-if="exportPhase === 'executing'" class="pa-12 text-center d-flex flex-column align-center justify-center h-100">
          <v-progress-circular indeterminate color="primary" size="120" width="8"></v-progress-circular>
          <div class="mt-8 text-h4 font-weight-black text-uppercase tracking-widest text-primary">Cifrando Artefato Final</div>
          <div class="mt-3 text-body-1 font-weight-bold font-mono opacity-80">{{ exportProgressText }}</div>
        </v-card-text>

        <v-card-actions v-if="exportPhase !== 'executing' && !isGeneratingPreview" class="pa-5 border-t d-flex justify-space-between bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'">
          <v-btn v-if="exportPhase === 'selection'" variant="outlined" size="large" class="btn-3d font-weight-bold px-6" @click="closeExportModal">Cancelar Operação</v-btn>
          <v-btn v-if="exportPhase === 'preview'" variant="outlined" size="large" class="btn-3d font-weight-bold px-6" @click="exportPhase = 'selection'">Voltar à Configuração</v-btn>

          <v-btn v-if="exportPhase === 'selection'" color="primary" variant="flat" size="large" class="btn-3d font-weight-black px-8 tracking-widest" :disabled="!isExportConfigValid" @click="generateExportPreview">
            AVANÇAR PARA ANÁLISE <v-icon end>mdi-arrow-right</v-icon>
          </v-btn>
          <v-btn v-if="exportPhase === 'preview'" color="primary" variant="flat" size="x-large" class="btn-3d font-weight-black px-10 tracking-widest" @click="executeExport">
            <v-icon start size="24">mdi-lock-check</v-icon> CRIPTOGRAFAR E EXPORTAR (.mj)
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showImportModal" :max-width="importPreviewData ? '1500' : '650'" persistent scrollable transition="dialog-bottom-transition">
      <v-card class="rounded-xl border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'" :style="importPreviewData ? 'height: 95vh;' : ''">

        <div class="pa-5 border-b d-flex justify-space-between align-center flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-error-lighten-5 border-error-lighten-3'">
          <div class="text-h6 font-weight-black text-error text-uppercase d-flex align-center gap-3 tracking-widest">
            <v-icon color="error" size="28">mdi-database-import</v-icon> Protocolo de Restauração de Sistema
          </div>
          <v-btn icon="mdi-close" variant="text" @click="closeImportModal" :disabled="isImporting || isAnalyzingFile"></v-btn>
        </div>

        <v-card-text v-if="!importPreviewData" class="pa-8 custom-scroll">
          <div v-if="!isAnalyzingFile">
            <v-icon size="80" color="warning" class="mb-6 d-block mx-auto text-center opacity-80">mdi-alert-decagram</v-icon>
            <h2 class="text-h5 font-weight-black mb-3 text-center tracking-tight">Ressurreição de Dados (Sobrescrita)</h2>
            <p class="text-body-2 font-weight-bold opacity-70 mb-8 text-center max-w-md mx-auto">
              Forneça o artefato <strong>.mj</strong>. O sistema o decifrará e exibirá uma visão geral detalhada, permitindo a purga de registros indesejados antes de concretizar a restauração.
            </p>

            <div
              class="border-dashed rounded-xl pa-10 cursor-pointer hover-bg-light transition-all d-flex flex-column align-center justify-center relative"
              :class="isDark ? 'border-white-20 bg-grey-darken-3 hover-card' : 'border-grey bg-grey-lighten-5 hover-card'"
              style="border-width: 2px !important;"
              @click="openImportFileSelector"
              @dragover.prevent="isDraggingImportFile = true"
              @dragleave.prevent="isDraggingImportFile = false"
              @drop.prevent="handleFileDrop"
            >
              <v-icon size="64" class="opacity-50 mb-4" color="primary">mdi-cloud-upload-outline</v-icon>
              <span class="text-subtitle-1 font-weight-black">
                {{ isDraggingImportFile ? 'Solte o arquivo .mj aqui' : 'Clique ou Arraste o Arquivo .mj' }}
              </span>
              <span class="text-caption font-weight-bold opacity-60 mt-1">Apenas artefatos selados por este sistema</span>
              <v-btn color="primary" variant="tonal" class="mt-5 font-weight-black" prepend-icon="mdi-folder-open" @click.stop="openImportFileSelector">
                Selecionar arquivo
              </v-btn>
              <input ref="importFileInput" type="file" accept=".mj,.mjpayables,application/octet-stream,application/json" class="d-none" @change="handleFileSelect" />
            </div>
          </div>

          <div v-if="isAnalyzingFile" class="text-center py-12">
            <v-progress-circular indeterminate color="primary" size="100" width="8"></v-progress-circular>
            <div class="mt-8 text-h5 font-weight-black text-uppercase tracking-widest text-primary">Decifrando Cofre...</div>
            <div class="mt-3 text-body-2 font-weight-bold opacity-70">Descompactando blobs e validando chaves AES. Aguarde.</div>
          </div>
        </v-card-text>

        <div v-if="importPreviewData && !isImporting" class="d-flex flex-grow-1 overflow-hidden animate-fade-in" style="height: 100%;">

          <div class="d-flex flex-column border-e overflow-hidden flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-surface-light border-grey-lighten-2'" style="width: 350px;">
            <div class="pa-5 border-b border-dashed" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
              <div class="text-caption font-weight-black text-uppercase tracking-widest opacity-70 mb-2">Artefato Desbloqueado</div>
              <div class="text-subtitle-2 font-mono font-weight-black line-clamp-1 text-primary mb-3" :title="selectedImportFile?.name">{{ selectedImportFile?.name }}</div>

              <div class="d-flex gap-3">
                <v-card class="pa-2 rounded border-thin flex-grow-1 text-center" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <div class="text-h6 font-weight-black text-error font-mono">{{ Object.keys(importPreviewData.data).length }}</div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Tabelas</div>
                </v-card>
                <v-card class="pa-2 rounded border-thin flex-grow-1 text-center" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
                  <div class="text-h6 font-weight-black text-warning font-mono">{{ Object.keys(importPreviewData.media || {}).length }}</div>
                  <div class="text-[10px] text-uppercase font-weight-bold opacity-70">Buckets</div>
                </v-card>
              </div>
            </div>

            <div class="flex-grow-1 overflow-y-auto custom-scroll py-3">
              <v-list density="compact" bg-color="transparent" class="pa-0">
                <v-list-subheader class="text-caption font-weight-black text-uppercase tracking-widest px-5 mt-2">Dados a Restaurar</v-list-subheader>

                <v-list-item v-for="(rows, tableName) in importPreviewData.data" :key="tableName" @click="selectImportTab('table', String(tableName))" :active="selectedImportType === 'table' && selectedImportKey === String(tableName)" :color="isDark ? 'white' : 'error'" class="mx-3 rounded-lg mb-1 transition-all">
                  <template v-slot:prepend>
                    <v-icon size="small" :color="excludedTables.has(String(tableName)) ? 'grey' : 'error'">{{ excludedTables.has(String(tableName)) ? 'mdi-table-cancel' : 'mdi-table' }}</v-icon>
                  </template>
                  <v-list-item-title class="text-body-2 font-weight-bold" :class="{'text-decoration-line-through opacity-50': excludedTables.has(String(tableName))} ">{{ tableName }}</v-list-item-title>
                  <template v-slot:append><v-chip size="x-small" :color="excludedTables.has(String(tableName)) ? 'grey' : 'error'" variant="tonal" class="font-mono font-weight-bold">{{ rows.length }}</v-chip></template>
                </v-list-item>

                <v-list-subheader v-if="Object.keys(importPreviewData.media || {}).length > 0" class="text-caption font-weight-black text-uppercase tracking-widest px-5 mt-6">Mídias Físicas</v-list-subheader>

                <v-list-item v-for="(files, bucketName) in importPreviewData.media" :key="bucketName" @click="selectImportTab('bucket', String(bucketName))" :active="selectedImportType === 'bucket' && selectedImportKey === String(bucketName)" color="warning" class="mx-3 rounded-lg mb-1 transition-all">
                  <template v-slot:prepend>
                    <v-icon size="small" :color="excludedBuckets.has(String(bucketName)) ? 'grey' : 'warning'">{{ excludedBuckets.has(String(bucketName)) ? 'mdi-folder-cancel' : 'mdi-folder-image' }}</v-icon>
                  </template>
                  <v-list-item-title class="text-body-2 font-weight-bold" :class="{'text-decoration-line-through opacity-50': excludedBuckets.has(String(bucketName))} ">{{ bucketName }}</v-list-item-title>
                  <template v-slot:append><v-chip size="x-small" :color="excludedBuckets.has(String(bucketName)) ? 'grey' : 'warning'" variant="tonal" class="font-mono font-weight-bold">{{ files.length }}</v-chip></template>
                </v-list-item>
              </v-list>
            </div>
          </div>

          <div class="d-flex flex-column flex-grow-1 overflow-hidden" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">

            <div v-if="!selectedImportKey" class="fill-height d-flex flex-column align-center justify-center opacity-50 pa-8 text-center">
              <v-icon size="80" class="mb-6 opacity-80" color="error">mdi-database-eye</v-icon>
              <div class="text-h5 font-weight-black text-uppercase tracking-widest mb-3">Auditoria de Restauração</div>
              <p class="text-body-1 font-weight-medium max-w-md">Este backup foi gerado em {{ new Date(importPreviewData.timestamp).toLocaleString('pt-BR') }}. Selecione os módulos à esquerda para verificar a integridade e expurgar dados obsoletos antes de aplicar a sobrescrita definitiva no servidor.</p>
            </div>

            <template v-else-if="selectedImportType === 'table'">
              <div class="pa-5 border-b flex-shrink-0 d-flex align-center justify-space-between gap-4" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                <div class="text-h6 font-weight-black font-mono text-error d-flex align-center gap-3">
                  <v-icon size="28">mdi-table</v-icon> {{ selectedImportKey }}
                </div>

                <div class="d-flex align-center gap-3 flex-wrap justify-end">
                  <v-chip size="small" :color="excludedTables.has(selectedImportKey) ? 'grey' : 'success'" variant="flat" class="font-weight-black chip-3d px-4 mr-2">
                    {{ excludedTables.has(selectedImportKey) ? 'Bloqueada p/ Restauro' : 'Pronta p/ Restauração' }}
                  </v-chip>

                  <v-btn v-if="selectedImportRows.length > 0" color="error" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="deleteSelectedImportRows">
                    <v-icon start>mdi-delete-sweep</v-icon> Excluir Linhas ({{ selectedImportRows.length }})
                  </v-btn>

                  <div class="d-flex align-center rounded-lg border-thin px-3 bg-white shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-5'" style="width: 300px; height: 40px;">
                    <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" size="18">mdi-magnify</v-icon>
                    <input v-model="importSearch" type="text" placeholder="Filtrar registros..." class="clean-input flex-grow-1 ml-2 text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
                  </div>

                  <v-btn size="small" :color="excludedTables.has(selectedImportKey) ? 'success' : 'grey-darken-2'" variant="tonal" class="btn-3d font-weight-bold" @click="toggleTableExclusion(selectedImportKey)">
                    <v-icon start>{{ excludedTables.has(selectedImportKey) ? 'mdi-plus-circle' : 'mdi-cancel' }}</v-icon>
                    {{ excludedTables.has(selectedImportKey) ? 'Reativar Tabela' : 'Ignorar Tabela' }}
                  </v-btn>
                </div>
              </div>

              <div class="flex-grow-1 overflow-auto custom-scroll position-relative" :class="{'opacity-40 pe-none': excludedTables.has(selectedImportKey)}">
                <v-table density="compact" class="text-caption font-mono text-no-wrap table-striped" hover>
                  <thead :class="isDark ? 'bg-grey-darken-3' : 'bg-grey-lighten-4'" class="sticky-head shadow-sm">
                    <tr>
                      <th class="text-center" style="width: 50px;">
                        <v-checkbox-btn v-model="selectAllImportPage" color="error" density="compact"></v-checkbox-btn>
                      </th>
                      <th v-for="col in currentImportTableColumns" :key="col" class="font-weight-black text-uppercase">{{ col }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, idx) in paginatedImportTableData" :key="idx" class="hover-bg-row transition-all" :class="isDark ? 'grid-row-dark' : 'grid-row-light'">
                      <td class="text-center">
                        <v-checkbox-btn v-model="selectedImportRows" :value="row" color="error" density="compact"></v-checkbox-btn>
                      </td>
                      <td v-for="col in currentImportTableColumns" :key="col" class="text-truncate" style="max-width: 300px;" :title="String(row[col])">
                        {{ formatCellValue(row[col]) }}
                      </td>
                    </tr>
                    <tr v-if="paginatedImportTableData.length === 0">
                      <td :colspan="currentImportTableColumns.length + 1" class="text-center py-10 opacity-50 font-weight-bold text-body-1">
                         <v-icon size="32" class="mb-2 d-block mx-auto">mdi-file-hidden</v-icon>
                         Tabela vazia ou filtro sem resultados.
                      </td>
                    </tr>
                  </tbody>
                </v-table>
              </div>
              <div class="pa-3 border-t d-flex justify-center bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                <v-pagination v-model="importPage" :length="importTotalPages" :total-visible="7" density="comfortable" active-color="error"></v-pagination>
              </div>
            </template>

            <template v-else-if="selectedImportType === 'bucket'">
              <div class="pa-5 border-b flex-shrink-0 d-flex align-center justify-space-between gap-4" :class="isDark ? 'border-white-10' : 'border-grey-lighten-2'">
                <div class="text-h6 font-weight-black font-mono text-warning d-flex align-center gap-3">
                  <v-icon size="28">mdi-folder-multiple-image</v-icon> {{ selectedImportKey }}
                </div>

                <div class="d-flex align-center gap-3 flex-wrap justify-end">
                  <v-chip size="small" variant="flat" :color="excludedBuckets.has(selectedImportKey) ? 'grey' : 'warning'" class="font-weight-black chip-3d px-4 mr-2">
                    {{ excludedBuckets.has(selectedImportKey) ? 'Bucket Ignorado' : 'Mídias Prontas p/ Upload' }}
                  </v-chip>

                  <v-btn v-if="selectedImportFiles.length > 0" color="error" variant="flat" size="small" class="btn-3d font-weight-bold px-4" @click="deleteSelectedImportFiles">
                    <v-icon start>mdi-delete</v-icon> Excluir Mídias ({{ selectedImportFiles.length }})
                  </v-btn>

                  <div class="d-flex align-center rounded-lg border-thin px-3 bg-white shadow-sm" :class="isDark ? 'bg-grey-darken-3 border-white-20' : 'bg-grey-lighten-5'" style="width: 300px; height: 40px;">
                    <v-icon :color="isDark ? 'white-70' : 'grey-darken-1'" size="18">mdi-magnify</v-icon>
                    <input v-model="importSearch" type="text" placeholder="Buscar arquivo..." class="clean-input flex-grow-1 ml-2 text-caption font-weight-bold" :class="isDark ? 'text-white' : 'text-grey-darken-4'" />
                  </div>

                  <v-btn size="small" :color="excludedBuckets.has(selectedImportKey) ? 'success' : 'grey-darken-2'" variant="tonal" class="btn-3d font-weight-bold" @click="toggleBucketExclusion(selectedImportKey)">
                    <v-icon start>{{ excludedBuckets.has(selectedImportKey) ? 'mdi-plus-circle' : 'mdi-cancel' }}</v-icon>
                    {{ excludedBuckets.has(selectedImportKey) ? 'Restaurar Bucket' : 'Bloquear Bucket' }}
                  </v-btn>
                </div>
              </div>

              <div class="flex-grow-1 overflow-auto custom-scroll pa-5" :class="{'opacity-40 pe-none': excludedBuckets.has(selectedImportKey)}">
                 <div class="d-flex align-center justify-space-between mb-4 px-2">
                   <v-checkbox v-model="selectAllImportFilesPage" label="Selecionar Todos na Página" color="warning" hide-details density="compact" class="font-weight-bold text-caption"></v-checkbox>
                   <span class="text-caption font-weight-bold opacity-70 font-mono">{{ currentImportBucketData.length }} Arquivos Contidos</span>
                 </div>

                 <v-row dense>
                   <v-col cols="12" sm="6" md="4" lg="3" xl="2" v-for="file in paginatedImportBucketData" :key="file.name">
                     <v-card class="pa-3 rounded-xl border-thin d-flex flex-column gap-3 position-relative transition-all" :class="[isDark ? 'bg-grey-darken-3 hover-card' : 'bg-white hover-card', selectedImportFiles.includes(file) ? 'border-error shadow-soft' : '']" @click="toggleFileSelection(file, 'import')">

                       <v-checkbox-btn :model-value="selectedImportFiles.includes(file)" color="error" class="absolute z-10" style="top: 4px; right: 4px;" @click.stop="toggleFileSelection(file, 'import')"></v-checkbox-btn>

                       <div class="d-flex align-center justify-center rounded-lg bg-grey-lighten-4 overflow-hidden border-thin" style="height: 140px;" :class="isDark ? 'bg-grey-darken-4 border-white-10' : ''">
                         <v-img v-if="file.objectUrl && isImage(file.name)" :src="file.objectUrl" cover class="w-100 h-100" lazy-src="/placeholder.png"></v-img>
                         <v-icon v-else size="48" color="grey">mdi-file-document-outline</v-icon>
                       </div>

                       <div class="overflow-hidden w-100 px-1">
                         <div class="text-caption font-weight-black text-truncate lh-1" :title="file.name">{{ file.name }}</div>
                       </div>
                     </v-card>
                   </v-col>
                   <v-col cols="12" v-if="paginatedImportBucketData.length === 0">
                     <div class="text-center py-12 opacity-50 font-weight-bold text-body-1">
                        <v-icon size="48" class="mb-3 d-block mx-auto">mdi-folder-search-outline</v-icon>
                        Nenhum arquivo no bucket ou filtro restrito.
                     </div>
                   </v-col>
                 </v-row>
              </div>
              <div class="pa-3 border-t d-flex justify-center bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5 border-grey-lighten-2'">
                <v-pagination v-model="importFilePage" :length="importBucketTotalPages" :total-visible="7" density="comfortable" active-color="warning"></v-pagination>
              </div>
            </template>
          </div>
        </div>

        <div v-if="isImporting" class="pa-12 text-center d-flex flex-column align-center justify-center flex-grow-1 h-100">
          <v-progress-circular indeterminate color="error" size="120" width="8"></v-progress-circular>
          <div class="mt-8 text-h4 font-weight-black text-uppercase tracking-widest text-error">Consolidando Sobrescrita...</div>
          <div class="mt-3 text-body-1 font-weight-bold font-mono opacity-80">{{ importProgressText }}</div>
        </div>

        <v-card-actions v-if="importPreviewData && !isImporting" class="pa-5 border-t d-flex justify-space-between bg-surface-light flex-shrink-0" :class="isDark ? 'bg-grey-darken-4 border-white-10' : 'bg-white'">
          <v-btn variant="outlined" size="large" class="btn-3d font-weight-bold px-6" @click="resetImportSelection" :color="isDark ? 'white' : 'grey-darken-3'">
            <v-icon start>mdi-close</v-icon> ABORTAR OPERAÇÃO
          </v-btn>

          <v-btn color="error" variant="flat" size="x-large" class="btn-3d font-weight-black px-10 tracking-widest" @click="executeImport">
            <v-icon start size="24">mdi-skull-crossbones</v-icon> CONFIRMAR E RESTAURAR SISTEMA
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, watch } from 'vue'
import { useTheme } from 'vuetify'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'
import { useUserStore } from '@/stores/user'
import JSZip from 'jszip'

const theme = useTheme()
const appStore = useAppStore()
const userStore = useUserStore()
const isDark = computed(() => theme.global.current.value.dark)

const zebraClass = (index: number) => isDark.value ? (index % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (index % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b')

// --- Controles de Estado: EXPORT ---
const showExportModal = ref(false)
const exportPhase = ref<'selection'|'preview'|'executing'>('selection')
const isGeneratingPreview = ref(false)
const isExporting = ref(false)
const exportProgressText = ref('')
const previewProgressText = ref('')

const exportConfig = reactive({
  isFull: true,
  selectedSubmodules: [] as string[],
  selectedBuckets: [] as string[],
  financePayablesDateFilter: {
    enabled: false,
    column: 'due_date',
    preset: 'current_and_previous_month',
    startDate: toDateInputValue(addMonths(firstDayOfMonth(new Date()), -1)),
    endDate: toDateInputValue(addMonths(firstDayOfMonth(new Date()), 1))
  }
})

const exportPreviewData = ref<any>(null)
const selectedExportType = ref<'table' | 'bucket' | null>(null)
const selectedExportKey = ref<string | null>(null)
const exportSearch = ref('')

// Paginação Exportação
const exportPage = ref(1)
const itemsPerPage = 50
const selectedExportRows = ref<any[]>([])
const selectedExportFiles = ref<any[]>([])

// --- Controles de Estado: IMPORT ---
const showImportModal = ref(false)
const isAnalyzingFile = ref(false)
const isImporting = ref(false)
const importProgressText = ref('')
const selectedImportFile = ref<File | null>(null)
const importFileInput = ref<HTMLInputElement | null>(null)
const isDraggingImportFile = ref(false)
const importPreviewData = ref<any>(null)

const selectedImportType = ref<'table' | 'bucket' | null>(null)
const selectedImportKey = ref<string | null>(null)
const importSearch = ref('')
const excludedTables = ref<Set<string>>(new Set())
const excludedBuckets = ref<Set<string>>(new Set())

// Paginação Importação
const importPage = ref(1)
const importFilePage = ref(1)
const selectedImportRows = ref<any[]>([])
const selectedImportFiles = ref<any[]>([])

// --- Auditoria ---
const backupHistory = ref<any[]>([])
const isLoadingHistory = ref(false)
const historySearch = ref('')

// --- Chave Criptográfica ---
const SYSTEM_SECRET_KEY = "MJ_PROCESS_CORE_SECURE_KEY_2026_!@#"

// --- Definição dos Módulos ---
const moduleHierarchy = [
  {
    id: 'vendas', name: 'CRM & Vendas',
    submodules: [
      { id: 'vendas_pedidos', name: 'Pedidos de Venda', tables: ['orders', 'order_items', 'order_logs', 'order_payments'] },
      { id: 'vendas_pdv', name: 'Frente de Caixa (PDV)', tables: ['store_sales', 'cajuia_cash_sessions', 'cajuia_cash_movements', 'pdv_price_lists', 'pdv_product_prices'] },
      { id: 'vendas_crm', name: 'Clientes & Interações', tables: ['customers', 'customers_mj', 'wa_conversations', 'wa_messages', 'public_leads'] }
    ]
  },
  {
    id: 'financeiro', name: 'Operações Financeiras',
    submodules: [
      { id: 'fin_recebiveis', name: 'Contas a Receber', tables: ['finance_receivables', 'finance_receivable_payments'] },
      { id: 'fin_pagaveis', name: 'Contas a Pagar', tables: ['finance_payables', 'finance_invoice_payments'] },
      { id: 'fin_caixas', name: 'Caixas e Bancos', tables: ['finance_accounts', 'finance_transactions', 'finance_bank_accounts'] },
      { id: 'fin_configs', name: 'Configurações Base', tables: ['finance_chart_of_accounts', 'finance_payment_methods', 'finance_cost_centers'] }
    ]
  },
  {
    id: 'design', name: 'Catálogo & Design',
    submodules: [
      { id: 'des_estampas', name: 'Biblioteca de Estampas', tables: ['catalog_stamps', 'stamp_library', 'stamp_folders'] },
      { id: 'des_tecidos', name: 'Tecidos e Produtos', tables: ['catalog_fabrics', 'products', 'cajuia_products'] },
      { id: 'des_solicitacoes', name: 'Chamados de Design', tables: ['design_requests', 'design_queue', 'design_rejection_logs'] }
    ]
  },
  {
    id: 'producao', name: 'PCP & Chão de Fábrica',
    submodules: [
      { id: 'pcp_kanban', name: 'Kanban e Agendamentos', tables: ['production_schedule', 'production_logs', 'cajuia_corte_tasks'] },
      { id: 'pcp_regras', name: 'Máquinas e Workflows', tables: ['production_machines', 'pcp_workflows'] }
    ]
  },
  {
    id: 'estoque', name: 'Almoxarifado & Compras',
    submodules: [
      { id: 'est_almoxarifado', name: 'Controle de Estoque', tables: ['stock', 'stock_movements', 'daily_stock_reports'] },
      { id: 'est_compras', name: 'Compras e Fornecedores', tables: ['purchases', 'purchase_items', 'suppliers_mj'] }
    ]
  },
  {
    id: 'rh', name: 'RH & Frota',
    submodules: [
      { id: 'rh_colaboradores', name: 'Colaboradores', tables: ['employees_mj', 'time_tracking_assignments', 'work_schedules'] },
      { id: 'rh_ponto', name: 'Controle de Ponto', tables: ['time_tracking_logs', 'time_tracking_corrections', 'time_tracking_settings'] },
      { id: 'rh_frota', name: 'Gestão de Frota', tables: ['fleet_vehicles', 'fleet_refuelings'] }
    ]
  },
  {
    id: 'fiscal', name: 'Motor Fiscal (Sefaz)',
    submodules: [
      { id: 'fisc_notas', name: 'Emissões (NFe/NFCe/CTe)', tables: ['nfe_outbound', 'nfce_outbound', 'cte_entries'] },
      { id: 'fisc_regras', name: 'Regras e Cadastros Fiscais', tables: ['fiscal_companies', 'fiscal_tax_rules', 'cajuia_tax_settings'] }
    ]
  },
  {
    id: 'sistema', name: 'Auditoria & Sistema',
    submodules: [
      { id: 'sys_perfis', name: 'Perfis e Acessos', tables: ['profiles', 'cajuia_permissions', 'custom_roles'] },
      { id: 'sys_configs', name: 'Parametrizações (Lojas)', tables: ['companies', 'stores', 'app_config'] },
    ]
  }
]

const availableBuckets = [
  { id: 'stamp-library', name: 'Imagens de Estampas e Artes' },
  { id: 'order-attachments', name: 'Comprovantes de Pagamento (Pedidos)' },
  { id: 'financial-receipts', name: 'Recibos do Contas a Pagar/Receber' },
  { id: 'rh-documents', name: 'Documentos e Avatares de Colaboradores' },
  { id: 'fleet-docs', name: 'Documentos e Fotos de Veículos' }
]

const financePayablesDateColumns = [
  { label: 'Vencimento (due_date)', value: 'due_date' },
  { label: 'Criação (created_at)', value: 'created_at' },
  { label: 'Atualização (updated_at)', value: 'updated_at' },
  { label: 'Competência (competence_date)', value: 'competence_date' },
  { label: 'Emissão (issue_date)', value: 'issue_date' },
  { label: 'Pagamento (paid_at)', value: 'paid_at' }
]

const financePayablesDatePresets = [
  { label: 'Mês atual', value: 'current_month' },
  { label: 'Mês passado', value: 'previous_month' },
  { label: 'Mês atual + mês passado', value: 'current_and_previous_month' },
  { label: 'Ano atual', value: 'current_year' },
  { label: 'Personalizado', value: 'custom' }
]

const totalSubmodules = computed(() => moduleHierarchy.reduce((acc, mod) => acc + mod.submodules.length, 0))
const isExportConfigValid = computed(() => exportConfig.isFull || exportConfig.selectedSubmodules.length > 0 || exportConfig.selectedBuckets.length > 0)

const totalBackupsGenerated = computed(() => backupHistory.value.filter(b => b.action_type === 'BACKUP_EXPORT').length)
const totalRestoresPerformed = computed(() => backupHistory.value.filter(b => b.action_type === 'BACKUP_RESTORE').length)

const filteredHistory = computed(() => {
  if (!historySearch.value) return backupHistory.value
  const s = historySearch.value.toLowerCase()
  return backupHistory.value.filter((log: any) =>
    log.actor_name?.toLowerCase().includes(s) ||
    log.didactic_message?.toLowerCase().includes(s) ||
    log.action_type?.toLowerCase().includes(s)
  )
})

// --- Utilities ---
const formatBytes = (bytes: number, decimals = 2) => {
  if (!+bytes) return '0 Bytes'
  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`
}

const formatCellValue = (val: any) => {
  if (val === null || val === undefined) return 'NULL'
  if (typeof val === 'object') return JSON.stringify(val)
  return String(val)
}

const isImage = (filename: string) => filename.match(/\.(jpeg|jpg|gif|png|webp|svg)$/i) !== null

function firstDayOfMonth(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), 1)
}

function firstDayOfYear(date: Date) {
  return new Date(date.getFullYear(), 0, 1)
}

function addMonths(date: Date, amount: number) {
  return new Date(date.getFullYear(), date.getMonth() + amount, 1)
}

function addYears(date: Date, amount: number) {
  return new Date(date.getFullYear() + amount, 0, 1)
}

function toDateInputValue(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const getFinancePayablesDateRange = () => {
  const preset = exportConfig.financePayablesDateFilter.preset
  const now = new Date()
  const currentMonth = firstDayOfMonth(now)
  const nextMonth = addMonths(currentMonth, 1)
  const previousMonth = addMonths(currentMonth, -1)
  const currentYear = firstDayOfYear(now)
  const nextYear = addYears(now, 1)

  if (preset === 'current_month') {
    return { start: toDateInputValue(currentMonth), end: toDateInputValue(nextMonth) }
  }

  if (preset === 'previous_month') {
    return { start: toDateInputValue(previousMonth), end: toDateInputValue(currentMonth) }
  }

  if (preset === 'current_and_previous_month') {
    return { start: toDateInputValue(previousMonth), end: toDateInputValue(nextMonth) }
  }

  if (preset === 'current_year') {
    return { start: toDateInputValue(currentYear), end: toDateInputValue(nextYear) }
  }

  return {
    start: exportConfig.financePayablesDateFilter.startDate,
    end: exportConfig.financePayablesDateFilter.endDate
  }
}

const financePayablesDateFilterSummary = computed(() => {
  if (!exportConfig.financePayablesDateFilter.enabled) return 'Sem filtro: exporta finance_payables inteira.'
  const range = getFinancePayablesDateRange()
  return `${exportConfig.financePayablesDateFilter.column} >= ${range.start || '...'} e < ${range.end || '...'}`
})



// Limpa seleções ao trocar de aba
watch(selectedExportKey, () => { selectedExportRows.value = []; selectedExportFiles.value = []; exportPage.value = 1; })
watch(selectedImportKey, () => { selectedImportRows.value = []; selectedImportFiles.value = []; importPage.value = 1; importFilePage.value = 1; })

// --- Paginação Dinâmica: EXPORT ---
const currentExportTableData = computed(() => {
  if (selectedExportType.value !== 'table' || !selectedExportKey.value || !exportPreviewData.value) return []
  let data = exportPreviewData.value.data[selectedExportKey.value] || []
  if (exportSearch.value) {
    const s = exportSearch.value.toLowerCase()
    data = data.filter((row: any) => Object.values(row).some(v => String(v).toLowerCase().includes(s)))
  }
  return data
})
const exportTotalPages = computed(() => Math.ceil(currentExportTableData.value.length / itemsPerPage) || 1)
const paginatedExportTableData = computed(() => {
  const start = (exportPage.value - 1) * itemsPerPage
  return currentExportTableData.value.slice(start, start + itemsPerPage)
})
const currentExportTableColumns = computed(() => {
  if (currentExportTableData.value.length === 0) return []
  const keys = new Set<string>()
  currentExportTableData.value.slice(0, 50).forEach((row: any) => Object.keys(row).forEach(k => keys.add(k)))
  return Array.from(keys)
})

const selectAllExportPage = computed({
  get() { return paginatedExportTableData.value.length > 0 && selectedExportRows.value.length === paginatedExportTableData.value.length },
  set(val) { selectedExportRows.value = val ? [...paginatedExportTableData.value] : [] }
})

const deleteSelectedExportRows = () => {
  if (exportPreviewData.value && exportPreviewData.value.data[selectedExportKey.value as string]) {
    const originalArray = exportPreviewData.value.data[selectedExportKey.value as string]
    selectedExportRows.value.forEach(row => {
      const idx = originalArray.indexOf(row)
      if (idx > -1) originalArray.splice(idx, 1)
    })
    selectedExportRows.value = []
    appStore.showSnackbar('Lixo expurgado da prévia de exportação.', 'success')
  }
}

const currentExportBucketData = computed(() => {
  if (selectedExportType.value !== 'bucket' || !selectedExportKey.value || !exportPreviewData.value) return []
  let files = exportPreviewData.value.media[selectedExportKey.value] || []
  if (exportSearch.value) {
    const s = exportSearch.value.toLowerCase()
    files = files.filter((f: any) => f.name.toLowerCase().includes(s))
  }
  return files
})
const exportBucketTotalPages = computed(() => Math.ceil(currentExportBucketData.value.length / itemsPerPage) || 1)
const paginatedExportBucketData = computed(() => {
  const start = (exportPage.value - 1) * itemsPerPage
  return currentExportBucketData.value.slice(start, start + itemsPerPage)
})

const selectAllExportFilesPage = computed({
  get() { return paginatedExportBucketData.value.length > 0 && selectedExportFiles.value.length === paginatedExportBucketData.value.length },
  set(val) { selectedExportFiles.value = val ? [...paginatedExportBucketData.value] : [] }
})

const toggleFileSelection = (file: any, mode: 'export'|'import') => {
  const targetArray = mode === 'export' ? selectedExportFiles : selectedImportFiles
  const idx = targetArray.value.indexOf(file)
  if(idx > -1) targetArray.value.splice(idx, 1)
  else targetArray.value.push(file)
}

const deleteSelectedExportFiles = () => {
  if (exportPreviewData.value && exportPreviewData.value.media[selectedExportKey.value as string]) {
    const originalArray = exportPreviewData.value.media[selectedExportKey.value as string]
    selectedExportFiles.value.forEach(file => {
      const idx = originalArray.indexOf(file)
      if (idx > -1) originalArray.splice(idx, 1)
    })
    selectedExportFiles.value = []
    appStore.showSnackbar('Mídias removidas do artefato.', 'success')
  }
}

// --- Paginação Dinâmica: IMPORT ---
const currentImportTableData = computed(() => {
  if (selectedImportType.value !== 'table' || !selectedImportKey.value || !importPreviewData.value) return []
  let data = importPreviewData.value.data[selectedImportKey.value] || []
  if (importSearch.value) {
    const s = importSearch.value.toLowerCase()
    data = data.filter((row: any) => Object.values(row).some(v => String(v).toLowerCase().includes(s)))
  }
  return data
})
const importTotalPages = computed(() => Math.ceil(currentImportTableData.value.length / itemsPerPage) || 1)
const paginatedImportTableData = computed(() => {
  const start = (importPage.value - 1) * itemsPerPage
  return currentImportTableData.value.slice(start, start + itemsPerPage)
})
const currentImportTableColumns = computed(() => {
  if (currentImportTableData.value.length === 0) return []
  const keys = new Set<string>()
  currentImportTableData.value.slice(0, 50).forEach((row: any) => Object.keys(row).forEach(k => keys.add(k)))
  return Array.from(keys)
})

const selectAllImportPage = computed({
  get() { return paginatedImportTableData.value.length > 0 && selectedImportRows.value.length === paginatedImportTableData.value.length },
  set(val) { selectedImportRows.value = val ? [...paginatedImportTableData.value] : [] }
})

const deleteSelectedImportRows = () => {
  if (importPreviewData.value && importPreviewData.value.data[selectedImportKey.value as string]) {
    const originalArray = importPreviewData.value.data[selectedImportKey.value as string]
    selectedImportRows.value.forEach(row => {
      const idx = originalArray.indexOf(row)
      if (idx > -1) originalArray.splice(idx, 1)
    })
    selectedImportRows.value = []
    appStore.showSnackbar('Lixo expurgado antes da ressurreição.', 'success')
  }
}

const currentImportBucketData = computed(() => {
  if (selectedImportType.value !== 'bucket' || !selectedImportKey.value || !importPreviewData.value) return []
  let files = importPreviewData.value.media[selectedImportKey.value] || []
  if (importSearch.value) {
    const s = importSearch.value.toLowerCase()
    files = files.filter((f: any) => f.name.toLowerCase().includes(s))
  }
  return files
})
const importBucketTotalPages = computed(() => Math.ceil(currentImportBucketData.value.length / itemsPerPage) || 1)
const paginatedImportBucketData = computed(() => {
  const start = (importFilePage.value - 1) * itemsPerPage
  return currentImportBucketData.value.slice(start, start + itemsPerPage)
})

const selectAllImportFilesPage = computed({
  get() { return paginatedImportBucketData.value.length > 0 && selectedImportFiles.value.length === paginatedImportBucketData.value.length },
  set(val) { selectedImportFiles.value = val ? [...paginatedImportBucketData.value] : [] }
})

const deleteSelectedImportFiles = () => {
  if (importPreviewData.value && importPreviewData.value.media[selectedImportKey.value as string]) {
    const originalArray = importPreviewData.value.media[selectedImportKey.value as string]
    selectedImportFiles.value.forEach(file => {
      const idx = originalArray.indexOf(file)
      if (idx > -1) originalArray.splice(idx, 1)
    })
    selectedImportFiles.value = []
    appStore.showSnackbar('Mídias removidas do fluxo de importação.', 'success')
  }
}


// --- Lógica de Banco Profunda (Recursão / Paginacao Exaustiva de Extração) ---
const fetchAllTableRecords = async (tableName: string) => {
  const allRecords = []
  let offset = 0
  const limit = 1000
  let hasMore = true

  const shouldFilterFinancePayables = tableName === 'finance_payables' && exportConfig.financePayablesDateFilter.enabled
  const financeRange = getFinancePayablesDateRange()

  if (shouldFilterFinancePayables) {
    if (!financeRange.start || !financeRange.end) {
      throw new Error('Informe data inicial e data final para exportar finance_payables com filtro.')
    }

    if (financeRange.start >= financeRange.end) {
      throw new Error('A data final do filtro de finance_payables precisa ser maior que a data inicial.')
    }
  }

  while (hasMore) {
    let query = supabase
      .from(tableName)
      .select('*')

    if (shouldFilterFinancePayables) {
      query = query
        .gte(exportConfig.financePayablesDateFilter.column, financeRange.start)
        .lt(exportConfig.financePayablesDateFilter.column, financeRange.end)
        .order(exportConfig.financePayablesDateFilter.column, { ascending: true, nullsFirst: false })
    }

    const { data, error } = await query.range(offset, offset + limit - 1)

    if (error) {
      console.warn(`Aviso de leitura na tabela ${tableName} (Offset ${offset}):`, error.message)
      throw error
    }

    if (data && data.length > 0) {
      allRecords.push(...data)
      offset += data.length
      if (data.length < limit) hasMore = false
    } else {
      hasMore = false
    }
  }
  return allRecords
}

const fetchAllBucketFiles = async (bucketName: string) => {
  const allFiles = []
  let offset = 0
  const limit = 1000
  let hasMore = true

  while (hasMore) {
    const { data, error } = await supabase
      .storage
      .from(bucketName)
      .list('', { limit, offset })

    if (error) {
      console.warn(`Aviso de leitura no bucket ${bucketName} (Offset ${offset}):`, error.message)
      break
    }

    if (data && data.length > 0) {
      allFiles.push(...data)
      offset += data.length
      if (data.length < limit) hasMore = false
    } else {
      hasMore = false
    }
  }
  return allFiles
}

// --- Auditoria de SRE (Gravação Direta) ---
const fetchAuditLogs = async () => {
  isLoadingHistory.value = true
  try {
    const { data } = await supabase
      .from('operation_events')
      .select('*')
      .in('action_type', ['BACKUP_EXPORT', 'BACKUP_RESTORE'])
      .order('created_at', { ascending: false })
      .limit(100)

    if (data) backupHistory.value = data
  } catch (error) {
    console.error("Falha ao buscar auditoria:", error)
  } finally {
    isLoadingHistory.value = false
  }
}

const logBackupAction = async (action: 'BACKUP_EXPORT' | 'BACKUP_RESTORE', sizeBytes: number, modulesStr: string) => {
  try {
    await supabase.from('operation_events').insert({
      module_key: 'Core System',
      actor_type: 'user',
      actor_id: userStore.user?.id,
      actor_name: userStore.profile?.full_name || 'Admin',
      action_type: action,
      entity_type: 'DATABASE',
      entity_id: crypto.randomUUID(),
      entity_label: 'Cofre de Dados',
      didactic_message: action === 'BACKUP_EXPORT' ? `Exportou backup dos módulos: ${modulesStr}` : `Restaurou backup sobre os módulos: ${modulesStr}`,
      payload: { size_bytes: sizeBytes, format: '.mj' },
      severity: action === 'BACKUP_RESTORE' ? 'critical' : 'info'
    })
    await fetchAuditLogs()
  } catch(e) {
    console.error("Erro ao salvar log no banco:", e)
  }
}

// --- Criptografia ---
const getCryptoKey = async (secret: string) => {
  const enc = new TextEncoder()
  const keyMaterial = await crypto.subtle.importKey("raw", enc.encode(secret), "PBKDF2", false, ["deriveKey"])
  return crypto.subtle.deriveKey({ name: "PBKDF2", salt: enc.encode("mj-process-salt-v1"), iterations: 100000, hash: "SHA-256" }, keyMaterial, { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"])
}

const encryptBlob = async (buffer: ArrayBuffer) => {
  const key = await getCryptoKey(SYSTEM_SECRET_KEY)
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const cipher = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, buffer)
  const payload = new Uint8Array(iv.length + cipher.byteLength)
  payload.set(iv, 0)
  payload.set(new Uint8Array(cipher), iv.length)
  return new Blob([payload], { type: 'application/octet-stream' })
}

const decryptBlob = async (blob: Blob) => {
  const buffer = await blob.arrayBuffer()
  const payload = new Uint8Array(buffer)
  const iv = payload.slice(0, 12)
  const data = payload.slice(12)
  const key = await getCryptoKey(SYSTEM_SECRET_KEY)
  return await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, data)
}

// --- Métodos de Exportação ---
const getTablesToExport = (): string[] => exportConfig.isFull ? [...new Set(moduleHierarchy.flatMap(m => m.submodules).flatMap(s => s.tables))] : [...new Set(moduleHierarchy.flatMap(m => m.submodules).filter(s => exportConfig.selectedSubmodules.includes(s.id)).flatMap(s => s.tables))]
const getBucketsToExport = (): string[] => exportConfig.isFull ? availableBuckets.map(b => b.id) : exportConfig.selectedBuckets

const closeExportModal = () => {
  showExportModal.value = false; exportPhase.value = 'selection'; exportPreviewData.value = null; selectedExportKey.value = null; selectedExportType.value = null;
}

const generateExportPreview = async () => {
  const tables = getTablesToExport()
  const buckets = getBucketsToExport()

  isGeneratingPreview.value = true
  const rawData: Record<string, any[]> = {}
  const mediaData: Record<string, any[]> = {}

  try {
    for (const table of tables) {
      previewProgressText.value = `Clonando tabela: ${table}...`
      rawData[table] = await fetchAllTableRecords(table)
    }

    for (const bucket of buckets) {
      previewProgressText.value = `Mapeando bucket físico: ${bucket}...`
      const files = await fetchAllBucketFiles(bucket)

      mediaData[bucket] = []
      for (const file of files) {
        if (file.name !== '.emptyFolderPlaceholder') {
          const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(file.name)
          mediaData[bucket].push({ name: file.name, metadata: file.metadata, publicUrl: urlData.publicUrl })
        }
      }
    }

    exportPreviewData.value = { data: rawData, media: mediaData }
    if (tables.length > 0) selectExportTab('table', tables[0])
    exportPhase.value = 'preview'

  } catch (error: any) {
    appStore.showSnackbar(`Erro ao gerar preview: ${error.message}`, 'error')
  } finally {
    isGeneratingPreview.value = false
  }
}

const selectExportTab = (type: 'table' | 'bucket', key: string) => { selectedExportType.value = type; selectedExportKey.value = key; exportSearch.value = ''; }

const executeExport = async () => {
  exportPhase.value = 'executing'
  isExporting.value = true
  const zip = new JSZip()

  try {
    const rawData = exportPreviewData.value.data
    const mediaData = exportPreviewData.value.media

    zip.file('database.json', JSON.stringify(rawData))

    for (const bucket of Object.keys(mediaData)) {
      const files = mediaData[bucket]
      for (const file of files) {
        exportProgressText.value = `Baixando mídia: ${file.name}...`
        try {
          const { data: blob } = await supabase.storage.from(bucket).download(file.name)
          if (blob) {
            const arrayBuffer = await blob.arrayBuffer()
            zip.file(`media/${bucket}/${file.name}`, arrayBuffer)
          }
        } catch(e) {}
      }
    }

    const metadata = {
      version: '3.1',
      timestamp: new Date().toISOString(),
      type: exportConfig.isFull ? 'FULL' : 'GRANULAR',
      modules_exported: exportConfig.isFull ? 'All' : exportConfig.selectedSubmodules.join(','),
      buckets_exported: exportConfig.isFull ? 'All' : exportConfig.selectedBuckets.join(','),
      finance_payables_date_filter: exportConfig.financePayablesDateFilter.enabled ? {
        column: exportConfig.financePayablesDateFilter.column,
        preset: exportConfig.financePayablesDateFilter.preset,
        start: getFinancePayablesDateRange().start,
        end_exclusive: getFinancePayablesDateRange().end
      } : null
    }
    zip.file('metadata.json', JSON.stringify(metadata))

    exportProgressText.value = 'Fechando o arquivo ZIP...'
    const zipBlob = await zip.generateAsync({ type: 'blob', compression: 'DEFLATE', compressionOptions: { level: 6 } })

    exportProgressText.value = 'Selando cofre com Criptografia AES-256-GCM...'
    const encryptedZipBlob = await encryptBlob(await zipBlob.arrayBuffer())

    exportProgressText.value = 'Iniciando Download...'
    const url = URL.createObjectURL(encryptedZipBlob)
    const a = document.createElement('a')
    a.href = url
    a.download = `sistema_${exportConfig.isFull ? 'full' : 'granular'}_${new Date().getTime()}.mj`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    await logBackupAction('BACKUP_EXPORT', encryptedZipBlob.size, metadata.modules_exported)
    appStore.showSnackbar('Backup físico e relacional selado com glória!', 'success')
    closeExportModal()

  } catch (error: any) {
    appStore.showSnackbar(`Catástrofe na exportação: ${error.message}`, 'error')
    exportPhase.value = 'preview'
  } finally {
    isExporting.value = false
  }
}

// --- Métodos de Importação ---
const closeImportModal = () => { showImportModal.value = false; resetImportSelection(); }

const resetImportSelection = () => {
  selectedImportFile.value = null; importPreviewData.value = null; selectedImportType.value = null; selectedImportKey.value = null;
  isDraggingImportFile.value = false;
  excludedTables.value.clear(); excludedBuckets.value.clear(); isAnalyzingFile.value = false; isImporting.value = false;
}

const openImportFileSelector = () => {
  importFileInput.value?.click()
}

const handleFileDrop = async (event: DragEvent) => {
  isDraggingImportFile.value = false
  const file = event.dataTransfer?.files?.[0]
  if (file) await processImportFile(file)
}

const handleFileSelect = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) await processImportFile(file)
  target.value = ''
}

const processImportFile = async (file: File) => {
  selectedImportFile.value = file
  isAnalyzingFile.value = true
  importPreviewData.value = null

  try {
    const decryptedBuffer = await decryptBlob(file)
    const zip = await JSZip.loadAsync(decryptedBuffer)

    const metaFile = zip.file('metadata.json')
    const dbFile = zip.file('database.json')

    if (!metaFile || !dbFile) throw new Error('O artefato .mj não contém metadata.json e database.json.')

    const metadata = JSON.parse(await metaFile.async('string'))
    const dbData = JSON.parse(await dbFile.async('string'))

    const mediaMap: Record<string, any[]> = {}
    zip.folder('media/')?.forEach((relativePath, fileObj) => {
      if (!fileObj.dir) {
         const parts = relativePath.split('/')
         const bucket = parts[0]
         const fileName = parts.slice(1).join('/')
         if (!bucket || !fileName) return
         if (!mediaMap[bucket]) mediaMap[bucket] = []
         mediaMap[bucket].push({ name: fileName, zipObject: fileObj, objectUrl: null })
      }
    })

    const tableNames = Object.keys(dbData)
    importPreviewData.value = { ...metadata, tableCount: tableNames.length, bucketCount: Object.keys(mediaMap).length, data: dbData, media: mediaMap }
    if (tableNames.length > 0) selectImportTab('table', tableNames[0])
  } catch (error: any) {
    console.error('Falha ao abrir arquivo de backup:', error)
    appStore.showSnackbar(`Falha ao decifrar/abrir backup: ${error.message || 'arquivo corrompido ou chave inválida.'}`, 'error')
    resetImportSelection()
  } finally {
    isAnalyzingFile.value = false
  }
}


const selectImportTab = async (type: 'table' | 'bucket', key: string) => {
  selectedImportType.value = type; selectedImportKey.value = key; importSearch.value = '';

  if (type === 'bucket' && importPreviewData.value) {
    const files = importPreviewData.value.media[key]
    for (const file of files) {
      if (!file.objectUrl && isImage(file.name)) {
        try {
          const blobData = await file.zipObject.async('blob')
          file.objectUrl = URL.createObjectURL(blobData)
        } catch(e) {}
      }
    }
  }
}

const toggleTableExclusion = (tableName: string) => excludedTables.value.has(tableName) ? excludedTables.value.delete(tableName) : excludedTables.value.add(tableName)
const toggleBucketExclusion = (bucketName: string) => excludedBuckets.value.has(bucketName) ? excludedBuckets.value.delete(bucketName) : excludedBuckets.value.add(bucketName)

const deleteImportPreviewRow = (tableName: string, rowObj: any) => {
  if (importPreviewData.value && importPreviewData.value.data[tableName]) {
     const originalArray = importPreviewData.value.data[tableName]
     const idx = originalArray.indexOf(rowObj)
     if (idx > -1) { originalArray.splice(idx, 1); appStore.showSnackbar('Registro varrido da restauração.', 'success') }
  }
}

const deleteImportPreviewFile = (bucketName: string, fileObj: any) => {
   if (importPreviewData.value && importPreviewData.value.media[bucketName]) {
     const originalArray = importPreviewData.value.media[bucketName]
     const idx = originalArray.indexOf(fileObj)
     if (idx > -1) { originalArray.splice(idx, 1); appStore.showSnackbar('Mídia removida da restauração.', 'success') }
  }
}

const executeImport = async () => {
  if (!importPreviewData.value) return
  isImporting.value = true

  try {
    const tablesToRestore = Object.keys(importPreviewData.value.data).filter(t => !excludedTables.value.has(t))
    for (const table of tablesToRestore) {
      importProgressText.value = `Sobrescrevendo tabela: ${table}...`
      const records = importPreviewData.value.data[table]

      if (records && records.length > 0) {
        const chunkSize = 500 // Batching para não estourar a API Payload
        for (let i = 0; i < records.length; i += chunkSize) {
           const chunk = records.slice(i, i + chunkSize)
           const upsertOptions = table === 'finance_payables' ? { onConflict: 'id' } : undefined
           const { error } = await supabase.from(table).upsert(chunk, upsertOptions)
           if (error) {
             console.warn(`Aviso em ${table}:`, error.message)
             throw error
           }
        }
      }
    }

    const bucketsToRestore = Object.keys(importPreviewData.value.media).filter(b => !excludedBuckets.value.has(b))
    for (const bucket of bucketsToRestore) {
      const files = importPreviewData.value.media[bucket]
      for (const fileObj of files) {
        importProgressText.value = `Restaurando Físico: ${fileObj.name}...`
        const blobData = await fileObj.zipObject.async('blob')
        await supabase.storage.from(bucket).upload(fileObj.name, blobData, { upsert: true })
      }
    }

    importProgressText.value = 'Concluindo ritual e acordando o Sistema...'
    await logBackupAction('BACKUP_RESTORE', selectedImportFile.value!.size, importPreviewData.value.modules_exported)

    setTimeout(() => {
      appStore.showSnackbar('Sistema restaurado. A ressurreição foi um sucesso absoluto.', 'success')
      closeImportModal()
    }, 1500)

  } catch (error: any) {
    appStore.showSnackbar(`Catástrofe na restauração: ${error.message}`, 'error')
    isImporting.value = false
  }
}

// --- Gráficos ApexCharts ---
const chartOptionsText = computed(() => isDark.value ? '#e0e0e0' : '#333')

const areaChartOptions = computed(() => ({
  chart: { type: 'area', toolbar: { show: false }, background: 'transparent', sparkline: { enabled: false } },
  theme: { mode: isDark.value ? 'dark' : 'light' },
  stroke: { curve: 'smooth', width: 2 },
  fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.05, stops: [0, 100] } },
  dataLabels: { enabled: false },
  xaxis: { categories: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'], labels: { style: { colors: chartOptionsText.value } } },
  yaxis: { labels: { style: { colors: chartOptionsText.value } } },
  colors: ['#2196F3', '#FF9800'],
  legend: { position: 'top', labels: { colors: chartOptionsText.value } }
}))

const areaChartSeries = ref([
  { name: 'Leituras (Queries)', data: [12000, 15000, 14000, 18000, 16000, 9000, 7000] },
  { name: 'Escritas (Mutations)', data: [3000, 4500, 4000, 5200, 4800, 2000, 1500] },
])

const operationsChartOptions = computed(() => ({
  chart: { type: 'donut', background: 'transparent' },
  theme: { mode: isDark.value ? 'dark' : 'light' },
  labels: ['Auditoria (SRE)', 'Autenticação', 'Relatórios', 'Webhooks'],
  colors: ['#9C27B0', '#4CAF50', '#03A9F4', '#F44336'],
  stroke: { width: 0 },
  legend: { position: 'bottom', labels: { colors: chartOptionsText.value } }
}))
const operationsChartSeries = ref([45000, 12000, 35000, 8000])

onMounted(() => {
  fetchAuditLogs()
})
</script>

<style scoped>
.bg-background { background-color: #f4f6f8; }
.bg-surface-dark { background-color: #1a1a1f; }
.border-white-10 { border-color: rgba(255, 255, 255, 0.1) !important; }
.border-white-20 { border-color: rgba(255, 255, 255, 0.2) !important; }

/* Aspecto 3D Enterprise */
.btn-3d {
  border-radius: 8px !important;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1), inset 0 2px 0 rgba(255,255,255,0.2) !important;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px);
  box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.1) !important;
}
.chip-3d {
  box-shadow: 0 2px 4px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.shadow-sm { box-shadow: 0 4px 12px rgba(0,0,0,0.05) !important; }
.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }
.border-dashed { border-style: dashed !important; border-width: 1px; }

.hover-card { transition: transform 0.2s ease, box-shadow 0.2s ease; }
.hover-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.1) !important; }

.tracking-widest { letter-spacing: 0.05em; }
.tracking-wide { letter-spacing: 0.02em; }
.ls-1 { letter-spacing: 0.5px; }
.lh-1 { line-height: 1.1; }
.line-clamp-1 { display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* Grid Alinhado */
.grid-header, .grid-row {
  display: grid; align-items: stretch; width: 100%; border-bottom: 1px solid rgba(0,0,0,0.06);
}
.cell { padding: 12px 16px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.04); font-size: 13px; }
.cell:last-child { border-right: none; }
.header-text { padding: 14px 16px; font-size: 11px; font-weight: 900; color: rgba(0,0,0,0.6); }

.cell.center, .header-text.center { justify-content: center; text-align: center; }

.grid-surface-light .cell { background: #f8fafc; border-color: rgba(0,0,0,0.08); }
.grid-surface-dark .cell { background: rgba(255,255,255,0.04); color: rgba(255,255,255,0.7); border-color: rgba(255,255,255,0.08); }

.grid-row-light .cell { background: #ffffff; border-color: rgba(0,0,0,0.05); }
.grid-row-dark .cell { background: transparent; border-color: rgba(255,255,255,0.05); color: rgba(255,255,255,0.9); }

.hover-bg-row:hover .cell { background: #f1f5f9 !important; }
.grid-row-dark.hover-bg-row:hover .cell { background: rgba(255,255,255,0.06) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #fafafa; }
.zebra-dark-a .cell { background: rgba(255,255,255,0.01); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }

.sticky-head { position: sticky; top: 0; z-index: 10; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }

/* V-Table Customization */
.table-striped tbody tr:nth-of-type(odd) { background-color: rgba(0,0,0,0.02); }
.grid-row-dark.table-striped tbody tr:nth-of-type(odd) { background-color: rgba(255,255,255,0.02); }

/* Animações e Scrollbars */
.animate-fade-in { animation: fadeIn 0.4s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

@keyframes pulse-green { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
.icon-pulse { animation: pulse-green 2s infinite; }

.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.3); border-radius: 4px; }
.custom-scroll::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128, 0.5); }
</style>
