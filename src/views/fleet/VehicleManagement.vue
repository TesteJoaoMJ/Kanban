<template>
  <div
    class="fleet-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        v-if="!isMobileFullscreen"
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Logística</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Gestão de Frota</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Controle de Veículos
             </div>
          </div>
        </div>

        <div class="d-none d-md-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="blue-darken-3"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0"
            prepend-icon="mdi-refresh"
            height="40"
            @click="fetchVehicles"
          >
            Atualizar
          </v-btn>

          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
            prepend-icon="mdi-plus"
            height="40"
            @click="openNewVehicleModal"
          >
             Novo Veículo
          </v-btn>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 py-2 flex-shrink-0">
        <v-row class="d-none d-md-flex">
          <v-col cols="12" sm="6" md="" v-for="(kpi, idx) in kpiList" :key="idx">
            <v-card
              class="kpi-card kpi-rect bg-gradient-custom hover-elevate py-3 px-4 cursor-pointer"
              :class="[kpi.gradient]"
              v-ripple
              elevation="2"
              @click="handleKpiClick(kpi.label)"
            >
              <div class="kpi-bg-icon"><v-icon>{{ kpi.icon }}</v-icon></div>
              <div class="d-flex flex-column position-relative z-10 justify-space-between fill-height">
                <div class="d-flex align-center" style="gap: 8px;">
                  <v-icon size="18" class="opacity-80">{{ kpi.icon }}</v-icon>
                  <span class="kpi-label">{{ kpi.label }}</span>
                </div>
                <div class="kpi-number-group my-1">
                  <span class="kpi-value">{{ kpi.value }}</span>
                </div>
                <div class="kpi-footer mt-1">{{ kpi.footer }}</div>
              </div>
            </v-card>
          </v-col>
        </v-row>

        <div class="d-block d-md-none kpi-mobile-wrapper my-2">
          <v-window v-model="kpiModel" show-arrows class="elevation-4 rounded-xl overflow-hidden shadow-lg">
             <template v-slot:prev="{ props }"><v-btn variant="flat" icon="mdi-chevron-left" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn></template>
             <template v-slot:next="{ props }"><v-btn variant="flat" icon="mdi-chevron-right" @click="props.onClick" color="rgba(0,0,0,0.3)" size="small" class="text-white backdrop-blur-sm"></v-btn></template>
             <v-window-item v-for="(kpi, idx) in kpiList" :key="idx">
                <v-card class="kpi-card-mobile d-flex flex-column align-center justify-center py-6 px-4 text-center relative" :class="[kpi.gradient]" @click="handleKpiClick(kpi.label)" height="140" elevation="0" v-ripple>
                    <div class="kpi-bg-icon-mobile"><v-icon>{{ kpi.icon }}</v-icon></div>
                    <div class="d-flex flex-column align-center relative z-10 w-100">
                        <div class="d-flex align-center justify-center mb-1 bg-white-20 px-3 py-1 rounded-pill backdrop-blur-sm" style="max-width: 80%;">
                            <v-icon size="16" class="mr-2 text-white">{{ kpi.icon }}</v-icon>
                            <span class="text-caption font-weight-black text-uppercase text-white tracking-wide text-truncate">{{ kpi.label }}</span>
                        </div>
                        <div class="text-h3 font-weight-black text-white my-2 text-shadow-sm">{{ kpi.value }}</div>
                        <div class="text-caption text-white font-weight-medium opacity-90">{{ kpi.footer }}</div>
                    </div>
                </v-card>
             </v-window-item>
          </v-window>
          <div class="d-flex justify-center mt-3 gap-2">
              <div v-for="(k, i) in kpiList" :key="i" class="kpi-dot transition-all rounded-circle cursor-pointer" :class="kpiModel === i ? 'bg-success w-3 h-3 elevation-2' : 'bg-grey-lighten-2 w-2 h-2 opacity-50'" @click="kpiModel = i"></div>
          </div>
        </div>
      </div>

      <div v-if="!isMobileFullscreen" class="px-4 px-md-6 pt-0 pb-2 flex-shrink-0">
        <div v-if="mobile" class="d-flex align-center gap-2">
             <v-btn color="success" variant="flat" class="btn-3d flex-shrink-0" height="44" icon="mdi-plus" @click="openNewVehicleModal"></v-btn>
             <div class="flex-grow-1 relative search-wrap rounded bg-white border d-flex align-center" style="height: 44px;">
                <input v-model="search" type="text" placeholder="Buscar placa, modelo..." class="clean-input w-100 h-100 px-3 font-weight-bold" style="outline: none;"/>
                <v-icon size="small" class="mr-3 text-grey-darken-1">mdi-magnify</v-icon>
            </div>
        </div>
        <div v-else class="controls-bar d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark'" style="gap: 10px;">
          <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between" style="gap: 10px;">
            <div class="d-flex align-center flex-wrap w-100 w-md-auto" style="gap: 10px;">
               <span class="text-caption font-weight-bold opacity-70 ml-2">Utilize a barra de pesquisa para filtrar os veículos.</span>
            </div>
            <div class="d-flex align-center flex-wrap justify-end w-100 w-md-auto" style="gap: 10px;">
              <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light' : 'search-dark'">
                <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'">mdi-magnify</v-icon>
                <input v-model="search" type="text" placeholder="Pesquisar veículo, placa, motorista..." class="clean-input flex-grow-1" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        class="flex-grow-1 overflow-hidden d-flex flex-column transition-all"
        :class="isMobileFullscreen ? 'absolute top-0 left-0 w-100 h-100 z-20 bg-white' : 'px-4 px-md-6 pb-4'"
      >
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-0 border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div v-if="!mobile" class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark', 'grid-fleet']"
            >
              <div class="cell cell-check center"><v-icon size="small" color="grey">mdi-car</v-icon></div>
              <div class="cell center header-text">Foto</div>
              <div class="cell center header-text">Placa</div>
              <div class="cell header-text">Marca / Modelo</div>
              <div class="cell header-text">Motorista Responsável</div>
              <div class="cell center header-text">Empresa</div>
              <div class="cell center header-text">Status</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
              <span class="text-caption mt-2 font-weight-bold opacity-60">Carregando Frota...</span>
            </div>

            <div v-else-if="filteredVehicles.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-car-off</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhum veículo encontrado.</span>
            </div>

            <div
              v-else
              v-for="(item, index) in filteredVehicles"
              :key="item.id"
              class="grid-row"
              :class="[
                themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark',
                zebraClass(index),
                'grid-fleet'
              ]"
            >
                <div class="cell cell-check center">
                   <div class="status-indicator" :class="getStatusDotClass(item.status)"></div>
                </div>
                <div class="cell center">
                    <v-avatar size="36" rounded="lg" class="border-thin shadow-sm">
                        <v-img :src="item.photo_url || '/placeholder.png'" cover></v-img>
                    </v-avatar>
                </div>
                <div class="cell center">
                    <span class="pill-ref text-blue-darken-3 bg-blue-lighten-5">{{ item.plate || 'S/ PLACA' }}</span>
                </div>
                <div class="cell d-flex flex-column align-start justify-center" style="line-height: 1.2;">
                    <div class="text-truncate list-text-11 font-weight-bold text-grey-darken-4">{{ item.brand }} {{ item.model }}</div>
                    <div class="text-caption opacity-70">{{ item.year }} • {{ item.color }}</div>
                </div>
                <div class="cell d-flex flex-column align-start justify-center" style="line-height: 1.2;">
                    <div class="text-truncate list-text-11 font-weight-medium text-grey-darken-3">{{ item.driver_name || 'Não atribuído' }}</div>
                    <div class="d-flex align-center gap-2 mt-1">
                        <div class="text-[10px] font-weight-medium opacity-80" v-if="item.driver_phone">
                            <v-icon size="10" color="grey-darken-1" class="mr-1">mdi-phone</v-icon>{{ item.driver_phone }}
                        </div>
                    </div>
                </div>
                <div class="cell center"><span class="list-text-11 font-weight-bold text-grey-darken-2">{{ getCompanyName(item.company_id) || 'N/A' }}</span></div>
                <div class="cell center"><span class="solid-chip chip-3d" :class="getStatusChipClass(item.status)">{{ item.status }}</span></div>
                <div class="cell center">
                    <div class="actions-inline">
                        <v-btn icon size="small" class="action-btn action-edit btn-3d" @click.stop="openEditModal(item)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn icon size="small" class="action-btn action-del btn-3d" @click.stop="deleteVehicle(item)" title="Excluir" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                    </div>
                </div>
            </div>
          </div>

          <div v-else class="flex-grow-1 overflow-y-auto bg-grey-lighten-4 pb-12 custom-scroll">
              <div v-if="loading" class="d-flex flex-column align-center justify-center py-8"><v-progress-circular indeterminate color="success"></v-progress-circular></div>
              <div v-else-if="filteredVehicles.length === 0" class="d-flex flex-column align-center justify-center py-10 opacity-60"><v-icon size="40">mdi-car-off</v-icon></div>
              <div v-else class="d-flex flex-column gap-3 pa-3">
                 <div
                    v-for="(item, index) in filteredVehicles"
                    :key="item.id"
                    class="bg-white rounded-lg border-thin pa-4 elevation-1 relative overflow-hidden"
                 >
                    <div class="d-flex justify-space-between align-center mb-3">
                        <div class="d-flex align-center gap-3">
                            <v-avatar size="40" rounded="lg" class="border shadow-sm"><v-img :src="item.photo_url || '/placeholder.png'" cover></v-img></v-avatar>
                            <div>
                                <div class="text-subtitle-2 font-weight-black text-grey-darken-4 leading-tight">{{ item.brand }} {{ item.model }}</div>
                                <div class="text-caption text-grey">{{ item.plate }}</div>
                            </div>
                        </div>
                        <v-chip size="small" :color="item.status === 'ativo' ? 'success' : (item.status === 'manutencao' ? 'error' : 'warning')" variant="flat" class="font-weight-black text-white text-uppercase px-2 chip-3d" style="height: 22px; font-size: 10px;">
                             {{ item.status }}
                        </v-chip>
                    </div>
                    <v-divider class="mb-3 border-opacity-50"></v-divider>
                    <div class="d-flex gap-2">
                         <v-btn class="flex-grow-1 font-weight-bold btn-3d text-white" variant="flat" color="info" height="36" @click.stop="openEditModal(item)">
                            <v-icon size="18" class="mr-1">mdi-pencil</v-icon> Editar
                         </v-btn>
                         <v-btn class="flex-grow-0 font-weight-bold btn-3d text-white" variant="flat" color="error" height="36" min-width="36" width="36" @click.stop="deleteVehicle(item)">
                            <v-icon size="18">mdi-trash-can-outline</v-icon>
                         </v-btn>
                    </div>
                 </div>
              </div>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog
        v-model="editModal.show"
        max-width="1200px"
        max-height="95vh"
        persistent
        scrim="black opacity-90"
        transition="dialog-bottom-transition"
        class="fixed-dialog"
    >
        <v-card class="d-flex flex-row rounded-0 overflow-hidden font-sans border border-grey-darken-2 bg-grey-lighten-4" elevation="24" style="min-height: 60vh;">

            <div class="sidebar-menu d-flex flex-column flex-shrink-0 bg-grey-darken-4 text-white border-r border-grey-darken-3 shadow-md" style="width: 290px; z-index: 20;">
                <div class="pa-6 d-flex flex-column align-center text-center border-b border-white-10 relative">
                    <v-btn icon size="x-small" variant="text" color="white" class="absolute top-2 right-2 d-md-none rounded-0" @click="editModal.show = false"><v-icon>mdi-close</v-icon></v-btn>

                    <div class="relative mb-4 group cursor-pointer" @click="$refs.mainPhotoInput.click()">
                        <v-avatar size="100" class="rounded-0 border-white-20 bg-grey-darken-3 transition-all">
                            <v-img v-if="editModal.previewImage || editModal.form.photo_url" :src="editModal.previewImage || editModal.form.photo_url" cover></v-img>
                            <v-icon v-else size="40" color="grey-lighten-1">mdi-car</v-icon>
                        </v-avatar>
                        <div class="avatar-overlay absolute inset-0 d-flex align-center justify-center rounded-0 opacity-0 group-hover:opacity-100 transition-all bg-black-70">
                            <v-icon color="white" size="24">mdi-camera-plus</v-icon>
                        </div>
                        <input type="file" ref="mainPhotoInput" accept="image/*" class="d-none" @change="handleMainPhotoUpload">
                    </div>

                    <h3 class="text-subtitle-1 font-weight-black leading-tight mb-1 text-white uppercase">{{ editModal.form.plate || 'NOVO VEÍCULO' }}</h3>
                    <div class="text-[11px] font-weight-bold text-grey-lighten-1 text-uppercase tracking-widest mb-3">
                        {{ editModal.form.brand || '---' }} {{ editModal.form.model || '---' }}
                    </div>
                    <div class="d-flex align-center gap-2 justify-center w-100">
                        <span class="text-[10px] font-weight-bold px-2 py-1 bg-blue-grey-darken-3 rounded-0 text-uppercase border border-white-10">{{ getCompanyName(editModal.form.company_id) || '---' }}</span>
                        <span class="text-[10px] font-weight-bold px-2 py-1 rounded-0 text-uppercase border border-white-10" :class="editModal.form.status === 'ativo' ? 'bg-green-darken-3' : (editModal.form.status === 'manutencao' ? 'bg-red-darken-3' : 'bg-orange-darken-3')">{{ editModal.form.status }}</span>
                    </div>
                </div>

                <v-tabs v-model="editModal.activeTab" direction="vertical" color="white" class="flex-grow-1 custom-scroll" slider-color="white">
                    <v-tab :value="0" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-car-info</v-icon> Dados do Veículo</v-tab>
                    <v-tab :value="1" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-card-account-details</v-icon> Emplacamento e Chassi</v-tab>
                    <v-tab :value="2" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-steering</v-icon> Motorista Principal</v-tab>
                    <v-tab :value="3" class="text-none font-weight-bold justify-start px-5 tab-item"><v-icon start size="18" class="opacity-70">mdi-folder-multiple-image</v-icon> Fichário de Documentos <span class="ml-auto font-mono text-[10px] bg-white text-black px-1 rounded-0" v-if="editModal.form.attachments?.length">{{ editModal.form.attachments.length }}</span></v-tab>
                </v-tabs>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden relative bg-grey-lighten-4">
                <div class="px-6 py-4 d-flex justify-space-between align-center border-b border-grey-lighten-2 bg-white flex-shrink-0 z-10 shadow-sm">
                    <div class="text-subtitle-1 font-weight-black text-uppercase text-grey-darken-4 d-flex align-center gap-2 tracking-widest">
                        <v-icon color="grey-darken-3" size="20">{{ tabIcons[editModal.activeTab] }}</v-icon>
                        {{ tabTitles[editModal.activeTab] }}
                    </div>
                    <div class="d-flex align-center gap-3">
                        <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" height="42" @click="editModal.show = false">DESCARTAR</v-btn>
                        <v-btn color="success" variant="flat" class="btn-rect font-weight-black px-8 shadow-sm text-body-2 tracking-widest" height="42" :loading="editModal.loading" @click="saveVehicle">
                            <v-icon start>mdi-content-save-check</v-icon> SALVAR VEÍCULO
                        </v-btn>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-6 custom-scroll">
                    <v-form @submit.prevent id="vehicleForm">
                        <v-window v-model="editModal.activeTab" :touch="false" class="overflow-visible">
                            <v-window-item :value="0">
                                <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                                    <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Detalhes Básicos da Frota</div>
                                    <div class="pa-5">
                                        <v-row dense class="row-gap">
                                            <v-col cols="12" md="6"><label class="input-label">Marca *</label><v-text-field v-model="editModal.form.brand" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" required></v-text-field></v-col>
                                            <v-col cols="12" md="6"><label class="input-label">Modelo *</label><v-text-field v-model="editModal.form.model" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold" required></v-text-field></v-col>
                                            <v-col cols="12" md="4"><label class="input-label">Ano Fabricação *</label><v-text-field v-model.number="editModal.form.year" type="number" variant="outlined" density="compact" color="primary" class="ui-field font-mono font-weight-bold"></v-text-field></v-col>
                                            <v-col cols="12" md="4"><label class="input-label">Cor Predominante</label><v-text-field v-model="editModal.form.color" variant="outlined" density="compact" color="primary" class="ui-field"></v-text-field></v-col>
                                            <v-col cols="12" md="4"><label class="input-label">Empresa Proprietária</label><v-autocomplete v-model="editModal.form.company_id" :items="companies" item-title="trade_name" item-value="id" variant="outlined" density="compact" color="primary" class="ui-field" clearable></v-autocomplete></v-col>
                                            <v-col cols="12" md="12"><label class="input-label">Status Operacional</label><v-select v-model="editModal.form.status" :items="['ativo', 'manutencao', 'inativo']" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold"></v-select></v-col>
                                        </v-row>
                                    </div>
                                </v-card>
                            </v-window-item>

                            <v-window-item :value="1">
                                <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                                    <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Documentação Legal e Chassi</div>
                                    <div class="pa-5">
                                        <v-row dense class="row-gap">
                                            <v-col cols="12" md="4"><label class="input-label">Placa (Mercosul/Antiga)*</label><v-text-field v-model="editModal.form.plate" variant="outlined" density="compact" color="primary" class="ui-field text-uppercase font-weight-bold font-mono" required></v-text-field></v-col>
                                            <v-col cols="12" md="4"><label class="input-label">RENAVAM</label><v-text-field v-model="editModal.form.renavam" variant="outlined" density="compact" color="primary" class="ui-field font-mono"></v-text-field></v-col>
                                            <v-col cols="12" md="4"><label class="input-label">Estado (UF)</label><v-select v-model="editModal.form.registration_state" :items="ufList" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold"></v-select></v-col>
                                            <v-col cols="12"><label class="input-label">Chassi</label><v-text-field v-model="editModal.form.chassis" variant="outlined" density="compact" color="primary" class="ui-field font-mono text-uppercase"></v-text-field></v-col>
                                        </v-row>
                                    </div>
                                </v-card>
                            </v-window-item>

                            <v-window-item :value="2">
                                <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm mb-6 bg-white" elevation="0">
                                    <div class="px-5 py-3 border-b bg-grey-lighten-4 text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Condutor Principal / Responsável</div>
                                    <div class="pa-0">
                                        <div class="d-flex flex-column flex-md-row w-100">
                                            <div class="d-flex flex-column align-center justify-center py-6 px-4 border-e-md border-dashed" style="width: 250px; min-width: 250px; background-color: #fafafa;">
                                                <div class="text-caption font-weight-bold opacity-70 mb-4 text-uppercase">Foto do Condutor</div>
                                                <div class="relative group cursor-pointer d-inline-block" @click="$refs.driverPhotoInput.click()">
                                                    <v-avatar size="140" class="rounded-0 border border-grey-lighten-2 bg-white transition-all shadow-sm">
                                                        <v-img v-if="editModal.driverPreviewImage || editModal.form.driver_photo_url" :src="editModal.driverPreviewImage || editModal.form.driver_photo_url" cover></v-img>
                                                        <v-icon v-else size="50" color="grey-lighten-1">mdi-account-tie-steering</v-icon>
                                                    </v-avatar>
                                                    <div class="avatar-overlay absolute inset-0 d-flex align-center justify-center rounded-0 opacity-0 group-hover:opacity-100 transition-all bg-black-70">
                                                        <v-icon color="white" size="28">mdi-camera-plus</v-icon>
                                                    </div>
                                                </div>
                                                <input type="file" ref="driverPhotoInput" class="d-none" accept="image/*" @change="handleDriverPhotoUpload">
                                                <div v-if="editModal.form.driver_photo_url || editModal.driverFileToUpload" class="mt-4">
                                                    <v-btn size="x-small" variant="outlined" color="error" class="rounded-0 font-weight-bold" @click="clearDriverPhoto">Remover Foto</v-btn>
                                                </div>
                                            </div>

                                            <div class="flex-grow-1 pa-6">
                                                <v-row dense class="row-gap">
                                                    <v-col cols="12"><label class="input-label">Nome Completo</label><v-text-field v-model="editModal.form.driver_name" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold"></v-text-field></v-col>
                                                    <v-col cols="12" md="6"><label class="input-label">CPF</label><v-text-field v-model="editModal.form.driver_cpf" variant="outlined" density="compact" color="primary" class="ui-field font-mono" v-maska="'###.###.###-##'"></v-text-field></v-col>
                                                    <v-col cols="12" md="6"><label class="input-label">Telefone / WhatsApp</label><v-text-field v-model="editModal.form.driver_phone" variant="outlined" density="compact" color="primary" class="ui-field font-mono" v-maska="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>

                                                    <v-col cols="12" md="4"><label class="input-label">Nº CNH</label><v-text-field v-model="editModal.form.driver_cnh" variant="outlined" density="compact" color="primary" class="ui-field font-mono"></v-text-field></v-col>
                                                    <v-col cols="12" md="4"><label class="input-label">Categoria CNH</label><v-select v-model="editModal.form.driver_cnh_category" :items="['A','B','AB','C','D','E']" variant="outlined" density="compact" color="primary" class="ui-field font-weight-bold"></v-select></v-col>
                                                    <v-col cols="12" md="4"><label class="input-label">Validade CNH</label><v-text-field v-model="editModal.form.driver_cnh_expiry" type="date" variant="outlined" density="compact" color="primary" class="ui-field font-mono"></v-text-field></v-col>
                                                </v-row>
                                            </div>
                                        </div>
                                    </div>
                                </v-card>
                            </v-window-item>

                            <v-window-item :value="3">
                                <v-card class="rounded-0 border border-grey-lighten-2 shadow-sm bg-white" elevation="0">
                                    <div class="px-5 py-3 border-b bg-grey-lighten-4 d-flex justify-space-between align-center">
                                          <div class="text-[11px] font-weight-black text-uppercase text-grey-darken-3 d-flex align-center gap-2">Organização de Arquivos do Veículo</div>
                                          <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-bold rounded-0" size="small" prepend-icon="mdi-upload" @click="showDocModal = true">Arquivar Documento</v-btn>
                                    </div>

                                    <v-expansion-panels variant="accordion" class="custom-expansion rounded-0">
                                        <v-expansion-panel v-for="cat in docCategories" :key="cat" class="border-b bg-white rounded-0">
                                            <v-expansion-panel-title class="py-3 px-5">
                                                <div class="d-flex align-center gap-3 w-100">
                                                    <v-icon color="grey-darken-3" size="20">mdi-folder</v-icon>
                                                    <span class="font-weight-bold text-[12px] text-uppercase text-grey-darken-3">{{ cat }}</span>
                                                    <span class="ml-auto mr-4 font-mono text-[10px] font-weight-black bg-grey-lighten-3 px-2 py-1 rounded-0 border">{{ getDocsByCategory(cat).length }}</span>
                                                </div>
                                            </v-expansion-panel-title>
                                            <v-expansion-panel-text class="bg-grey-lighten-5 pt-3 pb-3 px-5 border-t border-dashed">
                                                <div v-if="getDocsByCategory(cat).length === 0" class="text-center py-2 opacity-50 text-[10px] font-weight-bold font-italic text-uppercase">Pasta vazia.</div>
                                                <v-row dense v-else>
                                                    <v-col cols="12" md="6" lg="4" v-for="doc in getDocsByCategory(cat)" :key="doc.url">
                                                        <v-card variant="outlined" class="pa-2 border-grey-lighten-2 bg-white d-flex align-center justify-space-between rounded-0 shadow-sm hover-row cursor-pointer" @click="window.open(doc.url, '_blank')">
                                                            <div class="d-flex align-center gap-3 overflow-hidden">
                                                                <v-icon :color="doc.url.includes('.pdf') ? 'red-darken-3' : 'blue-grey-darken-2'" size="28">{{ doc.url.includes('.pdf') ? 'mdi-file-pdf-box' : 'mdi-image-outline' }}</v-icon>
                                                                <div class="overflow-hidden">
                                                                    <div class="text-[11px] font-weight-black text-truncate text-grey-darken-4" :title="doc.name">{{ doc.name }}</div>
                                                                    <div class="text-[9px] opacity-70 mt-0 font-mono">{{ formatDate(doc.uploaded_at) }}</div>
                                                                </div>
                                                            </div>
                                                            <v-btn icon size="x-small" variant="text" color="error" class="rounded-0" @click.stop="removeSavedAttachment(doc)"><v-icon size="14">mdi-delete</v-icon></v-btn>
                                                        </v-card>
                                                    </v-col>
                                                </v-row>
                                            </v-expansion-panel-text>
                                        </v-expansion-panel>
                                    </v-expansion-panels>
                                </v-card>
                            </v-window-item>
                        </v-window>
                    </v-form>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showDocModal" max-width="400">
        <v-card class="pa-5 rounded-0 border border-grey-darken-1 bg-white shadow-md">
            <h3 class="text-[13px] font-weight-black mb-4 text-uppercase tracking-widest text-grey-darken-3 border-b pb-2">Arquivar Documento</h3>
            <label class="input-label">Pasta de Destino</label>
            <v-select v-model="newDocCategory" :items="docCategories" variant="outlined" density="compact" class="ui-field font-weight-bold mb-2"></v-select>

            <label class="input-label">Arquivo (PDF/Imagem)</label>
            <v-file-input v-model="newDocFile" variant="outlined" density="compact" prepend-inner-icon="mdi-paperclip" prepend-icon="" class="ui-field font-weight-bold mb-2"></v-file-input>

            <label class="input-label">Nome Personalizado (Opcional)</label>
            <v-text-field v-model="newDocCustomName" placeholder="Se vazio, usa original" variant="outlined" density="compact" class="ui-field mb-4"></v-text-field>

            <div class="d-flex justify-end gap-2">
                <v-btn variant="outlined" color="grey-darken-2" class="btn-rect font-weight-bold bg-white" @click="showDocModal = false">Cancelar</v-btn>
                <v-btn color="grey-darken-4" variant="flat" class="btn-rect font-weight-black px-6" :loading="uploadingDoc" @click="executeDocUpload">Arquivar</v-btn>
            </div>
        </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useThemeStore } from '@/stores/theme';
