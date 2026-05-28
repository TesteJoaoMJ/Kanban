<template>
  <div class="view-wrap profile-view">
    <div v-if="isLoading" class="loading-state mj-surface mj-border">
      <v-progress-circular indeterminate color="primary" size="48" width="4" />
      <p>Carregando seu painel...</p>
    </div>

    <v-container v-else class="container-xl profile-container">
      <div class="profile-breadcrumb">
        <v-btn icon variant="tonal" size="small" class="back-btn" @click="router.back()">
          <v-icon>mdi-arrow-left</v-icon>
        </v-btn>
        <span>Minha Conta / <strong class="text-primary">{{ currentTabName }}</strong></span>
      </div>

      <div class="profile-layout">
        <aside class="profile-sidebar mj-surface mj-border">
          <div class="user-card">
            <div class="avatar-wrapper" @click="triggerAvatarUpload" :class="{ 'is-uploading': isUploadingAvatar }">
              <div v-if="isUploadingAvatar" class="avatar-loading-overlay">
                <v-progress-circular indeterminate color="white" size="24" width="3" />
              </div>
              <img v-else-if="userProfile.avatar_url" :src="userProfile.avatar_url" alt="Avatar" class="user-avatar" />
              <div v-else class="avatar-placeholder">
                <v-icon size="36">mdi-account</v-icon>
              </div>
              <div class="avatar-overlay">
                <v-icon color="white" size="20">mdi-camera</v-icon>
              </div>
            </div>
            <input type="file" ref="fileInput" accept="image/*" class="d-none" @change="handleAvatarUpload" />

            <h2 class="user-name d-flex align-center justify-center gap-1">
              {{ userProfile.name || 'Visitante' }}
              <v-icon v-if="hasDesignAccess" color="warning" size="22" class="vip-glow ml-1" title="Cliente VIP">mdi-crown</v-icon>
            </h2>
            <p class="user-email">{{ authEmail }}</p>
          </div>

          <nav class="profile-nav scrollable-nav">
            <button class="nav-item" :class="{ active: activeTab === 'dados' }" @click="activeTab = 'dados'">
              <v-icon size="20" class="nav-icon">mdi-card-account-details-outline</v-icon>
              Meus Dados
            </button>
            <button class="nav-item" :class="{ active: activeTab === 'pedidos' }" @click="activeTab = 'pedidos'">
              <v-icon size="20" class="nav-icon">mdi-package-variant-closed</v-icon>
              Meus Pedidos
            </button>

            <button class="nav-item" :class="{ active: activeTab === 'pilotos' }" @click="activeTab = 'pilotos'">
              <v-icon size="20" class="nav-icon">mdi-flask-outline</v-icon>
              Meus Pilotos
              <span v-if="pilots.length" class="nav-badge bg-primary text-white">{{ pilots.length }}</span>
            </button>

            <button class="nav-item" :class="{ active: activeTab === 'transacoes' }" @click="activeTab = 'transacoes'">
              <v-icon size="20" class="nav-icon">mdi-receipt-text-check-outline</v-icon>
              Transações e Recibos
            </button>

            <button class="nav-item vip-nav-btn" :class="{ active: activeTab === 'estudio' }" @click="activeTab = 'estudio'">
              <v-icon size="20" class="nav-icon" :color="activeTab === 'estudio' || hasDesignAccess ? 'warning' : 'grey'">mdi-crown</v-icon>
              <span :class="{'vip-text-gradient': activeTab === 'estudio' || hasDesignAccess}">Desenvolvimento Premium</span>
              <span v-if="userProfile.design_access_status === 'pending' && requireVipDesign" class="nav-badge" style="background: #f59e0b; color: #000;">Análise</span>
            </button>

            <button v-if="allowPsdSales" class="nav-item" :class="{ active: activeTab === 'biblioteca' }" @click="activeTab = 'biblioteca'">
              <v-icon size="20" class="nav-icon">mdi-folder-download-outline</v-icon>
              Minha Biblioteca (PSD)
            </button>

            <button class="nav-item" :class="{ active: activeTab === 'carrinho' }" @click="activeTab = 'carrinho'">
              <v-icon size="20" class="nav-icon">mdi-palette-swatch-outline</v-icon>
              Itens no Carrinho
              <span v-if="cartContext?.moodboard.value.length" class="nav-badge">{{ cartContext.moodboard.value.length }}</span>
            </button>
            <button class="nav-item" :class="{ active: activeTab === 'seguranca' }" @click="activeTab = 'seguranca'">
              <v-icon size="20" class="nav-icon">mdi-shield-lock-outline</v-icon>
              Segurança
            </button>
          </nav>

          <div class="sidebar-footer">
            <v-btn variant="text" color="error" block class="logout-btn" @click="logout">
              <v-icon start>mdi-logout-variant</v-icon>
              Encerrar Sessão
            </v-btn>
          </div>
        </aside>

        <main class="profile-content">
          <transition name="fade" mode="out-in">

            <div v-if="activeTab === 'dados'" key="dados" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Informações Pessoais</h3>
                <p class="panel-desc">Atualize seus dados de faturamento e contato para agilizar futuros orçamentos e compras.</p>
              </div>

              <v-form @submit.prevent="saveProfile" class="profile-form">
                <div class="form-grid">
                  <div class="form-group">
                    <label>Nome Completo / Razão Social</label>
                    <input v-model="profileForm.name" type="text" class="mj-input mj-surface-2 mj-border" required placeholder="Como deseja ser chamado" />
                  </div>
                  <div class="form-group">
                    <label>CPF / CNPJ</label>
                    <input v-model="profileForm.document" type="text" class="mj-input mj-surface-2 mj-border" required placeholder="000.000.000-00" />
                  </div>
                  <div class="form-group">
                    <label>Telefone / WhatsApp</label>
                    <input v-model="profileForm.phone" type="text" class="mj-input mj-surface-2 mj-border" placeholder="(00) 00000-0000" />
                  </div>
                  <div class="form-group">
                    <label>Localização (Cidade/Estado)</label>
                    <input v-model="profileForm.location" type="text" class="mj-input mj-surface-2 mj-border" placeholder="Ex: São Paulo, SP" />
                  </div>
                </div>

                <div class="form-actions">
                  <v-btn type="submit" color="primary" size="large" :loading="savingProfile" class="action-btn">
                    Salvar Alterações
                  </v-btn>
                </div>
              </v-form>
            </div>

            <div v-else-if="activeTab === 'estudio'" key="estudio" class="tab-panel mj-surface mj-border">

              <div class="panel-header d-flex justify-space-between align-start">
                <div>
                  <h3 class="panel-title d-flex align-center gap-2">
                    Estúdio de Design <v-icon color="warning" size="28" class="vip-glow">mdi-crown</v-icon>
                  </h3>
                  <p class="panel-desc">Solicite artes exclusivas e desenvolvimentos sob medida diretamente para nossa equipe criativa.</p>
                </div>
                <v-chip v-if="hasDesignAccess" color="warning" variant="flat" size="small" class="font-weight-bold px-3 text-black">
                  {{ requireVipDesign ? 'ACESSO VIP ATIVO' : 'ESTÚDIO ABERTO' }}
                </v-chip>
              </div>

              <div v-if="!hasDesignAccess && (!userProfile.design_access_status || userProfile.design_access_status === 'none')" class="empty-state vip-locked-state rounded-xl">
                <div class="vip-icon-wrap mb-6">
                  <v-icon size="64" color="warning" class="vip-glow">mdi-crown-outline</v-icon>
                </div>
                <h4 class="vip-text-gradient text-h5 mb-2">Acesso Premium</h4>
                <p class="text-muted max-w-md mx-auto mb-8" style="line-height: 1.6;">
                  O Desenvolvimento Premium é uma ferramenta dedicada aos nossos clientes frequentes e parceiros selecionados. Solicite um convite para criar um canal direto e prioritário com nossos designers.
                </p>
                <v-btn color="warning" size="x-large" class="action-btn text-black font-weight-black shadow-gold" :loading="requestingAccess" @click="requestDesignAccess">
                  <v-icon start>mdi-star</v-icon> Solicitar Convite VIP
                </v-btn>
              </div>

              <div v-else-if="!hasDesignAccess && userProfile.design_access_status === 'pending'" class="empty-state">
                <div class="empty-icon-wrap mj-surface-2" style="border: 1px solid rgba(245, 158, 11, 0.3);">
                  <v-icon size="42" color="warning">mdi-clock-outline</v-icon>
                </div>
                <h4>Convite em Análise</h4>
                <p>Nossa diretoria está avaliando seu perfil. Em breve o recurso será liberado na sua conta!</p>
                <v-btn variant="outlined" color="warning" class="mt-4 action-btn" @click="openWhatsAppSuporte">Falar com Consultor</v-btn>
              </div>

              <div v-else-if="hasDesignAccess">

                <div class="mj-surface-2 mj-border pa-6 rounded-xl mb-8" style="border-color: rgba(245, 158, 11, 0.2) !important;">
                  <h4 class="font-weight-bold mb-4 vip-text-gradient">Nova Solicitação Criativa</h4>

                  <v-form @submit.prevent="submitDesignToKanban" class="profile-form">
                    <div class="form-group mb-4">
                      <label>Briefing e Instruções</label>
                      <textarea
                        v-model="designForm.notes"
                        class="mj-input mj-surface mj-border"
                        rows="4"
                        style="height: auto; padding: 16px; resize: vertical;"
                        placeholder="Descreva cores, estilo, elementos desejados ou detalhes de alteração..."
                        required
                      ></textarea>
                    </div>

                    <div class="form-group mb-6">
                      <label>Referências Visuais</label>
                      <div
                        class="mj-surface mj-border d-flex flex-column align-center justify-center pa-6 rounded-xl cursor-pointer"
                        style="border-style: dashed !important; transition: all 0.2s;"
                        @click="triggerClientUpload"
                      >
                        <v-icon size="32" color="warning" class="mb-2">mdi-cloud-upload-outline</v-icon>
                        <strong class="text-main">Clique para anexar imagens (Opcional)</strong>
                        <span class="text-muted text-caption mt-1">JPG, PNG ou PDF</span>
                        <input type="file" ref="clientFileInput" multiple accept="image/*,.pdf" class="d-none" @change="handleClientFiles" />
                      </div>

                      <div v-if="designForm.files.length" class="d-flex flex-wrap gap-3 mt-4">
                        <div v-for="(file, index) in designForm.previews" :key="index" class="position-relative">
                          <img :src="file.url" class="mj-border rounded-lg" style="width: 80px; height: 80px; object-fit: cover;" />
                          <v-btn icon="mdi-close" size="x-small" color="error" class="position-absolute" style="top: -8px; right: -8px;" @click="removeClientFile(index)"></v-btn>
                        </div>
                      </div>
                    </div>

                    <div class="d-flex justify-end">
                      <v-btn type="submit" color="warning" size="large" :loading="sendingDesign" class="action-btn px-8 text-black font-weight-black shadow-gold">
                        <v-icon start>mdi-send-check</v-icon> Enviar para o Estúdio
                      </v-btn>
                    </div>
                  </v-form>
                </div>

                <div class="d-flex align-center justify-space-between mb-6">
                   <h4 class="font-weight-bold m-0">Cofre de Entregas do Designer</h4>
                   <span class="text-caption text-error font-weight-bold"><v-icon size="14" color="error" class="mr-1">mdi-fire</v-icon>Autodestrutivas (24h)</span>
                </div>

                <div class="vip-vault-grid">
                  <div
                    v-for="arte in activeDeliveries"
                    :key="arte.id"
                    class="art-3d-wrapper"
                    :class="{ 'destructing': destructingIds.includes(arte.id) }"
                  >
                    <div class="art-3d-card" @click="openArtModal(arte)">
                      <div class="position-absolute top-0 left-0 w-100 pa-3 d-flex justify-space-between align-start" style="z-index: 10; pointer-events: none;">
                         <v-chip size="x-small" color="warning" variant="flat" class="font-weight-black shadow-gold text-black">
                           <v-icon start size="12">mdi-crown</v-icon> {{ arte.design_request_id }}
                         </v-chip>
                         <v-chip size="x-small" color="error" variant="flat" class="font-weight-bold shadow-sm" style="background: rgba(239, 68, 68, 0.9) !important; color: white !important;">
                           <v-icon start size="12">mdi-timer-sand</v-icon> {{ getHoursLeft(arte.expires_at) }}
                         </v-chip>
                      </div>

                      <div class="art-media-container w-100 h-100">
                        <img :src="arte.file_url" class="art-img-filter w-100 h-100" style="object-fit: cover;" />
                      </div>

                      <div class="art-overlay d-flex align-center justify-center flex-column gap-2">
                         <v-btn color="warning" variant="flat" size="small" class="font-weight-black text-black shadow-gold rounded-lg text-none" style="pointer-events: none;">
                           <v-icon start>mdi-eye</v-icon> Visualizar Obra
                         </v-btn>
                         <span class="text-[10px] text-white font-weight-bold opacity-80 mt-2" style="letter-spacing: 1px;">Clique para abrir seguro</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div v-if="activeDeliveries.length === 0" class="empty-state py-8 mj-surface-2 rounded-xl" style="border: 1px dashed var(--border-color);">
                  <v-icon size="32" color="grey" class="mb-3">mdi-safe-square-outline</v-icon>
                  <p class="m-0 text-muted">Cofre Vazio. Suas artes aparecerão aqui em 3D.</p>
                </div>
              </div>
            </div>

            <div v-else-if="activeTab === 'seguranca'" key="seguranca" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Segurança da Conta</h3>
                <p class="panel-desc">Gerencie seu e-mail de acesso e credenciais da plataforma.</p>
              </div>

              <div class="security-section">
                <h4>Alterar Senha</h4>
                <v-form @submit.prevent="updatePassword" class="profile-form mt-4">
                  <div class="form-grid">
                    <div class="form-group">
                      <label>Nova Senha</label>
                      <input v-model="securityForm.newPassword" type="password" class="mj-input mj-surface-2 mj-border" required minlength="6" placeholder="Mínimo 6 caracteres" />
                    </div>
                    <div class="form-group">
                      <label>Confirmar Nova Senha</label>
                      <input v-model="securityForm.confirmPassword" type="password" class="mj-input mj-surface-2 mj-border" required minlength="6" placeholder="Repita a senha" />
                    </div>
                  </div>
                  <div class="form-actions mt-6">
                    <v-btn type="submit" color="primary" variant="tonal" size="large" :loading="savingSecurity" class="action-btn">
                      <v-icon start>mdi-lock-reset</v-icon>
                      Atualizar Senha
                    </v-btn>
                  </div>
                </v-form>
              </div>
            </div>

            <div v-else-if="activeTab === 'pedidos'" key="pedidos" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Histórico de Orçamentos</h3>
                <p class="panel-desc">Acompanhe as solicitações de produção em larga escala enviadas para a equipe.</p>
              </div>

              <div v-if="orders.length" class="timeline-container">
                <article v-for="order in orders" :key="order.id" class="order-card mj-surface-2 mj-border">
                  <div class="order-header">
                    <div class="order-meta">
                      <span class="order-id">PEDIDO #{{ order.id.split('-')[0].toUpperCase() }}</span>
                      <span class="order-date">Enviado em {{ formatDate(order.created_at) }}</span>
                    </div>
                    <div class="order-status-badge" :class="order.status">
                      <span class="status-dot"></span>
                      {{ translateStatus(order.status) }}
                    </div>
                  </div>

                  <div class="order-items">
                    <div v-for="(item, idx) in order.items" :key="idx" class="order-item">
                      <img :src="item.image_url || '/placeholder.png'" alt="Estampa" class="item-thumb mj-border" />
                      <div class="item-info">
                        <strong>{{ item.title }}</strong>
                        <span class="item-specs">Base: {{ item.fabric_name }}</span>
                        <span class="item-specs">Metragem: {{ item.quantity }} metros</span>
                      </div>
                      <div class="item-price text-right">
                        <div class="font-weight-bold">R$ {{ formatPrice(item.total_price) }}</div>
                        <div class="text-caption text-muted">R$ {{ formatPrice(item.total_price / item.quantity) }}/m</div>
                      </div>
                    </div>
                  </div>

                  <div class="order-footer">
                    <span class="total-label">Estimativa Total do Orçamento</span>
                    <span class="total-value text-primary">R$ {{ formatPrice(order.total_amount) }}</span>
                  </div>
                </article>
              </div>

              <div v-else class="empty-state">
                <div class="empty-icon-wrap mj-surface-2 mj-border"><v-icon size="42" color="primary">mdi-package-variant</v-icon></div>
                <h4>Nenhum orçamento enviado</h4>
                <p>Você ainda não enviou nenhum pedido de estamparia para nossa equipe avaliar.</p>
                <v-btn color="primary" class="mt-2 action-btn" @click="router.push('/marketplace/descobrir')">Explorar Catálogo</v-btn>
              </div>
            </div>

            <div v-else-if="activeTab === 'pilotos'" key="pilotos" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Meus Pilotos</h3>
                <p class="panel-desc">Acompanhe as suas solicitações de testes físicos e amostras.</p>
              </div>

              <div v-if="pilots.length" class="timeline-container">
                <article v-for="pilot in pilots" :key="pilot.id" class="order-card mj-surface-2 mj-border">

                  <div class="order-header">
                    <div class="order-meta">
                      <span class="order-id">PILOTO #{{ pilot.id.split('-')[0].toUpperCase() }}</span>
                      <span class="order-date">Solicitado em {{ formatDate(pilot.created_at) }}</span>
                    </div>
                    <div class="order-status-badge" :class="pilot.status">
                      <span class="status-dot"></span>
                      {{ translatePilotStatus(pilot.status) }}
                    </div>
                  </div>

                  <div class="order-items">
                    <div class="order-item pilot-item">
                      <img :src="pilot.stamp?.main_image_url || '/placeholder.png'" class="item-thumb mj-border" />

                      <div class="item-info">
                        <div class="d-flex align-center gap-2 mb-1 flex-wrap">
                          <strong class="text-h6" style="line-height: 1;">{{ pilot.stamp?.title || 'Estampa Desconhecida' }}</strong>
                          <v-chip v-if="pilot.representative_request" size="x-small" color="primary" variant="flat" class="font-weight-bold px-2 text-uppercase letter-spacing-1">Via WhatsApp</v-chip>
                        </div>
                        <span class="item-specs font-weight-bold mb-2 d-block text-primary">Ref: {{ pilot.stamp?.ref_code || '--' }}</span>

                        <div class="d-flex flex-column gap-1 mt-2">
                           <span class="item-specs d-flex align-center"><v-icon size="16" class="mr-2 opacity-70">mdi-texture</v-icon> <span class="opacity-80">Base:</span> &nbsp;<strong>{{ pilot.fabric?.name || '--' }}</strong></span>
                           <span class="item-specs d-flex align-center"><v-icon size="16" class="mr-2 opacity-70">mdi-tape-measure</v-icon> <span class="opacity-80">Quantidade:</span> &nbsp;<strong>{{ pilot.quantity_meters }} metro(s)</strong></span>
                        </div>
                      </div>

                      <div class="item-price d-flex flex-column align-end justify-center mobile-price-left">
                        <div class="font-weight-black text-h5 text-high-emphasis">R$ {{ formatPrice(pilot.amount) }}</div>
                        <div class="text-caption text-muted mb-2">Custo de produção</div>

                        <v-btn
                          v-if="pilot.status === 'pending_payment' && !pilot.representative_request"
                          color="success"
                          class="font-weight-black rounded-lg mt-2 action-btn"
                          @click="resumePilotPix(pilot)"
                        >
                          <v-icon start>mdi-qrcode-scan</v-icon> Pagar PIX Agora
                        </v-btn>

                        <div v-else-if="pilot.status === 'pending_payment' && pilot.representative_request" class="text-caption text-warning mt-2 font-weight-bold d-flex align-start flex-column align-md-center flex-md-row bg-warning-lighten-5 pa-2 rounded-lg border-warning-lighten-4 border" style="max-width: 200px; text-align: left; line-height: 1.3;">
                           <v-icon size="16" class="mr-2 flex-shrink-0">mdi-clock-outline</v-icon> Aguarde o link de pagamento do vendedor
                        </div>
                      </div>
                    </div>
                  </div>

                </article>
              </div>

              <div v-else class="empty-state">
                <div class="empty-icon-wrap mj-surface-2 mj-border"><v-icon size="42" color="primary">mdi-flask-empty-outline</v-icon></div>
                <h4>Nenhum piloto solicitado</h4>
                <p>Navegue pelo acervo e solicite um piloto em qualquer estampa para receber um teste físico da produção.</p>
                <v-btn color="primary" class="mt-2 action-btn" @click="router.push('/marketplace/descobrir')">Ir para Acervo</v-btn>
              </div>
            </div>

            <div v-else-if="activeTab === 'transacoes'" key="transacoes" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Transações e Recibos</h3>
                <p class="panel-desc">Histórico completo de pagamentos aprovados em sua conta.</p>
              </div>

              <div v-if="transactions.length" class="table-responsive">
                <table class="mj-table w-100">
                  <thead>
                    <tr>
                      <th class="text-left text-caption font-weight-bold text-muted">Data</th>
                      <th class="text-left text-caption font-weight-bold text-muted">Descrição</th>
                      <th class="text-left text-caption font-weight-bold text-muted">Método</th>
                      <th class="text-right text-caption font-weight-bold text-muted">Valor</th>
                      <th class="text-center text-caption font-weight-bold text-muted">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="tx in transactions" :key="tx.id" class="border-b">
                      <td class="py-4 text-body-2">{{ formatDate(tx.created_at) }}</td>
                      <td class="py-4">
                        <div class="font-weight-bold">{{ tx.description || 'Transação' }}</div>
                        <div class="text-caption text-muted text-uppercase">{{ tx.transaction_type }}</div>
                      </td>
                      <td class="py-4 text-body-2">{{ tx.payment_method }}</td>
                      <td class="py-4 text-right font-weight-bold text-primary">R$ {{ formatPrice(tx.amount) }}</td>
                      <td class="py-4 text-center">
                        <v-chip size="small" color="success" variant="flat" class="font-weight-bold">Pago</v-chip>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div v-else class="empty-state">
                <div class="empty-icon-wrap mj-surface-2 mj-border"><v-icon size="42" color="primary">mdi-receipt-text-outline</v-icon></div>
                <h4>Nenhuma transação registrada</h4>
                <p>O histórico de pagamentos aprovados aparecerá aqui.</p>
              </div>
            </div>

            <div v-else-if="activeTab === 'biblioteca' && allowPsdSales" key="biblioteca" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <div class="d-flex justify-space-between align-start">
                  <div>
                    <h3 class="panel-title">Minha Biblioteca</h3>
                    <p class="panel-desc">Estampas em PSD adquiridas. Uso liberado para produção sem royalties.</p>
                  </div>
                  <v-chip color="success" variant="tonal" size="small" class="font-weight-bold px-3">
                    <v-icon start size="14">mdi-shield-check</v-icon>
                    Acesso Vitalício
                  </v-chip>
                </div>
              </div>

              <div v-if="libraryItems.length" class="library-grid">
                <article v-for="item in libraryItems" :key="item.id" class="library-card mj-surface-2 mj-border">
                  <div class="library-image-wrap">
                    <img :src="item.stamp.main_image_url || '/placeholder.png'" alt="Estampa" class="library-image" />
                    <div class="resolution-badge">300 DPI</div>
                  </div>
                  <div class="library-info">
                    <div class="lib-ref">{{ item.stamp.ref_code }}</div>
                    <h4 class="lib-title">{{ item.stamp.title }}</h4>
                    <p class="lib-date">Adquirido em {{ formatDate(item.created_at) }}</p>

                    <v-btn
                      color="success"
                      block
                      class="mt-4 download-btn"
                      elevation="0"
                      :loading="downloadingId === item.id"
                      @click="downloadDigitalFile(item.id)"
                    >
                      <v-icon start>mdi-cloud-download-outline</v-icon>
                      Baixar Arquivo PSD
                    </v-btn>
                  </div>
                </article>
              </div>

              <div v-else class="empty-state">
                <div class="empty-icon-wrap mj-surface-2 mj-border"><v-icon size="42" color="primary">mdi-folder-open-outline</v-icon></div>
                <h4>Sua biblioteca está vazia</h4>
                <p>Compre estampas digitais de alta resolução para baixar instantaneamente e usar na sua produção.</p>
                <v-btn color="primary" class="mt-2 action-btn" @click="router.push('/marketplace/descobrir')">Comprar Arquivos PSD</v-btn>
              </div>
            </div>

            <div v-else-if="activeTab === 'carrinho'" key="carrinho" class="tab-panel mj-surface mj-border">
              <div class="panel-header">
                <h3 class="panel-title">Seleção Atual</h3>
                <p class="panel-desc">Gerencie os items que você separou para orçar ou comprar.</p>
              </div>

              <div v-if="cartContext?.moodboard.value.length" class="cart-list">
                <article v-for="(item, index) in cartContext.moodboard.value" :key="index" class="cart-item mj-surface-2 mj-border">
                  <img :src="item.stamp.main_image_url || '/placeholder.png'" alt="Estampa" class="cart-image mj-border" />
                  <div class="cart-info">
                    <div class="d-flex align-center gap-2 mb-1">
                      <span class="cart-ref">{{ item.stamp.ref_code }}</span>
                      <span v-if="item.stamp.is_physical" class="badge-physical">Físico</span>
                      <span v-else class="badge-digital">Digital</span>
                    </div>
                    <h4 class="cart-title">{{ item.stamp.title }}</h4>
                    <p class="cart-specs" v-if="item.stamp.is_physical">
                      {{ item.stamp.fabric_name || 'Apenas estampa' }} — <strong>{{ item.quantity }}m</strong>
                    </p>
                    <p class="cart-specs text-success" v-else>Arquivo PSD Alta Resolução</p>
                  </div>
                  <v-btn icon="mdi-delete-outline" color="error" variant="text" class="remove-cart-btn" @click="cartContext.removeFromCarrinho(index)" />
                </article>

                <div class="cart-actions mt-8">
                  <v-btn color="primary" size="x-large" block class="action-btn" @click="cartContext.moodboardOpen.value = true">
                    <v-icon start>mdi-cart-check</v-icon>
                    Prosseguir para Checkout / Envio
                  </v-btn>
                </div>
              </div>

              <div v-else class="empty-state">
                <div class="empty-icon-wrap mj-surface-2 mj-border"><v-icon size="42" color="primary">mdi-cart-remove</v-icon></div>
                <h4>Seu carrinho está vazio</h4>
                <p>Nenhum item selecionado no momento. Adicione estampas físicas ou digitais para prosseguir.</p>
              </div>
            </div>

          </transition>
        </main>
      </div>

      <section class="favorites-section mt-16 pt-10 border-t" style="border-color: rgba(var(--v-border-color), 0.08) !important;">
        <div class="text-center mb-10">
          <h2 class="text-h4 font-weight-black text-high-emphasis mb-2" style="letter-spacing: -0.02em;">Meus Favoritos</h2>
          <p class="text-body-1 text-medium-emphasis">Suas inspirações e estampas salvas para o próximo projeto.</p>
        </div>

        <div class="d-flex flex-column flex-md-row align-center justify-space-between gap-4 mb-8">
          <div class="d-flex gap-2 overflow-x-auto custom-scrollbar pb-2 w-100" style="flex: 1;">
            <v-chip
              :color="favoriteCategory === null ? 'primary' : 'default'"
              :variant="favoriteCategory === null ? 'flat' : 'tonal'"
              class="font-weight-bold cursor-pointer"
              @click="favoriteCategory = null"
            >
              Todas
            </v-chip>
            <v-chip
              v-for="cat in categories"
              :key="cat.id"
              :color="favoriteCategory === cat.id ? 'primary' : 'default'"
              :variant="favoriteCategory === cat.id ? 'flat' : 'tonal'"
              class="font-weight-bold cursor-pointer"
              @click="favoriteCategory = cat.id"
            >
              {{ cat.name }}
            </v-chip>
          </div>

          <div class="bg-surface-2 border d-flex align-center px-4 rounded-pill" style="height: 48px; min-width: 280px;">
            <v-icon size="20" class="text-medium-emphasis mr-2">mdi-magnify</v-icon>
            <input v-model="favoriteSearch" type="text" placeholder="Buscar nos favoritos..." class="w-100 outline-none text-body-1 text-high-emphasis bg-transparent" />
          </div>
        </div>

        <div v-if="filteredFavorites.length > 0" class="pinterest-grid">
          <div v-for="stamp in filteredFavorites" :key="stamp.id" class="pinterest-item mj-surface mj-border position-relative">
            <div class="stamp-media-wrap cursor-pointer" @click="router.push(`/marketplace/produto/${stamp.id}`)">
              <img :src="getOptimizedUrl(stamp.main_image_url, 600)" @error="handleImageError" loading="lazy" class="w-100 h-100 object-cover" style="border-radius: 12px 12px 0 0; display: block;" />
            </div>

            <v-btn
              icon="mdi-heart"
              color="error"
              size="small"
              variant="flat"
              class="position-absolute shadow-soft"
              style="top: 12px; right: 12px; z-index: 10;"
              @click.stop="removeFavorite(stamp.id)"
              title="Remover dos favoritos"
            ></v-btn>

            <div class="pa-4 cursor-pointer" @click="router.push(`/marketplace/produto/${stamp.id}`)">
               <div class="d-flex justify-space-between align-center mb-1">
                 <span class="text-caption font-weight-bold text-medium-emphasis text-uppercase letter-spacing-1">{{ stamp.ref_code }}</span>
                 <span class="text-caption font-weight-bold" :class="stamp.stamp_type === 'Barrado' ? 'text-warning' : 'text-primary'">{{ stamp.stamp_type || 'Corrida' }}</span>
               </div>
               <h4 class="text-body-1 font-weight-black text-high-emphasis m-0" style="line-height: 1.2;">{{ stamp.title }}</h4>
            </div>
          </div>
        </div>

        <div v-else class="text-center py-16 mj-surface-2 rounded-xl border border-dashed">
          <v-icon size="64" class="text-disabled mb-4">mdi-heart-broken-outline</v-icon>
          <h3 class="text-h5 font-weight-bold text-high-emphasis mb-2">Nenhum favorito encontrado</h3>
          <p class="text-medium-emphasis mb-6">Explore o acervo e salve suas estampas preferidas clicando no coração.</p>
          <v-btn color="primary" size="large" class="rounded-lg font-weight-bold" @click="router.push('/marketplace/descobrir')">
            Descobrir Estampas
          </v-btn>
        </div>
      </section>

    </v-container>

    <ImageModal
      :show="showImageModal"
      :image-url="selectedImageSrc"
      :file-name="selectedImageTitle"
      @close="closeArtModal"
    />

    <v-dialog v-model="showPixModal" max-width="480" persistent>
      <v-card class="rounded-xl pa-8 text-center border shadow-lg mj-surface">
        <template v-if="!pilotApproved">
          <div class="d-flex align-center justify-center mb-4">
             <v-icon size="40" color="success" class="mr-2">mdi-qrcode-scan</v-icon>
             <h3 class="text-h5 font-weight-black">Pagamento Pendente</h3>
          </div>
          <p class="text-body-2 text-medium-emphasis mb-6">Continue seu pagamento via Pix para finalizar a solicitação do piloto.</p>

          <div class="pa-4 bg-white rounded-xl mx-auto border" style="width: fit-content;" v-if="pixData.copyPaste">
            <qrcode-vue
              :value="pixData.copyPaste"
              :size="220"
              level="M"
              render-as="svg"
            />
          </div>

          <v-text-field
             class="mt-6 mb-2"
             :model-value="pixData.copyPaste"
             readonly
             append-inner-icon="mdi-content-copy"
             @click:append-inner="copyPixText"
             variant="outlined"
             density="comfortable"
             hide-details
             bg-color="surface-2"
             label="Pix Copia e Cola"
          ></v-text-field>

          <div class="d-flex align-center justify-center gap-3 mt-6 mb-2">
             <v-progress-circular indeterminate color="primary" size="24" width="3"></v-progress-circular>
             <span class="text-caption font-weight-bold text-uppercase tracking-widest text-primary">Aguardando pagamento...</span>
          </div>
          <v-btn variant="text" block class="mt-4 opacity-70 font-weight-bold" @click="cancelPixPolling">Fechar</v-btn>
        </template>

        <template v-else>
          <div class="py-6">
            <v-icon size="80" color="success" class="mx-auto mb-6 pulse-animation">mdi-check-circle</v-icon>
            <h3 class="text-h4 font-weight-black text-success mb-3">Pagamento Aprovado!</h3>
            <p class="text-body-1 text-medium-emphasis mb-8 px-4">O piloto foi confirmado e será enviado à fila de produção.</p>
            <v-btn color="success" block size="x-large" class="rounded-pill font-weight-black mb-3" @click="showPixModal = false">
               Entendido
            </v-btn>
          </div>
        </template>
      </v-card>
    </v-dialog>

    <v-snackbar
      v-model="showPlagiarismWarning"
      color="error"
      timeout="6000"
      location="top"
      elevation="24"
      class="plagiarism-snackbar"
    >
      <div class="d-flex align-center gap-3">
        <v-icon size="32" class="animate-pulse">mdi-police-badge-outline</v-icon>
        <div>
           <div class="font-weight-black text-subtitle-1 mb-1">TENTATIVA DE CÓPIA DETECTADA</div>
           <div class="text-body-2" style="line-height: 1.2;" v-html="plagiarismWarningText"></div>
        </div>
      </div>
    </v-snackbar>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, inject, watch, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import ImageModal from '@/components/ImageModal.vue'