import { useAppStore } from '@/stores/app';
import { useDisplay } from 'vuetify';
import { vMaska } from "maska/vue";
import { format } from 'date-fns';

const themeStore = useThemeStore();
const appStore = useAppStore();
const { mobile } = useDisplay();

// Estado Principal
const loading = ref(false);
const vehicles = ref<any[]>([]);
const companies = ref<any[]>([]);
const search = ref('');
const isMobileFullscreen = ref(false);

const ufList = ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];

const tabTitles = ['Ficha Cadastral do Veículo', 'Documentação e Emplacamento', 'Condutor Responsável', 'Cofre de Arquivos (Fichário)'];
const tabIcons = ['mdi-car-info', 'mdi-card-account-details', 'mdi-steering', 'mdi-folder-multiple-image'];
const docCategories = ['Documento do Veículo (CRLV)', 'Seguros e Apólices', 'CNH do Condutor', 'Laudos e Vistorias', 'Multas e Infrações', 'Comprovantes de Manutenção', 'Outros'];

// Modais Secundários
const showDocModal = ref(false);
const newDocCategory = ref(docCategories[0]);
const newDocFile = ref<File | null>(null);
const newDocCustomName = ref('');
const uploadingDoc = ref(false);

// Modal de Edição
const defaultItem = {
    id: '', plate: '', brand: '', model: '', year: new Date().getFullYear(), color: '',
    status: 'ativo', company_id: null as string|null, photo_url: null as string|null,
    renavam: '', chassis: '', registration_state: 'SP',
    driver_name: '', driver_phone: '', driver_cpf: '', driver_cnh: '', driver_cnh_category: '', driver_cnh_expiry: '', driver_photo_url: null as string|null,
    attachments: [] as any[]
};