import QrcodeVue from 'qrcode.vue'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

const router = useRouter()
const route = useRoute()
const cartContext = inject('marketplaceCart') as any
const userStore = useMarketplaceUserStore()

const isLoading = ref(true)
const savingProfile = ref(false)
const savingSecurity = ref(false)
const isUploadingAvatar = ref(false)
const downloadingId = ref<string | null>(null)
const activeTab = ref('dados')

const allowPsdSales = ref(true)
const requireVipDesign = ref(true)

const authEmail = ref('')
const userProfile = ref<any>({})
const profileForm = ref({ name: '', document: '', phone: '', location: '' })
const securityForm = ref({ newPassword: '', confirmPassword: '' })

// Dados de Banco Originais
const orders = ref<any[]>([])
const libraryItems = ref<any[]>([])
const fileInput = ref<HTMLInputElement | null>(null)

// Novos Dados
const pilots = ref<any[]>([])
const transactions = ref<any[]>([])

// Variáveis Estúdio de Design VIP
const requestingAccess = ref(false)
const sendingDesign = ref(false)
const clientFileInput = ref<HTMLInputElement | null>(null)
const designForm = ref<{ notes: string, files: File[], previews: {url: string, name: string}[] }>({ notes: '', files: [], previews: [] })
const allClientDeliveries = ref<any[]>([])