const editModal = reactive({
    show: false,
    loading: false,
    activeTab: 0,
    form: JSON.parse(JSON.stringify(defaultItem)),
    previewImage: null as string | null,
    fileToUpload: null as File | null,
    driverPreviewImage: null as string | null,
    driverFileToUpload: null as File | null,
    newDocsToUpload: [] as File[]
});

// Referências DOM
const mainPhotoInput = ref<HTMLInputElement | null>(null);
const driverPhotoInput = ref<HTMLInputElement | null>(null);
const docsInput = ref<HTMLInputElement | null>(null);

// Computed / Filtragem
const activeVehicles = computed(() => vehicles.value.filter(v => v.status === 'ativo').length);
const maintenanceVehicles = computed(() => vehicles.value.filter(v => v.status === 'manutencao').length);
const filteredVehicles = computed(() => {
    if (!search.value) return vehicles.value;
    const term = search.value.toLowerCase();
    return vehicles.value.filter(v =>
        v.plate?.toLowerCase().includes(term) ||
        v.model?.toLowerCase().includes(term) ||
        v.brand?.toLowerCase().includes(term) ||
        v.driver_name?.toLowerCase().includes(term)
    );
});

// KPIs
const kpiModel = ref(0);
const kpiList = computed(() => ([
  { label: 'Total Veículos', value: vehicles.value.length, footer: 'Frota Cadastrada', icon: 'mdi-car-multiple', gradient: 'bg-gradient-info' },
  { label: 'Ativos', value: activeVehicles.value, footer: 'Operando', icon: 'mdi-check-circle', gradient: 'bg-gradient-green' },
  { label: 'Manutenção', value: maintenanceVehicles.value, footer: 'Parados', icon: 'mdi-wrench', gradient: 'bg-gradient-red' },
  { label: 'Inativos', value: vehicles.value.length - activeVehicles.value - maintenanceVehicles.value, footer: 'Desativados', icon: 'mdi-alert', gradient: 'bg-gradient-purple' },
]));

const handleKpiClick = (label: string) => {
    search.value = '';
    if (label === 'Ativos') search.value = 'ativo';
    if (label === 'Manutenção') search.value = 'manutencao';
    if (label === 'Inativos') search.value = 'inativo';
};

// Utils
const formatDate = (val: string) => { if (!val) return ''; const [y, m, d] = val.split('T')[0].split('-'); return `${d}/${m}/${y}`; };
const getCompanyName = (id: string) => { const c = companies.value.find(x => x.id === id); return c ? c.trade_name : ''; };

// Funções de Interface da Grid
const getStatusChipClass = (status: string) => {
  if (status === 'ativo') return 'chip-success';
  if (status === 'manutencao') return 'chip-danger';
  return 'chip-warn';
};
const getStatusDotClass = (status: string) => {
  if (status === 'ativo') return 'bg-success';
  if (status === 'manutencao') return 'bg-error pulse';
  return 'bg-grey';
};
const zebraClass = (i:number) => themeStore.currentMode!=='light' ? (i%2===0?'zebra-dark-a':'zebra-dark-b') : (i%2===0?'zebra-light-a':'zebra-light-b');
const getFileIcon = (url: string) => {
    if(!url) return 'mdi-file';
    if(url.toLowerCase().includes('.pdf')) return 'mdi-file-pdf-box';
    return 'mdi-image';
};