// Variáveis Anti-Plágio e Autodestruição
const showImageModal = ref(false)
const selectedImageSrc = ref('')
const selectedImageTitle = ref('')
const selectedArteId = ref('')
const plagiarismStrikes = ref(0)
const showPlagiarismWarning = ref(false)
const plagiarismWarningText = ref('')
const destructingIds = ref<string[]>([])

// Variáveis Favoritos (Wishlist)
const favoriteStamps = ref<any[]>([])
const favoriteSearch = ref('')
const favoriteCategory = ref<string | null>(null)
const categories = ref<any[]>([])

// Estado Modal PIX
const showPixModal = ref(false)
const pixData = ref({ qrCodeBase64: '', copyPaste: '', txId: '', pilotId: '' })
const pilotApproved = ref(false)
let pixPollingInterval: any = null

const currentTabName = computed(() => {
  const map: Record<string, string> = {
    dados: 'Meus Dados',
    pedidos: 'Orçamentos Físicos',
    pilotos: 'Meus Pilotos',
    transacoes: 'Transações e Recibos',
    estudio: 'Estúdio VIP',
    biblioteca: 'Minha Biblioteca (PSD)',
    carrinho: 'Seleção Atual',
    seguranca: 'Segurança da Conta'
  }
  return map[activeTab.value]
})