// API Fetch
const fetchCompanies = async () => {
    const { data } = await supabase.from('companies').select('id, trade_name');
    if (data) companies.value = data;
};

const fetchVehicles = async () => {
  loading.value = true;
  try {
      const { data, error } = await supabase.from('fleet_vehicles').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      vehicles.value = data || [];
  } catch (e:any) {
      appStore.showSnackbar('Erro ao carregar frota: ' + e.message, 'error');
  } finally {
      loading.value = false;
  }
};

// Modal Controls
const openNewVehicleModal = () => {
  editModal.form = JSON.parse(JSON.stringify(defaultItem));
  editModal.previewImage = null; editModal.fileToUpload = null;
  editModal.driverPreviewImage = null; editModal.driverFileToUpload = null;
  editModal.newDocsToUpload = [];
  editModal.activeTab = 0;
  editModal.show = true;
};

const openEditModal = (item: any) => {
  const parsedItem = JSON.parse(JSON.stringify(item));

  // Garantir conversão do antigo array de strings (se houver) para array de objetos no formato atual
  if (parsedItem.attachments && parsedItem.attachments.length > 0 && typeof parsedItem.attachments[0] === 'string') {
      parsedItem.attachments = parsedItem.attachments.map((url: string, i: number) => ({
          name: `Anexo Legado ${i+1}`, url: url, category: 'Outros', uploaded_at: new Date().toISOString()
      }));
  } else if (!parsedItem.attachments) {
      parsedItem.attachments = [];
  }

  editModal.form = parsedItem;
  editModal.previewImage = null; editModal.fileToUpload = null;
  editModal.driverPreviewImage = null; editModal.driverFileToUpload = null;
  editModal.newDocsToUpload = [];
  editModal.activeTab = 0;
  editModal.show = true;
};

// Upload Handlers
const handleMainPhotoUpload = (e: Event) => {
    const t = e.target as HTMLInputElement;
    if(t.files && t.files[0]) {
        editModal.fileToUpload = t.files[0];
        editModal.previewImage = URL.createObjectURL(t.files[0]);
    }
};

const handleDriverPhotoUpload = (e: Event) => {
    const t = e.target as HTMLInputElement;
    if(t.files && t.files[0]) {
        editModal.driverFileToUpload = t.files[0];
        editModal.driverPreviewImage = URL.createObjectURL(t.files[0]);
    }
};

const clearDriverPhoto = () => {
    editModal.form.driver_photo_url = null;
    editModal.driverFileToUpload = null;
    editModal.driverPreviewImage = null;
};

const uploadFileToBucket = async (file: File, folder: string): Promise<string|null> => {
    const fileName = `${folder}/${Date.now()}-${file.name.replace(/\s/g, '_')}`;
    const { data, error } = await supabase.storage.from('fleet-media').upload(fileName, file);
    if (data) {
        const { data: pData } = supabase.storage.from('fleet-media').getPublicUrl(fileName);
        return pData.publicUrl;
    }
    console.error("Erro upload:", error);
    return null;
};

// Tratamento de Fichário (Anexos)
const getDocsByCategory = (cat: string) => { return (editModal.form.attachments || []).filter((d: any) => d.category === cat); };