const hasDesignAccess = computed(() => {
  return !requireVipDesign.value || userProfile.value.design_access_status === 'granted'
})

// Filtra entregas ativas (autodestruição 24h)
const activeDeliveries = computed(() => {
  const now = new Date()
  return allClientDeliveries.value.filter(arte => {
    const expiresAt = new Date(arte.expires_at)
    return now < expiresAt || arte.force_visible === true
  })
})

const filteredFavorites = computed(() => {
  let list = favoriteStamps.value
  if (favoriteCategory.value) {
    list = list.filter(s => s.category_id === favoriteCategory.value)
  }
  if (favoriteSearch.value) {
    const q = favoriteSearch.value.toLowerCase()
    list = list.filter(s => s.title?.toLowerCase().includes(q) || s.ref_code?.toLowerCase().includes(q))
  }
  return list
})

async function loadCategories() {
  const { data } = await supabase.from('catalog_categories').select('id, name').eq('is_active', true)
  if (data) categories.value = data
}

async function loadFavorites() {
  if (!userStore.wishlist || userStore.wishlist.length === 0) {
    favoriteStamps.value = []
    return
  }
  try {
    const { data } = await supabase
      .from('catalog_stamps')
      .select('*, catalog_categories(name)')
      .in('id', userStore.wishlist)
      .eq('is_active', true)

    if (data) favoriteStamps.value = data
  } catch (error) {
    console.error('Erro ao carregar estampas favoritas:', error)
  }
}

async function removeFavorite(stampId: string) {
  await userStore.toggleWishlist(stampId)
  favoriteStamps.value = favoriteStamps.value.filter(s => s.id !== stampId)
}

function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return '/placeholder.png'
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl

  try {
    const urlParts = originalUrl.split('/object/public/')
    const pathAndBucket = urlParts[1]
    const firstSlashIndex = pathAndBucket.indexOf('/')
    const bucket = pathAndBucket.substring(0, firstSlashIndex)

    let filePath = pathAndBucket.substring(firstSlashIndex + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    filePath = decodeURIComponent(filePath)

    const { data } = supabase.storage.from(bucket).getPublicUrl(filePath, {
      transform: { width: targetWidth }
    })
    return data.publicUrl
  } catch (err) {
    return originalUrl
  }
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) {
    img.src = '/placeholder.png'
  }
}

watch(() => userStore.wishlist, () => {
  loadFavorites()
}, { deep: true })

watch(() => route.query.tab, (newTab) => {
  if (newTab && typeof newTab === 'string') {
    activeTab.value = newTab;
  }
});


onMounted(async () => {
  if (route.query.tab && typeof route.query.tab === 'string') {
     activeTab.value = route.query.tab;
  }

  isLoading.value = true
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) {
      router.push('/marketplace-login')
      return
    }

    authEmail.value = session.user.email || ''

    const { data: leadData } = await supabase
      .from('public_leads')
      .select('*')
      .eq('email', authEmail.value)
      .maybeSingle()

    if (leadData) {
      userProfile.value = leadData
      profileForm.value = {
        name: leadData.name || '',
        document: leadData.document || '',
        phone: leadData.phone || '',
        location: leadData.location || ''
      }
    }

    await loadCategories()
    await loadFavorites()

    try {
      const { data: sysSet } = await supabase.from('system_settings').select('require_vip_design').single()
      if (sysSet) {
        requireVipDesign.value = sysSet.require_vip_design
      }
    } catch (e) {}

    try {
      const { data: settingsData } = await supabase
        .from('storefront_settings')
        .select('allow_psd_sales')
        .order('updated_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (settingsData && settingsData.allow_psd_sales === false) {
        allowPsdSales.value = false
        if (activeTab.value === 'biblioteca') activeTab.value = 'dados'
      }
    } catch (e) {}

    // Entregas de Design (Cofre)
    try {
      const { data: deliveriesData } = await supabase
        .from('client_design_deliveries')
        .select('*')
        .eq('client_email', authEmail.value)
        .order('delivered_at', { ascending: false })
      if (deliveriesData) allClientDeliveries.value = deliveriesData
    } catch (e) {}

    // Pedidos Físicos Originais
    try {
      const resOrder = await supabase
        .from('store_orders')
        .select('*')
        .eq('client_email', authEmail.value)
        .order('created_at', { ascending: false })
      if (resOrder.data) orders.value = resOrder.data
    } catch (e) {}

    // Buscar Pilotos
    if (userProfile.value.id) {
       try {
          const resPilots = await supabase
            .from('pilot_requests')
            .select('*, stamp:catalog_stamps(*), fabric:catalog_fabrics(*)')
            .eq('user_id', userProfile.value.id)
            .order('created_at', { ascending: false })
          if (resPilots.data) pilots.value = resPilots.data
       } catch (e) {}

       // Buscar Transações (Recibos)
       try {
          const resTx = await supabase
            .from('client_transactions')
            .select('*')
            .eq('user_id', userProfile.value.id)
            .order('created_at', { ascending: false })
          if (resTx.data) transactions.value = resTx.data
       } catch (e) {}
    }

    // Biblioteca Digital
    if (allowPsdSales.value) {
      try {
        const resDigital = await supabase
          .from('digital_purchases')
          .select('*, stamp:catalog_stamps(*)')
          .eq('client_email', authEmail.value)
          .eq('status', 'paid')
          .order('created_at', { ascending: false })
        if (resDigital.data) libraryItems.value = resDigital.data
      } catch (e) {}
    }

  } catch (error) {
    console.error('Erro ao carregar perfil:', error)
  } finally {
    isLoading.value = false
  }
})

// === GESTÃO DE ROUBO DE PI E AUTODESTRUIÇÃO ===

function openArtModal(arte: any) {
  selectedImageSrc.value = arte.file_url
  selectedImageTitle.value = `Arte: ${arte.design_request_id} - CONFIDENCIAL`
  selectedArteId.value = arte.id
  plagiarismStrikes.value = 0
  showPlagiarismWarning.value = false
  showImageModal.value = true
}

function closeArtModal() {
  showImageModal.value = false
}

function preventPlagiarism(e: Event) {
  e.preventDefault()
  triggerStrike()
}

function checkKeyboard(e: KeyboardEvent) {
  if (
    e.key === 'PrintScreen' ||
    (e.ctrlKey && (e.key === 's' || e.key === 'p' || e.key === 'c')) ||
    (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'i' || e.key === 'C' || e.key === 'c' || e.key === 'J' || e.key === 'j')) ||
    e.key === 'F12'
  ) {
    e.preventDefault()
    triggerStrike()
  }
}