const executeDocUpload = async () => {
    if (!newDocFile.value) return appStore.showSnackbar('Selecione um arquivo.', 'warning');
    uploadingDoc.value = true;
    try {
        const file = Array.isArray(newDocFile.value) ? newDocFile.value[0] : newDocFile.value;
        const url = await uploadFileToBucket(file, 'docs');
        if (!url) throw new Error('Falha ao upar arquivo');

        if (!editModal.form.attachments) editModal.form.attachments = [];
        editModal.form.attachments.push({
            name: newDocCustomName.value || file.name,
            url: url,
            category: newDocCategory.value,
            uploaded_at: new Date().toISOString()
        });

        appStore.showSnackbar('Documento arquivado!', 'success');
        showDocModal.value = false; newDocFile.value = null; newDocCustomName.value = '';
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar documento', 'error');
    } finally {
        uploadingDoc.value = false;
    }
};

const removeSavedAttachment = (doc: any) => {
    if(confirm('Excluir este documento permanentemente?')) {
        const idx = editModal.form.attachments.findIndex((d: any) => d.url === doc.url);
        if(idx > -1) editModal.form.attachments.splice(idx, 1);
    }
};

// Salvar / Delete Principal
const saveVehicle = async () => {
    if(!editModal.form.plate || !editModal.form.brand || !editModal.form.model) {
        editModal.activeTab = 0;
        appStore.showSnackbar('Preencha Marca, Modelo e Placa (obrigatórios)', 'warning');
        return;
    }

    editModal.loading = true;
    try {
        let payload = { ...editModal.form };

        // Limpar mascaras
        if(payload.driver_cpf) payload.driver_cpf = payload.driver_cpf.replace(/\D/g, '');

        if (editModal.fileToUpload) {
            const url = await uploadFileToBucket(editModal.fileToUpload, 'vehicles');
            if(url) payload.photo_url = url;
        }

        if (editModal.driverFileToUpload) {
            const url = await uploadFileToBucket(editModal.driverFileToUpload, 'drivers');
            if(url) payload.driver_photo_url = url;
        }

        const { id, ...dataToSave } = payload;

        if (id) {
            await supabase.from('fleet_vehicles').update(dataToSave).eq('id', id);
            appStore.showSnackbar('Veículo atualizado!', 'success');
        } else {
            await supabase.from('fleet_vehicles').insert([dataToSave]);
            appStore.showSnackbar('Veículo cadastrado!', 'success');
        }

        editModal.show = false;
        fetchVehicles();

    } catch (e:any) {
        appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error');
    } finally {
        editModal.loading = false;
    }
};

const deleteVehicle = async (item: any) => {
  if (confirm(`Remover veículo ${item.plate}?`)) {
      try {
          await supabase.from('fleet_vehicles').delete().eq('id', item.id);
          fetchVehicles();
          appStore.showSnackbar('Veículo removido.', 'success');
      } catch(e:any) {
          appStore.showSnackbar('Erro ao remover: ' + e.message, 'error');
      }
  }
};

onMounted(() => {
    fetchCompanies();
    fetchVehicles();
});
</script>

<style scoped lang="scss">
/* Layout e Fundo Idêntico ao Receivables */
.fleet-layout { position: relative; }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; opacity: 1; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.95)); backdrop-filter: blur(8px); }