function triggerStrike() {
  plagiarismStrikes.value++
  if (plagiarismStrikes.value === 1) {
    showPlagiarismWarning.value = true
    plagiarismWarningText.value = 'Esta é uma obra protegida pela <strong>Lei de Direitos Autorais (Lei nº 9.610/98)</strong>.<br>É estritamente proibido salvar, copiar ou reproduzir. Mais 2 tentativas e a arte será destruída.'
  } else if (plagiarismStrikes.value === 2) {
    showPlagiarismWarning.value = true
    plagiarismWarningText.value = '<strong>ÚLTIMO AVISO!</strong> Violação de propriedade intelectual detectada.<br>A próxima tentativa ativará o protocolo de autodestruição.'
  } else if (plagiarismStrikes.value >= 3) {
    showPlagiarismWarning.value = false
    executeSelfDestruct()
  }
}

async function executeSelfDestruct() {
  const idToDestroy = selectedArteId.value
  closeArtModal()

  if (!idToDestroy) return

  destructingIds.value.push(idToDestroy)

  try {
    await supabase.from('client_design_deliveries').update({
      expires_at: new Date().toISOString()
    }).eq('id', idToDestroy)
  } catch(e) {}

  setTimeout(() => {
    allClientDeliveries.value = allClientDeliveries.value.filter(a => a.id !== idToDestroy)
    destructingIds.value = destructingIds.value.filter(id => id !== idToDestroy)
  }, 1200)
}

watch(showImageModal, (newVal) => {
  if (newVal) {
     window.addEventListener('contextmenu', preventPlagiarism)
     window.addEventListener('keydown', checkKeyboard)
     window.addEventListener('dragstart', preventPlagiarism)
  } else {
     window.removeEventListener('contextmenu', preventPlagiarism)
     window.removeEventListener('keydown', checkKeyboard)
     window.removeEventListener('dragstart', preventPlagiarism)
     plagiarismStrikes.value = 0
  }
})

onUnmounted(() => {
  window.removeEventListener('contextmenu', preventPlagiarism)
  window.removeEventListener('keydown', checkKeyboard)
  window.removeEventListener('dragstart', preventPlagiarism)
  if (pixPollingInterval) clearInterval(pixPollingInterval)
})


// === GESTÃO DO ESTÚDIO DE DESIGN VIP ===

async function requestDesignAccess() {
  requestingAccess.value = true
  try {
    await supabase.from('public_leads')
      .update({ design_access_status: 'pending' })
      .eq('email', authEmail.value)

    userProfile.value.design_access_status = 'pending'
  } catch (e) {
    alert('Erro ao solicitar acesso.')
  } finally {
    requestingAccess.value = false
  }
}

function openWhatsAppSuporte() {
  window.open('https://wa.me/5500000000000?text=Olá, solicitei um convite para o Estúdio VIP de Design e gostaria de falar com um consultor.', '_blank')
}

function triggerClientUpload() {
  clientFileInput.value?.click()
}

function handleClientFiles(event: Event) {
  const target = event.target as HTMLInputElement
  if (!target.files) return
  const files = Array.from(target.files)
  files.forEach(file => {
    designForm.value.files.push(file)
    designForm.value.previews.push({ url: URL.createObjectURL(file), name: file.name })
  })
  if (target) target.value = ''
}

function removeClientFile(index: number) {
  designForm.value.files.splice(index, 1)
  designForm.value.previews.splice(index, 1)
}

async function submitDesignToKanban() {
  if (!designForm.value.notes) return alert('Por favor, insira um briefing ou observação.')
  sendingDesign.value = true

  try {
    const uploadedUrls: string[] = []
    const tempDevCode = `STORE-${Date.now().toString().slice(-5)}`

    for (const file of designForm.value.files) {
      const fileExt = file.name.split('.').pop()
      const filePath = `${tempDevCode}/vip_${Date.now()}.${fileExt}`
      const { error } = await supabase.storage.from('arts').upload(filePath, file)
      if (!error) {
        const { data: { publicUrl } } = supabase.storage.from('arts').getPublicUrl(filePath)
        uploadedUrls.push(publicUrl)
      }
    }

    const { error: rpcError } = await supabase.rpc('create_design_request', {
      p_general_notes: "Solicitação via Estúdio VIP (Marketplace)",
      p_store_id: null,
      p_design_items: [{
        customer_id: userProfile.value.id,
        customer_name: userProfile.value.name || 'Cliente VIP (Site)',
        notes: designForm.value.notes,
        attachments: uploadedUrls,
        meta_summary: 'Briefing VIP via Site'
      }],
      p_created_by: null,
      p_request_type: 'development'
    })

    if (rpcError) throw rpcError

    alert('🚀 Sua solicitação VIP foi enviada direto para nossa equipe de design!')
    designForm.value = { notes: '', files: [], previews: [] }

  } catch (error) {
    console.error('Erro no envio VIP:', error)
    alert('Ocorreu um erro ao enviar sua solicitação. Tente novamente.')
  } finally {
    sendingDesign.value = false
  }
}

function getHoursLeft(expiresAtStr: string) {
  const now = new Date().getTime()
  const exp = new Date(expiresAtStr).getTime()
  const diffMs = exp - now
  if (diffMs <= 0) return 'Expirado'
  const diffHrs = Math.floor(diffMs / (1000 * 60 * 60))
  const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
  return `${diffHrs}h ${diffMins}m`
}

// === GESTÃO DO PERFIL ===

async function saveProfile() {
  savingProfile.value = true
  try {
    const { error } = await supabase
      .from('public_leads')
      .update({
        name: profileForm.value.name,
        document: profileForm.value.document,
        phone: profileForm.value.phone,
        location: profileForm.value.location
      })
      .eq('email', authEmail.value)

    if (error) throw error

    userProfile.value = { ...userProfile.value, ...profileForm.value }
    alert('✅ Perfil atualizado com sucesso!')
  } catch (error) {
    console.error('Erro ao salvar:', error)
    alert('Erro ao atualizar perfil.')
  } finally {
    savingProfile.value = false
  }
}

async function updatePassword() {
  if (securityForm.value.newPassword !== securityForm.value.confirmPassword) {
    alert('As senhas não coincidem.')
    return
  }

  savingSecurity.value = true
  try {
    const { error } = await supabase.auth.updateUser({
      password: securityForm.value.newPassword
    })

    if (error) throw error
    alert('✅ Senha atualizada com segurança!')
    securityForm.value.newPassword = ''
    securityForm.value.confirmPassword = ''
  } catch (error) {
    console.error('Erro ao atualizar senha:', error)
    alert('Erro ao atualizar senha. Verifique se a mesma possui o mínimo de 6 caracteres.')
  } finally {
    savingSecurity.value = false
  }
}

// === AVATAR UPLOAD ===

function triggerAvatarUpload() {
  fileInput.value?.click()
}

async function handleAvatarUpload(event: Event) {
  const target = event.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  const fileExt = file.name.split('.').pop()
  const filePath = `avatars/${authEmail.value}-${Math.random()}.${fileExt}`

  try {
    isUploadingAvatar.value = true

    const { error: uploadError } = await supabase.storage
      .from('catalog-assets')
      .upload(filePath, file)

    if (uploadError) throw uploadError

    const { data: { publicUrl } } = supabase.storage
      .from('catalog-assets')
      .getPublicUrl(filePath)

    await supabase
      .from('public_leads')
      .update({ avatar_url: publicUrl })
      .eq('email', authEmail.value)

    userProfile.value.avatar_url = publicUrl
  } catch (error) {
    console.error('Erro no upload de avatar:', error)
    alert('Não foi possível fazer o upload da imagem.')
  } finally {
    isUploadingAvatar.value = false
  }
}

async function logout() {
  await supabase.auth.signOut()
  router.push('/marketplace-login')
}

// === ANTI-PIRATARIA PSD ===
async function downloadDigitalFile(purchaseId: string) {
  downloadingId.value = purchaseId
  try {
    const { data, error } = await supabase.functions.invoke('generate-download-link', {
      body: { purchase_id: purchaseId }
    })

    if (error) throw new Error(error.message)

    if (data && data.signedUrl) {
      window.open(data.signedUrl, '_blank')
    } else {
      throw new Error(data?.error || 'Erro ao gerar assinatura digital.')
    }
  } catch (error: any) {
    console.error('Erro de segurança no download:', error)
    alert(`Acesso Negado: ${error.message || 'Você não tem permissão para baixar este arquivo ou o link expirou.'}`)
  } finally {
    downloadingId.value = null
  }
}

// === RETOMAR PAGAMENTO DO PILOTO ===
function resumePilotPix(pilot: any) {
    if (!pilot.pix_qr_code) {
        alert("Código PIX não encontrado para este pedido. Entre em contato com o suporte.");
        return;
    }
    pixData.value = {
        qrCodeBase64: pilot.pix_qr_code_base64 || '',
        copyPaste: pilot.pix_qr_code,
        txId: pilot.id,
        pilotId: pilot.id
    };
    pilotApproved.value = false;
    showPixModal.value = true;

    // Busca novamente o ID da fatura na Cora se tiver
    const invoiceId = pilot.payment_id || '';
    startPixPolling(pilot.id, invoiceId);
}

function startPixPolling(pilotId: string, coraInvoiceId: string = '') {
    if (pixPollingInterval) clearInterval(pixPollingInterval);

    pixPollingInterval = setInterval(async () => {
        const { data } = await supabase.from('pilot_requests').select('payment_status').eq('id', pilotId).single();

        if (data && (data.payment_status === 'approved' || data.payment_status === 'paid')) {
            pilotApproved.value = true;
            clearInterval(pixPollingInterval);

            // Atualiza o frontend localmente
            const p = pilots.value.find(x => x.id === pilotId);
            if (p) p.status = 'paid';
        }
    }, 4500);
}

function cancelPixPolling() {
    if (pixPollingInterval) clearInterval(pixPollingInterval);
    showPixModal.value = false;
}

function copyPixText() {
    navigator.clipboard.writeText(pixData.value.copyPaste).then(() => {
        alert('Código PIX Copiado!');
    });
}

// === HELPERS DE FORMATAÇÃO ===

function formatDate(dateString: string) {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  })
}

function formatPrice(value: number) {
  return Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function translateStatus(status: string) {
  const map: Record<string, string> = {
    'pending': 'Em Análise',
    'approved': 'Aprovado / Em Produção',
    'completed': 'Finalizado',
    'cancelled': 'Cancelado'
  }
  return map[status] || 'Processando'
}

function translatePilotStatus(status: string) {
  const map: Record<string, string> = {
    'pending_payment': 'Aguardando Pagamento',
    'paid': 'Aprovado / Fila de Produção',
    'in_production': 'Em Produção',
    'shipped': 'Enviado',
    'delivered': 'Entregue',
    'canceled': 'Cancelado'
  }
  return map[status] || 'Em Análise'
}
</script>

<style scoped>
/* =========================================================
   ESTILOS ORIGINAIS DO SEU DESIGN MJ-SURFACE
========================================================= */

.view-wrap {
  padding-top: 82px;
}

.profile-view {
  min-height: calc(100vh - 82px);
  background: var(--bg-main);
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 60vh;
  gap: 16px;
  border-radius: 28px;
  margin: 40px auto;
  max-width: 600px;
  color: var(--text-muted);
}

.profile-container {
  padding-top: 34px;
  padding-bottom: 60px;
}

.profile-breadcrumb {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 24px;
}

.back-btn {
  border-radius: 14px !important;
}

.profile-layout {
  display: grid;
  grid-template-columns: 290px 1fr;
  gap: 32px;
  align-items: start;
}

/* --- SIDEBAR --- */
.profile-sidebar {
  border-radius: 28px;
  overflow: hidden;
  position: sticky;
  top: 110px;
  display: flex;
  flex-direction: column;
  box-shadow: var(--surface-shadow);
}

.user-card {
  padding: 36px 24px;
  text-align: center;
  border-bottom: 1px solid var(--border-color);
  background: linear-gradient(180deg, rgba(var(--v-theme-primary), 0.03), transparent);
}

.avatar-wrapper {
  width: 96px;
  height: 96px;
  margin: 0 auto 16px;
  border-radius: 50%;
  position: relative;
  cursor: pointer;
  overflow: hidden;
  border: 4px solid var(--bg-surface);
  box-shadow: 0 12px 28px rgba(0,0,0,0.12);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.avatar-wrapper:hover:not(.is-uploading) {
  transform: scale(1.05);
  box-shadow: 0 16px 32px rgba(0,0,0,0.18);
}

.avatar-loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(var(--v-theme-primary), 0.8);
  display: grid;
  place-items: center;
  z-index: 2;
}

.user-avatar {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  background: var(--bg-surface-2);
  color: var(--text-muted);
}

.avatar-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.avatar-wrapper:hover:not(.is-uploading) .avatar-overlay {
  opacity: 1;
}

.user-name {
  color: var(--text-main);
  font-size: 1.15rem;
  font-weight: 800;
  margin: 0;
  letter-spacing: -0.01em;
}

.user-email {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 4px;
}

.profile-nav {
  display: flex;
  flex-direction: column;
  padding: 16px;
  gap: 6px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 100%;
  min-height: 50px;
  padding: 0 16px;
  border: 0;
  background: transparent;
  color: var(--text-soft);
  font-size: 0.95rem;
  font-weight: 700;
  border-radius: 16px;
  transition: all 0.2s ease;
  position: relative;
}

.nav-item:hover {
  background: var(--bg-surface-2);
  color: var(--text-main);
}

.nav-item.active {
  background: rgba(var(--v-theme-primary), 0.1);
  color: rgb(var(--v-theme-primary));
}

.nav-icon {
  opacity: 0.7;
}

.nav-item.active .nav-icon {
  opacity: 1;
}

.nav-badge {
  position: absolute;
  right: 16px;
  background: rgb(var(--v-theme-primary));
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 999px;
  box-shadow: 0 4px 10px rgba(var(--v-theme-primary), 0.3);
}

.sidebar-footer {
  padding: 16px;
  margin-top: auto;
  border-top: 1px solid var(--border-color);
}

.logout-btn {
  border-radius: 16px !important;
  font-weight: 800 !important;
}

/* --- MAIN CONTENT --- */
.tab-panel {
  border-radius: 28px;
  padding: 36px;
  min-height: 600px;
  box-shadow: var(--surface-shadow);
}

.panel-header {
  margin-bottom: 36px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--border-color);
}

.panel-title {
  color: var(--text-main);
  font-size: 1.8rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin: 0;
}

.panel-desc {
  color: var(--text-muted);
  font-size: 1rem;
  margin-top: 6px;
}

/* FORMULÁRIOS */
.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  color: var(--text-main);
  font-size: 0.85rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.mj-input {
  width: 100%;
  height: 56px;
  padding: 0 18px;
  border-radius: 16px;
  color: var(--text-main);
  font-size: 1.05rem;
  outline: none;
  transition: all 0.2s ease;
}

.mj-input:focus {
  border-color: rgba(var(--v-theme-primary), 0.65);
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.12);
  background: var(--bg-surface);
}

.form-actions {
  margin-top: 32px;
  display: flex;
  justify-content: flex-end;
}

.action-btn {
  border-radius: 16px !important;
  font-weight: 800 !important;
  padding: 0 36px !important;
  letter-spacing: 0.02em;
}

.security-section h4 {
  color: var(--text-main);
  font-size: 1.2rem;
  font-weight: 800;
}

/* TIMELINE DE PEDIDOS E PILOTOS */
.timeline-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.order-card {
  border-radius: 24px;
  padding: 28px;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}

.order-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--hover-shadow);
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-color);
}

.order-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.order-id {
  color: var(--text-main);
  font-weight: 900;
  font-size: 1.2rem;
  letter-spacing: -0.01em;
}

.order-date {
  color: var(--text-muted);
  font-size: 0.9rem;
}

.order-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background: var(--bg-surface);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