.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; padding: 0 12px; border: 1px solid rgba(0,0,0,0.08); display: flex; align-items: center; min-width: 300px; flex: 1; }
.clean-input { border: none; outline: none; flex: 1; font-size: 12px; }

/* Grid e Scroll */
.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

/* Grid Layout Fluido */
.grid-header, .grid-row {
    display: grid;
    align-items: stretch;
    width: 100%;
}
.grid-fleet { grid-template-columns: 45px 60px 100px minmax(180px, 2.5fr) minmax(180px, 2fr) minmax(120px, 1.5fr) minmax(100px, 1fr) 100px; }

.cell {
    padding: 6px 8px;
    display: flex;
    align-items: center;
    border-right: 1px solid rgba(0,0,0,0.08);
    border-bottom: 1px solid rgba(0,0,0,0.08);
    min-height: 54px;
    overflow: hidden;
    transition: background-color 0.2s ease;
}

.header-text { font-size: 14px !important; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; }
.center { justify-content: center; text-align: center; }

.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 14px !important; line-height: 1.2 !important; }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-surface-dark .cell { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.95); border-color: rgba(255,255,255,0.1) !important; }

.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.grid-row-dark .cell { border-color: rgba(255,255,255,0.08) !important; }

.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.zebra-dark-a .cell { background: rgba(0,0,0,0.15); }
.zebra-dark-b .cell { background: rgba(255,255,255,0.03); }
.grid-row-light:hover .cell { background: #e3f2fd !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.12) !important; }

/* KPIs idênticas */
.kpi-card { color: white; position: relative; min-height: 110px; overflow: hidden; }
.kpi-bg-icon { position: absolute; right: -20px; bottom: -20px; opacity: 0.15; transform: rotate(-15deg); }
.kpi-bg-icon .v-icon { font-size: 100px; color: white; }
.kpi-bg-icon-mobile { position: absolute; right: -5px; bottom: -5px; opacity: 0.15; transform: rotate(-10deg); }
.kpi-bg-icon-mobile .v-icon { font-size: 60px; color: white; }

.bg-gradient-info { background: linear-gradient(135deg, #0288d1, #005b9f); }
.bg-gradient-green { background: linear-gradient(135deg, #2e7d32, #1b5e20); }
.bg-gradient-red { background: linear-gradient(135deg, #c62828, #8e0000); }
.bg-gradient-purple { background: linear-gradient(135deg, #7b1fa2, #4a148c); }

.kpi-label { font-size: 12px; font-weight: 900; letter-spacing: .2px; }
.kpi-value { font-size: 22px; font-weight: 900; }
.kpi-footer { font-size: 11px; opacity: .9; font-weight: 700; }

/* Chips & Buttons 3D */
.pill-ref { font-size: 12px !important; font-weight: 900; font-family: monospace; padding: 4px 6px; border-radius: 0px; white-space: nowrap; }
.solid-chip { display: inline-flex; align-items: center; justify-content: center; height: 28px; padding: 0 12px; font-size: 11px !important; font-weight: 900; color: #fff; text-transform: uppercase; white-space: nowrap; }
.chip-success { background: #2e7d32; }
.chip-warn { background: #f57f17; }
.chip-danger { background: #c62828; }

.actions-inline { display: flex; gap: 4px; justify-content: center; flex-wrap: nowrap !important; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}
.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.row-gap { row-gap: 14px; margin-top: 4px; }

/* Status Dot Pulse */
.status-indicator { width: 10px; height: 10px; border-radius: 50%; }
.pulse { animation: pulse-red 2s infinite; }
@keyframes pulse-red { 0% { box-shadow: 0 0 0 0 rgba(198, 40, 40, 0.7); } 70% { box-shadow: 0 0 0 8px rgba(198, 40, 40, 0); } 100% { box-shadow: 0 0 0 0 rgba(198, 40, 40, 0); } }

/* CONTORNO EXTERNO DA GRID E FIX STICKY */
.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }
.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }

/* =======================================================
   ESTILO CORPORATIVO ADMIN/EMPLOYEE MODAL
   ======================================================= */
.fixed-dialog { overflow: hidden !important; }
.btn-rect { border-radius: 2px !important; text-transform: none !important; letter-spacing: 0.5px; }
.ui-field :deep(.v-field) { border-radius: 2px !important; font-size: 13px; background: #fff;}
.input-label { display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #757575; margin-bottom: 6px; letter-spacing: 0.5px; }
.tracking-widest { letter-spacing: 0.05em; }

.border-white-20 { border: 1px solid rgba(255,255,255,0.2) !important; }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.bg-black-70 { background-color: rgba(0,0,0,0.7); }
.shadow-md { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); }
.shadow-sm { box-shadow: 0 1px 2px rgba(0,0,0,0.05) !important; }
.hover-row:hover { background-color: #f8f9fa !important; }

/* Tabs laterais */
.tab-item { border-bottom: 1px solid rgba(255,255,255,0.05); min-height: 52px; font-size: 13px; }
.tab-item.v-tab--selected { background: rgba(255,255,255,0.1); border-right: 3px solid #fff; }

/* Upload overlays */
.hover-brightness:hover { filter: brightness(0.85); }
.overlay-edit { position: absolute; top:0; left:0; width:100%; height:100%; background: rgba(0,0,0,0.4); opacity: 0; transition: opacity 0.2s; }
.hover-brightness:hover .overlay-edit { opacity: 1; }

/* Expansion Panels (Fichário) */
.custom-expansion :deep(.v-expansion-panel-title) { min-height: 50px; padding: 12px 20px; font-size: 13px; }
</style>