/* Status Colors */
.order-status-badge.pending, .order-status-badge.pending_payment { color: #d97706; background: rgba(245, 158, 11, 0.1); }
.order-status-badge.pending .status-dot, .order-status-badge.pending_payment .status-dot { background: #f59e0b; box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2); }

.order-status-badge.approved, .order-status-badge.in_production { color: #2563eb; background: rgba(59, 130, 246, 0.1); }
.order-status-badge.approved .status-dot, .order-status-badge.in_production .status-dot { background: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2); }

.order-status-badge.completed, .order-status-badge.delivered, .order-status-badge.paid, .order-status-badge.shipped { color: #059669; background: rgba(16, 185, 129, 0.1); }
.order-status-badge.completed .status-dot, .order-status-badge.delivered .status-dot, .order-status-badge.paid .status-dot, .order-status-badge.shipped .status-dot { background: #10b981; box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2); }

.order-status-badge.cancelled, .order-status-badge.canceled { color: #dc2626; background: rgba(239, 68, 68, 0.1); }
.order-status-badge.cancelled .status-dot, .order-status-badge.canceled .status-dot { background: #ef4444; box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2); }

.order-items {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.order-item {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 12px;
  border-radius: 16px;
  background: var(--bg-surface);
}

.pilot-item {
  align-items: flex-start;
  padding: 20px;
}

.item-thumb {
  width: 72px;
  height: 72px;
  border-radius: 12px;
  object-fit: cover;
}

.pilot-item .item-thumb {
  width: 110px;
  height: 110px;
}

.item-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.item-info strong {
  color: var(--text-main);
  font-size: 1.05rem;
  font-weight: 800;
}

.item-specs {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 2px;
}

.item-price {
  color: var(--text-main);
}

.order-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px dashed var(--border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.total-label {
  color: var(--text-muted);
  font-weight: 800;
  text-transform: uppercase;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
}

.total-value {
  font-size: 1.6rem;
  font-weight: 900;
  letter-spacing: -0.02em;
}

/* TABELA DE TRANSAÇÕES */
.table-responsive {
  overflow-x: auto;
}
.mj-table {
  border-collapse: collapse;
}
.mj-table th, .mj-table td {
  padding: 12px 16px;
}
.mj-table tr:not(:last-child) {
  border-bottom: 1px solid var(--border-color);
}

/* BIBLIOTECA PSD */
.library-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}

.library-card {
  border-radius: 24px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}

.library-card:hover {
  transform: translateY(-6px);
  box-shadow: var(--hover-shadow);
  border-color: rgba(var(--v-theme-primary), 0.3);
}

.library-image-wrap {
  position: relative;
  width: 100%;
  height: 200px;
}

.library-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.resolution-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  background: rgba(0,0,0,0.7);
  color: #fff;
  backdrop-filter: blur(8px);
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 900;
  letter-spacing: 0.1em;
}

.library-info {
  padding: 24px;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.lib-ref {
  color: var(--text-muted);
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 8px;
}

.lib-title {
  color: var(--text-main);
  font-size: 1.15rem;
  font-weight: 800;
  line-height: 1.2;
  margin: 0 0 10px;
}

.lib-date {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-bottom: auto;
}

.download-btn {
  border-radius: 14px !important;
  font-weight: 800 !important;
  letter-spacing: 0.02em;
}

/* CARRINHO TAB */
.cart-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.cart-item {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 20px;
  border-radius: 24px;
}

.cart-image {
  width: 90px;
  height: 90px;
  border-radius: 16px;
  object-fit: cover;
}

.cart-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.badge-physical, .badge-digital {
  font-size: 9px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  padding: 2px 6px;
  border-radius: 4px;
}

.badge-physical { background: rgba(var(--v-theme-primary), 0.15); color: rgb(var(--v-theme-primary)); }
.badge-digital { background: rgba(16, 185, 129, 0.15); color: #10b981; }

.cart-ref {
  color: var(--text-muted);
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.cart-title {
  color: var(--text-main);
  font-size: 1.2rem;
  font-weight: 800;
  margin: 4px 0 6px;
}

.cart-specs {
  color: var(--text-muted);
  font-size: 0.9rem;
}

.remove-cart-btn {
  background: var(--bg-surface);
  border-radius: 14px;
}

.remove-cart-btn:hover {
  background: rgba(239, 68, 68, 0.1);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 80px 20px;
  color: var(--text-muted);
}

.empty-icon-wrap {
  width: 90px;
  height: 90px;
  border-radius: 24px;
  display: grid;
  place-items: center;
  margin-bottom: 24px;
}

.empty-state h4 {
  color: var(--text-main);
  font-size: 1.4rem;
  font-weight: 800;
  margin: 0 0 10px;
}

.empty-state p {
  margin-bottom: 24px;
  max-width: 420px;
  line-height: 1.6;
}


/* =========================================================
   DESTAQUES VIP DOURADOS SUTIS
========================================================= */
.vip-nav-btn.active {
  background: rgba(245, 158, 11, 0.1) !important;
}
.vip-text-gradient {
  background: linear-gradient(45deg, #F59E0B, #FCD34D, #F59E0B);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 900;
}
.vip-glow {
  filter: drop-shadow(0 0 8px rgba(245, 158, 11, 0.6));
}
.shadow-gold {
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3) !important;
}
.vip-locked-state {
  border: 1px solid rgba(245, 158, 11, 0.3) !important;
  background: linear-gradient(180deg, rgba(245, 158, 11, 0.05) 0%, transparent 100%);
  padding: 80px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

/* =========================================================
   COFRE DE ARTES VIP (3D GALLERY) & AUTODESTRUIÇÃO
========================================================= */
.vip-vault-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 24px;
}

.art-3d-wrapper {
  perspective: 1000px;
  transform-style: preserve-3d;
}

.art-3d-card {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  transform: rotateY(-12deg) rotateX(4deg);
  transition: transform 0.4s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.4s ease;
  box-shadow: -10px 15px 25px rgba(0,0,0,0.3);
  background: #000;
  border: 1px solid rgba(255,255,255,0.1);
  aspect-ratio: 1;
}

.art-3d-card:hover {
  transform: rotateY(-4deg) rotateX(2deg) scale(1.05);
  box-shadow: -5px 10px 30px rgba(245, 158, 11, 0.4);
  border-color: #f59e0b;
}

.art-media-container {
  width: 100%;
  height: 100%;
}

.art-img-filter {
  transition: filter 0.4s ease;
}
.art-3d-card:hover .art-img-filter {
  filter: blur(2px) brightness(0.6);
}

.art-overlay {
  position: absolute;
  inset: 0;
  opacity: 0;
  transition: opacity 0.3s ease;
  background: rgba(0,0,0,0.4);
}

.art-3d-card:hover .art-overlay {
  opacity: 1;
}

/* ANIMAÇÃO DE AUTODESTRUIÇÃO (FOGO/DERRETIMENTO) */
.destructing {
  animation: burn-out 1.2s forwards cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none;
}

@keyframes burn-out {
  0% { transform: scale(1); filter: brightness(1) sepia(0); opacity: 1; }
  20% { transform: scale(1.1); filter: brightness(2) sepia(1) hue-rotate(-50deg) saturate(5); box-shadow: 0 0 50px #ef4444; }
  50% { transform: scale(0.8) rotate(10deg); filter: blur(8px) brightness(3); opacity: 0.8; }
  100% { transform: scale(0) rotate(-15deg); filter: blur(15px); opacity: 0; }
}

.plagiarism-snackbar {
  z-index: 10000 !important;
}

.animate-pulse {
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.2); opacity: 0.8; }
  100% { transform: scale(1); opacity: 1; }
}

/* =========================================================
   PINTEREST MASONRY GRID (FAVORITOS)
========================================================= */
.pinterest-grid {
  column-count: 2;
  column-gap: 20px;
}
@media (min-width: 768px) {
  .pinterest-grid { column-count: 3; }
}
@media (min-width: 1024px) {
  .pinterest-grid { column-count: 4; }
}
@media (min-width: 1440px) {
  .pinterest-grid { column-count: 5; }
}

.pinterest-item {
  break-inside: avoid;
  margin-bottom: 20px;
  border-radius: 16px;
  overflow: hidden;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}
.pinterest-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 32px rgba(0,0,0,0.1);
}
.shadow-soft {
  box-shadow: 0 8px 24px rgba(0,0,0,0.15) !important;
}


/* Transições */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* RESPONSIVIDADE */
@media (max-width: 1199px) {
  .library-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 959px) {
  .profile-layout { grid-template-columns: 1fr; }
  .profile-sidebar { position: static; box-shadow: none; }
  .form-grid { grid-template-columns: 1fr; }
}

@media (max-width: 767px) {
  .tab-panel { padding: 24px; min-height: 400px; border-radius: 24px; }
  .panel-title { font-size: 1.4rem; }
  .library-grid { grid-template-columns: 1fr; }

  .order-item { flex-direction: column; align-items: flex-start; gap: 12px; }
  .item-thumb { width: 100%; height: 140px; }
  .pilot-item .item-thumb { width: 100%; height: 180px; }
  .item-price { margin-top: 8px; text-align: left; }

  .profile-container { width: min(100%, calc(100% - 20px)); padding-top: 20px; }
  .order-header { flex-direction: column; gap: 16px; }
  .order-footer { flex-direction: column; align-items: flex-start; gap: 8px; }

  .cart-item { flex-direction: column; align-items: flex-start; gap: 16px; position: relative; }
  .cart-image { width: 100%; height: 180px; }
  .remove-cart-btn { position: absolute; top: 16px; right: 16px; }

  .vip-vault-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }

  .mobile-price-left {
     align-items: flex-start !important;
     text-align: left !important;
     margin-top: 12px;
     width: 100%;
  }
  .mobile-price-left .v-btn, .mobile-price-left .bg-warning-lighten-5 {
     width: 100%;
     max-width: 100% !important;
     text-align: center !important;
     justify-content: center;
  }
}
</style>
