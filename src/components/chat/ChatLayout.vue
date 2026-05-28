<template>
  <div class="app-chat-container" :class="{ 'is-mobile': isMobileView }">

    <div v-if="!isMobileView" class="desktop-layout">

      <nav class="col-1-nav">
        <div class="nav-top">
          <v-avatar size="40" class="mb-6 cursor-pointer elevation-2" color="primary">
            <v-img v-if="userStore.profile?.avatar_url" :src="userStore.profile.avatar_url" cover></v-img>
            <span v-else class="text-white">{{ userStore.profile?.full_name?.charAt(0).toUpperCase() || 'U' }}</span>
          </v-avatar>
          <v-btn icon="mdi-message-text" variant="text" color="primary" class="mb-2" v-tooltip="'Conversas'"></v-btn>
          <v-btn icon="mdi-account-group" variant="text" class="text-medium-emphasis mb-2" v-tooltip="'Contatos'"></v-btn>
        </div>

        <div class="nav-bottom">
          <v-menu location="right bottom" offset="10" z-index="99999">
            <template v-slot:activator="{ props }">
              <v-btn v-bind="props" icon="mdi-cog" variant="text" class="text-medium-emphasis mb-2" v-tooltip="'Configurações'"></v-btn>
            </template>
            <v-list density="compact" class="bg-surface elevation-3 rounded-lg py-1">
              <v-list-item @click="triggerWallpaperUpload" :disabled="isUploadingWallpaper">
                <template v-slot:prepend><v-icon size="small" class="mr-3">mdi-image-outline</v-icon></template>
                <v-list-item-title>Alterar Fundo do Chat</v-list-item-title>
              </v-list-item>
              <v-list-item v-if="userStore.profile?.chat_wallpaper_url" @click="resetWallpaper" class="text-error" :disabled="isUploadingWallpaper">
                <template v-slot:prepend><v-icon size="small" class="mr-3">mdi-delete-outline</v-icon></template>
                <v-list-item-title>Remover Fundo</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>
        </div>
      </nav>

      <aside class="col-2-list bg-surface">
        <ChatSidebar
          :channels="channels"
          :active-channel-id="activeChannelId"
          @select-channel="setActiveChannel"
          @open-new-chat-modal="openNewChatModal"
          @channel-action="handleChannelAction"
          :is-mobile="false"
          :is-chat-active="!!activeChannelId"
        />
      </aside>

      <main class="col-3-chat transition-all"
            @dragenter.prevent="handleDragEnter"
            @dragover.prevent="handleDragOver"
            @dragleave.prevent="handleDragLeave"
            @drop.prevent="handleDrop"
      >
        <v-fade-transition>
          <div v-if="isDraggingFile" class="drag-drop-overlay d-flex flex-column align-center justify-center">
            <div class="drag-drop-content d-flex flex-column align-center justify-center rounded-xl elevation-10 pa-8 text-center bg-surface">
              <v-icon size="80" color="primary" class="mb-4 pulse-anim">mdi-cloud-upload-outline</v-icon>
              <h2 class="text-h5 font-weight-bold text-high-emphasis mb-2">Solte seus arquivos aqui</h2>
              <p class="text-medium-emphasis text-body-1">Eles serão adicionados como anexo na conversa.</p>
            </div>
          </div>
        </v-fade-transition>

        <div v-if="loadingChannel" class="h-100 d-flex justify-center align-center">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>

        <div v-else-if="activeChannel" class="chat-wrapper d-flex flex-column h-100 w-100 position-relative">
          <ChatHeader
            :channel="activeChannel"
            :online-users="allUsersWithStatus"
            v-model:searchQuery="searchQuery"
            @toggle-repository="showRepository = true"
            @open-info="showDesktopInfoPanel = !showDesktopInfoPanel"
            :is-mobile="false"
            class="header-elevation"
          />

          <div ref="messagesList" class="messages-area flex-grow-1" @scroll="handleScroll" :style="wallpaperStyle">
            <div v-if="isLoadingMore" class="d-flex justify-center pa-4 mb-2">
              <v-progress-circular indeterminate color="primary" size="24"></v-progress-circular>
            </div>

            <template v-for="(group, index) in filteredGroupedMessages" :key="index">
              <div class="date-divider"><span>{{ group.date }}</span></div>
              <ChatMessage
                v-for="(message, msgIndex) in group.messages"
                :key="message.id"
                :message="message"
                :is-consecutive="isConsecutiveMessage(message, msgIndex, group.messages)"
                :search-query="searchQuery"
                :is-group="!activeChannel.is_private_dm"
                @show-menu="onShowMenu"
                @view-media="handleViewMedia"
                @reply="handleSwipeReply"
                @scroll-to="scrollToMessage"
              />
            </template>
          </div>

          <v-scale-transition>
            <v-btn
              v-show="showScrollButton"
              icon="mdi-chevron-down"
              color="surface"
              elevation="4"
              class="scroll-bottom-btn"
              size="small"
              @click="scrollToBottom(true, false)"
            ></v-btn>
          </v-scale-transition>

          <div class="input-area bg-surface">
            <div class="preview-area reply-preview" v-if="replyingToMessage">
              <div class="d-flex align-center w-100 overflow-hidden">
                <div v-if="replyingToMessage.message_type === 'image' || replyingToMessage.message_type === 'video'" class="reply-preview-thumb mr-3">
                  <img :src="replyingToMessage.content" class="h-100 w-100" style="object-fit: cover; border-radius: 4px;" />
                  <div v-if="replyingToMessage.message_type === 'video'" class="video-overlay-small">
                     <v-icon size="16" color="white">mdi-play</v-icon>
                  </div>
                </div>
                <div v-else-if="replyingToMessage.message_type === 'audio'" class="reply-preview-thumb bg-primary-lighten-4 d-flex align-center justify-center mr-3 rounded">
                   <v-icon color="primary" size="20">mdi-microphone</v-icon>
                </div>
                <div v-else-if="replyingToMessage.message_type === 'file' || replyingToMessage.message_type === 'document'" class="reply-preview-thumb bg-grey-lighten-2 d-flex align-center justify-center mr-3 rounded">
                   <v-icon color="grey-darken-2" size="20">mdi-file-document</v-icon>
                </div>

                <div class="preview-content flex-grow-1 overflow-hidden">
                  <div class="d-flex align-center mb-1">
                    <v-icon size="small" color="primary">mdi-reply</v-icon>
                    <strong class="ml-1 text-primary text-caption">Respondendo a {{ replyingToMessage.profile?.full_name || 'Usuário' }}</strong>
                  </div>
                  <p class="text-caption text-truncate mb-0 text-medium-emphasis">
                     {{ (!replyingToMessage.message_type || replyingToMessage.message_type === 'text') ? replyingToMessage.content : (replyingToMessage.message_type === 'image' ? '📷 Foto' : (replyingToMessage.message_type === 'video' ? '🎥 Vídeo' : (replyingToMessage.message_type === 'audio' ? '🎵 Áudio' : '📄 Arquivo'))) }}
                  </p>
                </div>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" @click="cancelReply" class="ml-2"></v-btn>
            </div>

            <div class="preview-area edit-preview" v-if="editingMessage">
              <div class="preview-content">
                <v-icon size="small" color="warning">mdi-pencil</v-icon>
                <strong class="ml-2 text-warning">Editando mensagem</strong>
                <p class="text-caption text-truncate mb-0 text-medium-emphasis">{{ editingMessage.content }}</p>
              </div>
              <v-btn icon="mdi-close" variant="text" size="small" @click="cancelEdit"></v-btn>
            </div>

            <div v-if="activeChannel.is_locked && userStore.profile?.role !== 'admin' && userStore.profile?.role !== 'super_admin'" class="d-flex align-center justify-center w-100 pa-3 bg-error-lighten-5 text-error rounded-lg border-error">
               <v-icon class="mr-2">mdi-lock</v-icon>
               <span class="font-weight-bold">A Administração bloqueou temporariamente este chat.</span>
            </div>

            <div v-else class="input-controls d-flex align-center w-100">
              <input type="file" ref="fileInputDesktop" @change="handleFileUpload" multiple style="display: none" />

              <template v-if="!isRecording">

                <v-menu v-model="showEmojiPickerDesktop" :close-on-content-click="false" location="top start" offset="10">
                  <template v-slot:activator="{ props }">
                    <v-btn v-bind="props" icon="mdi-emoticon-outline" variant="text" class="text-medium-emphasis mr-1"></v-btn>
                  </template>
                  <v-card width="320" height="400" class="d-flex flex-column emoji-picker-card bg-surface">
                    <div class="emoji-picker-header bg-surface-variant px-3 py-2 d-flex justify-space-between align-center border-b">
                      <span class="text-caption font-weight-bold text-medium-emphasis">Emojis</span>
                      <v-btn icon="mdi-close" variant="text" size="x-small" @click="showEmojiPickerDesktop = false"></v-btn>
                    </div>
                    <div class="emoji-categories d-flex px-2 py-1 bg-surface border-b">
                      <v-btn v-for="(cat, idx) in emojiCategories" :key="idx" icon variant="text" size="small" :color="activeEmojiCategory === idx ? 'primary' : 'medium-emphasis'" @click="activeEmojiCategory = idx">
                        <v-icon size="20">{{ cat.icon }}</v-icon>
                      </v-btn>
                    </div>
                    <v-window v-model="activeEmojiCategory" class="flex-grow-1 overflow-hidden">
                      <v-window-item v-for="(cat, idx) in emojiCategories" :key="idx" :value="idx" class="h-100">
                        <div class="emoji-grid pa-2 custom-scroll h-100 overflow-y-auto">
                          <span v-for="emoji in cat.emojis" :key="emoji" class="emoji-item cursor-pointer" @click="insertEmoji(emoji)">
                            {{ emoji }}
                          </span>
                        </div>
                      </v-window-item>
                    </v-window>
                  </v-card>
                </v-menu>

                <v-btn icon="mdi-paperclip" variant="text" class="text-medium-emphasis mr-2" @click="triggerFileInput"></v-btn>

                <div class="input-field-wrapper flex-grow-1 elevation-1">
                  <v-text-field
                    v-model="newMessage"
                    @keydown.enter.prevent="handleSend"
                    variant="solo"
                    flat
                    placeholder="Digite uma mensagem"
                    hide-details
                    density="compact"
                    class="chat-text-field"
                    autofocus
                  ></v-text-field>
                </div>
              </template>

              <template v-else>
                <div class="recording-ui d-flex align-center flex-grow-1 bg-surface py-1 px-3 rounded-pill elevation-2 mr-2">
                  <v-btn icon="mdi-delete" variant="text" color="grey-darken-1" size="small" class="mr-2" @click="cancelRecording"></v-btn>

                  <div class="mic-pulse-wrapper d-flex align-center mr-3">
                    <v-icon color="error" class="pulse-anim mr-2" size="20">mdi-microphone</v-icon>
                    <span class="text-error font-weight-medium text-body-2">{{ recordingTime }}</span>
                  </div>

                  <div class="live-waveform flex-grow-1 d-flex align-center justify-end overflow-hidden">
                    <div class="wave-bar" v-for="(h, i) in recordingWaves" :key="i" :style="{ height: Math.max(h, 15) + '%' }"></div>
                  </div>
                </div>
              </template>

              <div class="action-buttons ml-2">
                <v-btn v-if="!newMessage.trim() && !isRecording" icon="mdi-microphone" variant="text" class="text-medium-emphasis" @click="startRecording"></v-btn>
                <v-btn v-else-if="isRecording" icon="mdi-send" color="success" variant="flat" elevation="2" class="pulse-send-btn" @click="stopRecordingAndSend"></v-btn>
                <v-btn v-else icon="mdi-send" color="primary" variant="flat" elevation="2" @click="handleSend"></v-btn>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="empty-chat d-flex flex-column justify-center align-center h-100 bg-surface">
          <v-icon size="64" class="text-disabled mb-4">mdi-forum-outline</v-icon>
          <h2 class="text-high-emphasis font-weight-bold">Selecione uma conversa</h2>
          <p class="text-medium-emphasis">Escolha um contato ou grupo para começar a conversar.</p>
        </div>
      </main>

      <aside v-if="activeChannel && showDesktopInfoPanel" class="col-4-info bg-surface transition-all border-s">
        <ChatProfileInfo
          :channel="activeChannel"
          :is-mobile="false"
          @close="showDesktopInfoPanel = false"
          @open-media="showRepository = true"
          @action="handleProfileInfoAction"
        />
      </aside>

      <aside class="col-5-contacts bg-surface border-s transition-all">
        <div class="contacts-header d-flex align-center bg-surface-variant elevation-1">
          <div class="icon-wrapper d-flex justify-center flex-shrink-0">
            <v-icon color="primary" size="24">mdi-account-group</v-icon>
          </div>
          <h3 class="font-weight-bold text-high-emphasis text-body-1 mb-0 header-title text-uppercase tracking-wide">
            Contatos ({{ allUsersWithStatus.length }})
          </h3>
        </div>

        <div class="contacts-list flex-grow-1 overflow-y-auto">
          <div
            v-for="user in allUsersWithStatus"
            :key="user.id"
            class="contact-item d-flex align-center cursor-pointer hover-effect py-3 px-2 border-bottom"
            @click="startDirectMessage(user)"
          >
            <div class="avatar-wrapper d-flex justify-center flex-shrink-0 pl-1">
              <v-badge
                dot
                location="bottom right"
                offset-x="2"
                offset-y="2"
                :color="user.status === 'online' ? 'success' : (user.status === 'away' ? 'warning' : 'grey-lighten-1')"
              >
                <v-avatar size="44" color="blue-grey-lighten-4" class="elevation-1">
                  <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                  <span v-else class="text-blue-grey-darken-3 font-weight-bold text-h6">
                    {{ user.full_name?.charAt(0).toUpperCase() || 'U' }}
                  </span>
                </v-avatar>
              </v-badge>
            </div>

            <div class="contact-info d-flex flex-column min-w-0 pr-3 ml-2 flex-grow-1 overflow-hidden">
              <span class="font-weight-bold text-body-2 text-high-emphasis text-truncate mb-1">
                {{ user.full_name || 'Usuário' }}
              </span>
              <div class="d-flex align-center justify-space-between w-100">
                <span class="text-caption text-truncate text-medium-emphasis" style="max-width: 110px;">
                  {{ user.role || 'Membro' }}
                </span>
                <span class="text-caption font-weight-medium d-flex align-center" :class="user.status === 'online' ? 'text-success' : 'text-disabled'">
                  {{ user.status === 'online' ? 'Online' : (user.status === 'away' ? 'Ausente' : 'Offline') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </aside>

    </div>

    <div v-else class="mobile-layout">

      <div v-show="!activeChannelId" class="mobile-screen-list d-flex flex-column h-100 w-100 position-relative">
        <ChatSidebar
          :channels="channels"
          :active-channel-id="activeChannelId"
          @select-channel="setActiveChannel"
          @open-new-chat-modal="openNewChatModal"
          @channel-action="handleChannelAction"
          :is-mobile="true"
          :is-chat-active="false"
          class="flex-grow-1"
        />
        <v-btn color="surface" icon="mdi-cog" size="large" class="mobile-settings-fab" elevation="4" @click="showMobileSettings = true"></v-btn>
        <v-btn color="primary" icon="mdi-account-group" size="large" class="mobile-contacts-fab" elevation="4" @click="showPresenceModal = true"></v-btn>
        <v-btn color="primary" icon="mdi-message-plus" size="large" class="mobile-fab" elevation="4" @click="openNewChatModal('contacts')"></v-btn>
      </div>

      <Teleport to="body">
        <v-slide-x-reverse-transition>
          <div v-if="activeChannel && isMobileView" class="mobile-screen-chat d-flex flex-column w-100 position-relative"
               @dragenter.prevent="handleDragEnter"
               @dragover.prevent="handleDragOver"
               @dragleave.prevent="handleDragLeave"
               @drop.prevent="handleDrop"
          >
            <v-fade-transition>
              <div v-if="isDraggingFile" class="drag-drop-overlay d-flex flex-column align-center justify-center">
                <div class="drag-drop-content d-flex flex-column align-center justify-center rounded-xl elevation-10 pa-8 text-center bg-surface">
                  <v-icon size="80" color="primary" class="mb-4 pulse-anim">mdi-cloud-upload-outline</v-icon>
                  <h2 class="text-h5 font-weight-bold text-high-emphasis mb-2">Solte seus arquivos aqui</h2>
                  <p class="text-medium-emphasis text-body-1">Eles serão adicionados como anexo na conversa.</p>
                </div>
              </div>
            </v-fade-transition>

            <div v-if="loadingChannel" class="h-100 d-flex justify-center align-center bg-surface">
              <v-progress-circular indeterminate color="primary"></v-progress-circular>
            </div>
            <template v-else>
              <ChatHeader
                :channel="activeChannel"
                :online-users="allUsersWithStatus"
                v-model:searchQuery="searchQuery"
                @toggle-repository="showRepository = true"
                @open-info="showMobileProfile = true"
                @back="closeMobileChat"
                :is-mobile="true"
                class="header-elevation"
              />

              <div ref="messagesListMobile" class="messages-area flex-grow-1" @scroll="handleScrollMobile" :style="wallpaperStyle">
                <div v-if="isLoadingMore" class="d-flex justify-center pa-4 mb-2">
                  <v-progress-circular indeterminate color="primary" size="24"></v-progress-circular>
                </div>

                <template v-for="(group, index) in filteredGroupedMessages" :key="index">
                  <div class="date-divider"><span>{{ group.date }}</span></div>
                  <ChatMessage
                    v-for="(message, msgIndex) in group.messages"
                    :key="message.id"
                    :message="message"
                    :is-consecutive="isConsecutiveMessage(message, msgIndex, group.messages)"
                    :search-query="searchQuery"
                    :is-group="!activeChannel.is_private_dm"
                    @show-menu="onShowMenu"
                    @view-media="handleViewMedia"
                    @reply="handleSwipeReply"
                    @scroll-to="scrollToMessage"
                  />
                </template>
              </div>

              <v-scale-transition>
                <v-btn
                  v-show="showScrollButton"
                  icon="mdi-chevron-down"
                  color="surface"
                  elevation="4"
                  class="scroll-bottom-btn mobile-scroll-btn"
                  size="small"
                  @click="scrollToBottom(true, false)"
                ></v-btn>
              </v-scale-transition>

              <div class="input-area bg-surface">
                <div class="preview-area reply-preview" v-if="replyingToMessage">
                  <div class="d-flex align-center w-100 overflow-hidden">
                    <div v-if="replyingToMessage.message_type === 'image' || replyingToMessage.message_type === 'video'" class="reply-preview-thumb mr-3">
                      <img :src="replyingToMessage.content" class="h-100 w-100" style="object-fit: cover; border-radius: 4px;" />
                      <div v-if="replyingToMessage.message_type === 'video'" class="video-overlay-small">
                         <v-icon size="16" color="white">mdi-play</v-icon>
                      </div>
                    </div>
                    <div v-else-if="replyingToMessage.message_type === 'audio'" class="reply-preview-thumb bg-primary-lighten-4 d-flex align-center justify-center mr-3 rounded">
                       <v-icon color="primary" size="20">mdi-microphone</v-icon>
                    </div>
                    <div v-else-if="replyingToMessage.message_type === 'file' || replyingToMessage.message_type === 'document'" class="reply-preview-thumb bg-grey-lighten-2 d-flex align-center justify-center mr-3 rounded">
                       <v-icon color="grey-darken-2" size="20">mdi-file-document</v-icon>
                    </div>

                    <div class="preview-content flex-grow-1 overflow-hidden">
                      <div class="d-flex align-center mb-1">
                        <v-icon size="small" color="primary">mdi-reply</v-icon>
                        <strong class="ml-1 text-primary text-caption">Respondendo a {{ replyingToMessage.profile?.full_name || 'Usuário' }}</strong>
                      </div>
                      <p class="text-caption text-truncate mb-0 text-medium-emphasis">
                         {{ (!replyingToMessage.message_type || replyingToMessage.message_type === 'text') ? replyingToMessage.content : (replyingToMessage.message_type === 'image' ? '📷 Foto' : (replyingToMessage.message_type === 'video' ? '🎥 Vídeo' : (replyingToMessage.message_type === 'audio' ? '🎵 Áudio' : '📄 Arquivo'))) }}
                      </p>
                    </div>
                  </div>
                  <v-btn icon="mdi-close" variant="text" size="small" @click="cancelReply" class="ml-2"></v-btn>
                </div>

                <div class="preview-area edit-preview" v-if="editingMessage">
                  <div class="preview-content">
                    <v-icon size="small" color="warning">mdi-pencil</v-icon>
                    <strong class="ml-2 text-warning">Editando mensagem</strong>
                    <p class="text-caption text-truncate mb-0 text-medium-emphasis">{{ editingMessage.content }}</p>
                  </div>
                  <v-btn icon="mdi-close" variant="text" size="small" @click="cancelEdit"></v-btn>
                </div>

                <div v-if="activeChannel.is_locked && userStore.profile?.role !== 'admin' && userStore.profile?.role !== 'super_admin'" class="d-flex align-center justify-center w-100 pa-3 bg-error-lighten-5 text-error rounded-lg border-error">
                   <v-icon class="mr-2">mdi-lock</v-icon>
                   <span class="font-weight-bold text-caption text-center">A Administração bloqueou temporariamente este chat.</span>
                </div>

                <div v-else class="input-controls d-flex align-center w-100">
                  <input type="file" ref="fileInputMobile" @change="handleFileUpload" multiple style="display: none" />

                  <template v-if="!isRecording">

                    <v-menu v-model="showEmojiPickerMobile" :close-on-content-click="false" location="top start" offset="10">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon="mdi-emoticon-outline" variant="text" class="text-medium-emphasis mr-1" size="small"></v-btn>
                      </template>
                      <v-card width="320" height="350" class="d-flex flex-column emoji-picker-card bg-surface">
                        <div class="emoji-picker-header bg-surface-variant px-3 py-2 d-flex justify-space-between align-center border-b">
                          <span class="text-caption font-weight-bold text-medium-emphasis">Emojis</span>
                          <v-btn icon="mdi-close" variant="text" size="x-small" @click="showEmojiPickerMobile = false"></v-btn>
                        </div>
                        <div class="emoji-categories d-flex px-2 py-1 bg-surface border-b justify-space-between">
                          <v-btn v-for="(cat, idx) in emojiCategories" :key="idx" icon variant="text" size="small" :color="activeEmojiCategory === idx ? 'primary' : 'medium-emphasis'" @click="activeEmojiCategory = idx">
                            <v-icon size="20">{{ cat.icon }}</v-icon>
                          </v-btn>
                        </div>
                        <v-window v-model="activeEmojiCategory" class="flex-grow-1 overflow-hidden">
                          <v-window-item v-for="(cat, idx) in emojiCategories" :key="idx" :value="idx" class="h-100">
                            <div class="emoji-grid pa-2 custom-scroll h-100 overflow-y-auto">
                              <span v-for="emoji in cat.emojis" :key="emoji" class="emoji-item cursor-pointer" @click="insertEmoji(emoji)">
                                {{ emoji }}
                              </span>
                            </div>
                          </v-window-item>
                        </v-window>
                      </v-card>
                    </v-menu>

                    <v-btn icon="mdi-paperclip" variant="text" class="text-medium-emphasis mr-1" size="small" @click="triggerFileInput"></v-btn>

                    <div class="input-field-wrapper flex-grow-1 elevation-1">
                      <v-text-field
                        v-model="newMessage"
                        @keydown.enter.prevent="handleSend"
                        variant="solo"
                        flat
                        placeholder="Mensagem"
                        hide-details
                        density="compact"
                        class="chat-text-field"
                      ></v-text-field>
                    </div>
                  </template>

                  <template v-else>
                    <div class="recording-ui d-flex align-center flex-grow-1 bg-surface py-1 px-3 rounded-pill elevation-2 mr-2">
                      <v-btn icon="mdi-delete" variant="text" color="grey-darken-1" size="small" class="mr-2" @click="cancelRecording"></v-btn>

                      <div class="mic-pulse-wrapper d-flex align-center mr-3">
                        <v-icon color="error" class="pulse-anim mr-2" size="20">mdi-microphone</v-icon>
                        <span class="text-error font-weight-medium text-body-2">{{ recordingTime }}</span>
                      </div>

                      <div class="live-waveform flex-grow-1 d-flex align-center justify-end overflow-hidden">
                        <div class="wave-bar" v-for="(h, i) in recordingWaves" :key="i" :style="{ height: Math.max(h, 15) + '%' }"></div>
                      </div>
                    </div>
                  </template>

                  <div class="action-buttons ml-1">
                    <v-btn v-if="!newMessage.trim() && !isRecording" icon="mdi-microphone" color="primary" variant="flat" elevation="2" size="small" @click="startRecording"></v-btn>
                    <v-btn v-else-if="isRecording" icon="mdi-send" color="success" variant="flat" elevation="2" size="small" class="pulse-send-btn" @click="stopRecordingAndSend"></v-btn>
                    <v-btn v-else icon="mdi-send" color="primary" variant="flat" elevation="2" size="small" @click="handleSend"></v-btn>
                  </div>
                </div>
              </div>

            </template>
          </div>
        </v-slide-x-reverse-transition>
      </Teleport>
    </div>

    <v-dialog v-model="rejectedFilesModal" max-width="450" z-index="999999">
      <v-card class="rounded-xl elevation-10 bg-surface">
        <div class="d-flex flex-column align-center pa-6 text-center">
          <div class="bg-error-lighten-4 rounded-circle pa-4 mb-4 d-flex justify-center align-center">
             <v-icon color="error" size="40">mdi-file-cancel-outline</v-icon>
          </div>
          <h3 class="text-h6 font-weight-bold text-high-emphasis mb-2">Arquivos muito pesados</h3>
          <p class="text-body-2 text-medium-emphasis mb-4">
            O limite máximo para envio é de <strong>200 MB</strong> por arquivo. Os seguintes arquivos excedem esse limite e não poderão ser enviados:
          </p>

          <v-list class="w-100 bg-surface-variant rounded-lg mb-4 text-left" density="compact">
            <v-list-item v-for="(file, idx) in rejectedFilesList" :key="idx" class="px-3">
               <template v-slot:prepend><v-icon color="error" size="small" class="mr-2">mdi-alert-circle</v-icon></template>
               <v-list-item-title class="text-caption font-weight-medium text-truncate text-high-emphasis" :title="file.name">{{ file.name }}</v-list-item-title>
               <template v-slot:append><span class="text-caption font-weight-bold text-error">{{ file.size }}</span></template>
            </v-list-item>
          </v-list>

          <v-btn color="primary" variant="flat" class="w-100 rounded-lg text-button" size="large" @click="rejectedFilesModal = false">
            Entendi
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar.show" :color="snackbar.color" timeout="3000" location="top" class="mt-4">
      <div class="d-flex align-center font-weight-medium">
        <v-icon v-if="snackbar.color === 'error'" size="20" class="mr-2">mdi-alert-circle-outline</v-icon>
        <v-icon v-else size="20" class="mr-2">mdi-check-circle-outline</v-icon>
        {{ snackbar.text }}
      </div>
      <template v-slot:actions>
        <v-btn variant="text" size="small" icon="mdi-close" @click="snackbar.show = false"></v-btn>
      </template>
    </v-snackbar>

    <input type="file" ref="wallpaperInput" @change="handleWallpaperUpload" accept="image/*" style="display: none;" />

    <UploadPreview
      :show="showUploadPreview"
      @update:show="showUploadPreview = $event"
      :files="pendingFiles"
      :is-mobile="isMobileView"
      :is-sending="isUploadingMedia"
      @cancel="cancelUploadPreview"
      @send="handleConfirmUpload"
    />

    <MediaRepository v-model:show="showRepository" :channel="activeChannel" :online-users="allUsersWithStatus" />
    <MessageMenu :show="menu.show" :x="menu.x" :y="menu.y" :is-my-message="menu.isMyMessage" @update:show="menu.show = $event" @action="handleMenuAction" />
    <NewConversationModal ref="newConversationModalRef" @conversation-started="handleConversationStart" @group-created="handleGroupCreated" />
    <ForwardMessageModal v-model="showForwardModal" :message="forwardingMessage" :channels="channels" @forward="executeForward" />

    <ImageModal
      :show="showMediaModal"
      :image-url="mediaModalUrl"
      :file-name="mediaModalFileName"
      @close="showMediaModal = false"
      @forward="handleMediaForward"
    />

    <v-dialog v-if="isMobileView" v-model="showPresenceModal" fullscreen hide-overlay transition="dialog-bottom-transition" style="z-index: 999999;">
      <v-card>
        <v-toolbar color="surface" elevation="2">
          <v-btn icon="mdi-close" @click="showPresenceModal = false"></v-btn>
          <v-toolbar-title class="font-weight-bold">Contatos Internos</v-toolbar-title>
        </v-toolbar>
        <ChatPresence :users="allUsersWithStatus" @start-dm="startDirectMessage" />
      </v-card>
    </v-dialog>

    <v-dialog v-model="showMobileSettings" max-width="320" z-index="999999">
      <v-card class="rounded-xl bg-surface elevation-10">
        <v-card-title class="font-weight-bold px-4 py-3 border-b">Configurações de Chat</v-card-title>
        <v-list density="compact" class="bg-transparent py-0">
          <v-list-item @click="triggerWallpaperUpload(); showMobileSettings = false;" class="px-4 py-3" :disabled="isUploadingWallpaper">
            <template v-slot:prepend><v-icon color="primary" class="mr-3">mdi-image-outline</v-icon></template>
            <v-list-item-title class="text-body-1 font-weight-medium">Alterar Fundo</v-list-item-title>
          </v-list-item>
          <v-list-item v-if="userStore.profile?.chat_wallpaper_url" @click="resetWallpaper(); showMobileSettings = false;" class="px-4 py-3 text-error" :disabled="isUploadingWallpaper">
            <template v-slot:prepend><v-icon color="error" class="mr-3">mdi-delete-outline</v-icon></template>
            <v-list-item-title class="text-body-1 font-weight-medium">Remover Fundo</v-list-item-title>
          </v-list-item>
        </v-list>
        <v-card-actions class="px-4 py-3 justify-end">
          <v-btn variant="text" color="medium-emphasis" class="font-weight-bold" @click="showMobileSettings = false">Fechar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch, computed, reactive, watchEffect } from 'vue';
import { supabase } from '@/api/supabase';
import { useRoute } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { useChatStore } from '@/stores/chat';
import { useOnlineStatusStore } from '@/stores/onlineStatus';
import { storeToRefs } from 'pinia';
import ChatSidebar from './ChatSidebar.vue';
import ChatMessage from './ChatMessage.vue';
import ChatHeader from './ChatHeader.vue';
import ChatPresence from './ChatPresence.vue';
import MediaRepository from './MediaRepository.vue';
import MessageMenu from './MessageMenu.vue';
import NewConversationModal from './NewConversationModal.vue';
import ForwardMessageModal from './ForwardMessageModal.vue';
import ChatProfileInfo from './ChatProfileInfo.vue';
import ImageModal from '@/components/ImageModal.vue';
import UploadPreview from './UploadPreview.vue';
import type { RealtimeChannel } from '@supabase/supabase-js';
import { format, isToday, isYesterday, differenceInMinutes } from 'date-fns';
import { ptBR } from 'date-fns/locale';


const route = useRoute();
const userStore = useUserStore();
const chatStore = useChatStore();
const onlineStatusStore = useOnlineStatusStore();

const isMobileView = ref(window.innerWidth <= 767);
const handleResize = () => { isMobileView.value = window.innerWidth <= 767; };

// Recupera estados atualizados do Pinia
const { channels, activeChannel, messages, hasMoreMessages, isLoadingMore } = storeToRefs(chatStore);
const activeChannelId = ref<number | null>(null);
const newMessage = ref('');
const messagesList = ref<HTMLElement | null>(null);
const messagesListMobile = ref<HTMLElement | null>(null);
const loadingChannel = ref(false);
const fileInputDesktop = ref<HTMLInputElement | null>(null);
const fileInputMobile = ref<HTMLInputElement | null>(null);

const showRepository = ref(false);
const showDesktopInfoPanel = ref(false);
const showMobileProfile = ref(false);
const showPresenceModal = ref(false);
const showMobileSettings = ref(false);

const snackbar = reactive({ show: false, text: '', color: 'error' });
const showAppNotification = (text: string, type: 'error' | 'success' = 'error') => {
  snackbar.text = text;
  snackbar.color = type;
  snackbar.show = true;
};

// ESTADOS E DADOS DO EMOJI PICKER
const showEmojiPickerDesktop = ref(false);
const showEmojiPickerMobile = ref(false);
const activeEmojiCategory = ref(0);

const emojiCategories = [
  {
    name: 'Smileys',
    icon: 'mdi-emoticon-outline',
    emojis: ['😀','😃','😄','😁','😆','😅','😂','🤣','🥲','☺️','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🥸','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🫣','🤭','🤫','🤥','😶','😶‍🌫️','😐','😑','😬','🫨','🫠','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','😵‍💫','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕','🤑','🤠','😈','👿','👹','👺','🤡','💩','👻','💀','☠️','👽','👾','🤖','🎃','😺','😸','😹','😻','😼','😽','🙀','😿','😾']
  },
  {
    name: 'Gestures',
    icon: 'mdi-hand-wave-outline',
    emojis: ['👋','🤚','🖐','✋','🖖','🫱','🫲','🫳','🫴','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','🫶','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🫀','🫁','🧠','🦷','🦴','👀','👁️','👅','👄','💋','🩸']
  },
  {
    name: 'Hearts',
    icon: 'mdi-heart-outline',
    emojis: ['❤️','🩷','🧡','💛','💚','💙','🩵','💜','🖤','🩶','🤍','🤎','💔','❤️‍🔥','❤️‍🩹','❣️','💕','💞','💓','💗','💖','💘','💝','💟']
  },
  {
     name: 'Nature',
     icon: 'mdi-leaf',
     emojis: ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐻‍❄️','🐨','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🪱','🐛','🦋','🐌','🐞','🐜','🪰','🪲','🪳','🦟','🦗','🕷','🦂','🐢','🐍','🦎','🦖','🦕','🐙','🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬','🐳','🐋','🦈','🦭','🐊','🐅','🐆','🦓','🦍','🦧','🦣','🐘','🦛','🦏','🐪','🐫','🦒','🦘','🐃','🐂','🐄','🐎','🐖','🐏','🐑','🦙','🐐','🦌','🐕','🐩','🦮','🐕‍🦺','🐈','🐈‍⬛','🪶','🐓','🦃','🦤','🦚','🦜','🦢','🦩','🕊','🐇','🦝','🦨','🦡','🦫','🦦','🦥','🐁','🐀','🐿','🦔','🐾','🐉','🐲','🌵','🎄','🌲','🌳','🌴','🪵','🌱','🌿','☘️','🍀','🎍','🪴','🎋','🍃','🍂','🍁','🍄','🐚','🪨','🌾','💐','🌷','🌹','🥀','🪷','🌺','🌸','🌼','🌻','🌞','🌝','🌛','🌜','🌚','🌕','🌖','🌗','🌘','🌑','🌒','🌓','🌔','🌙','🌎','🌍','🌏','🪐','💫','⭐️','🌟','✨','⚡️','☄️','💥','🔥','🌪','🌈','☀️','🌤','⛅️','🌥','☁️','🌦','🌧','⛈','🌩','🌨','❄️','☃️','⛄️','🌬','💨','💧','💦','☔️','☂️','🌊','🌫']
  },
  {
     name: 'Food',
     icon: 'mdi-food-apple-outline',
     emojis: ['🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥑','🥦','🥬','🥒','🌶','🫑','🌽','🥕','🫒','🧄','🧅','🥔','🍠','🥐','🥯','🍞','🥖','🥨','🧀','🥚','🍳','🧈','🥞','🧇','🥓','🥩','🍗','🍖','🌭','🍔','🍟','🍕','🫓','🥪','🥙','🧆','🌮','🌯','🫔','🥗','🥘','🫕','🥫','🍝','🍜','🍲','🍛','🍣','🍱','🥟','🦪','🍤','🍙','🍚','🍘','🍥','🥠','🥮','🍢','🍡','🍧','🍨','🍦','🥧','🧁','🍰','🎂','🍮','🍭','🍬','🍫','🍿','🍩','🍪','🌰','🥜','🍯','🥛','🍼','🫖','☕️','🍵','🧃','🥤','🧋','🧯','🍶','🍺','🍻','🥂','🍷','🥃','🍸','🍹','🧉','🍾','🧊','🥄','🍴','🍽','🥣','🥡','🥢','🧂']
  }
];

const insertEmoji = (emoji: string) => {
  newMessage.value += emoji;
};

// ESTADOS DO PREVIEW DE UPLOAD
const showUploadPreview = ref(false);
const pendingFiles = ref<File[]>([]);
const isUploadingMedia = ref(false);

// ESTADOS DE ARQUIVOS REJEITADOS (> 200MB)
const rejectedFilesModal = ref(false);
const rejectedFilesList = ref<{name: string, size: string}[]>([]);

// DRAG AND DROP ESTADOS
const isDraggingFile = ref(false);
let dragCounter = 0;

// CONTROLES DO MODAL DE MÍDIA
const showMediaModal = ref(false);
const mediaModalUrl = ref('');
const mediaModalFileName = ref('');

const newConversationModalRef = ref<any>(null);
const searchQuery = ref('');
const showForwardModal = ref(false);

const allUsersWithStatus = ref<any[]>([]);
let realtimeChannel: RealtimeChannel | null = null;

const menu = reactive({ show: false, x: 0, y: 0, message: null as any | null, isMyMessage: false });
const editingMessage = ref<any | null>(null);
const replyingToMessage = ref<any | null>(null);
const forwardingMessage = ref<any | null>(null);

const showScrollButton = ref(false);

// ==========================================
// DRAG AND DROP (ARRASTAR E SOLTAR ARQUIVOS)
// ==========================================
const handleDragEnter = (e: DragEvent) => {
  e.preventDefault();
  dragCounter++;
  if (e.dataTransfer?.types.includes('Files')) {
    isDraggingFile.value = true;
  }
};

const handleDragOver = (e: DragEvent) => {
  e.preventDefault();
};

const handleDragLeave = (e: DragEvent) => {
  e.preventDefault();
  dragCounter--;
  if (dragCounter === 0) {
    isDraggingFile.value = false;
  }
};

const handleDrop = (e: DragEvent) => {
  e.preventDefault();
  dragCounter = 0;
  isDraggingFile.value = false;

  if (e.dataTransfer && e.dataTransfer.files.length > 0) {
    processFiles(Array.from(e.dataTransfer.files));
  }
};

// ==========================================
// GRAVAÇÃO DE ÁUDIO & WAVEFORM TEMPO REAL
// ==========================================
const isRecording = ref(false);
const mediaRecorder = ref<MediaRecorder | null>(null);
const audioChunks = ref<Blob[]>([]);
const recordingTime = ref('00:00');
let recordingInterval: number;
const cancelCurrentRecording = ref(false);
const recordingWaves = ref<number[]>([]);

let audioContext: AudioContext | null = null;
let analyser: AnalyserNode | null = null;
let microphone: MediaStreamAudioSourceNode | null = null;
let animationFrameId: number;

const startRecording = async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder.value = new MediaRecorder(stream);
    audioChunks.value = [];
    recordingWaves.value = [];
    cancelCurrentRecording.value = false;

    audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    analyser = audioContext.createAnalyser();
    microphone = audioContext.createMediaStreamSource(stream);
    microphone.connect(analyser);
    analyser.fftSize = 256;
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const drawWave = () => {
      if (!isRecording.value) return;
      analyser!.getByteFrequencyData(dataArray);
      let sum = 0;
      for(let i = 0; i < bufferLength; i++) { sum += dataArray[i]; }
      let average = sum / bufferLength;
      let percent = Math.min(100, Math.max(10, (average / 128) * 100));

      recordingWaves.value.push(percent);
      if (recordingWaves.value.length > 35) { recordingWaves.value.shift(); }
      animationFrameId = requestAnimationFrame(drawWave);
    };

    mediaRecorder.value.ondataavailable = event => audioChunks.value.push(event.data);

    mediaRecorder.value.onstop = async () => {
      stream.getTracks().forEach(track => track.stop());
      cancelAnimationFrame(animationFrameId);
      if (audioContext && audioContext.state !== 'closed') { audioContext.close(); }

      if (cancelCurrentRecording.value) {
        cancelCurrentRecording.value = false;
        return;
      }

      const mimeType = MediaRecorder.isTypeSupported('audio/webm') ? 'audio/webm' : 'audio/mp4';
      const audioBlob = new Blob(audioChunks.value, { type: mimeType });
      const ext = mimeType === 'audio/mp4' ? 'mp4' : 'webm';
      const fileName = `audio_${Date.now()}.${ext}`;
      const filePath = `channel_${activeChannelId.value}/${fileName}`;

      const { data, error } = await supabase.storage.from('media').upload(filePath, audioBlob);
      if (!error) {
         const { data: { publicUrl } } = supabase.storage.from('media').getPublicUrl(data.path);
         await sendMessage(publicUrl, 'audio');
      } else {
         showAppNotification('Erro ao enviar áudio. Tente novamente.');
      }
    };

    mediaRecorder.value.start();
    isRecording.value = true;
    let seconds = 0;

    recordingInterval = window.setInterval(() => {
      seconds++;
      const min = Math.floor(seconds / 60).toString().padStart(2, '0');
      const sec = (seconds % 60).toString().padStart(2, '0');
      recordingTime.value = `${min}:${sec}`;
    }, 1000);

    drawWave();
  } catch (err) {
    showAppNotification('Não foi possível acessar o microfone. Verifique as permissões.');
  }
};

const cancelRecording = () => {
  cancelCurrentRecording.value = true;
  if (mediaRecorder.value) mediaRecorder.value.stop();
  resetRecordingState();
};

const stopRecordingAndSend = () => {
  cancelCurrentRecording.value = false;
  if (mediaRecorder.value) mediaRecorder.value.stop();
  resetRecordingState();
};

const resetRecordingState = () => {
  isRecording.value = false;
  window.clearInterval(recordingInterval);
  recordingTime.value = '00:00';
  recordingWaves.value = [];
};

// ==========================================
// UPLOAD E CONTROLE DE PAPEL DE PAREDE
// ==========================================
const wallpaperInput = ref<HTMLInputElement | null>(null);
const isUploadingWallpaper = ref(false);

const wallpaperStyle = computed(() => {
  const url = userStore.profile?.chat_wallpaper_url;
  if (url) {
    return {
      backgroundImage: `url('${url}')`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundAttachment: 'fixed',
      backgroundRepeat: 'no-repeat'
    };
  }
  return {};
});

const triggerWallpaperUpload = () => { if (wallpaperInput.value) wallpaperInput.value.click(); };

const handleWallpaperUpload = async (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file || !userStore.profile?.id) return;

  const MAX_SIZE = 10 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    showAppNotification('A imagem de fundo não pode passar de 10MB.');
    if (target) target.value = '';
    return;
  }

  isUploadingWallpaper.value = true;
  const fileExt = file.name.split('.').pop();
  const fileName = `wallpaper_${Date.now()}.${fileExt}`;
  const filePath = `${userStore.profile.id}/${fileName}`;

  const { error: uploadError } = await supabase.storage.from('wallpapers').upload(filePath, file);

  if (!uploadError) {
    const { data: { publicUrl } } = supabase.storage.from('wallpapers').getPublicUrl(filePath);
    await supabase.from('profiles').update({ chat_wallpaper_url: publicUrl }).eq('id', userStore.profile.id);
    userStore.profile.chat_wallpaper_url = publicUrl;
    showAppNotification('Fundo alterado com sucesso!', 'success');
  } else {
    showAppNotification('Erro ao fazer upload do fundo.');
  }

  isUploadingWallpaper.value = false;
  if (target) target.value = '';
};

const resetWallpaper = async () => {
  if (!userStore.profile?.id) return;
  isUploadingWallpaper.value = true;
  await supabase.from('profiles').update({ chat_wallpaper_url: null }).eq('id', userStore.profile.id);
  userStore.profile.chat_wallpaper_url = null;
  isUploadingWallpaper.value = false;
  showAppNotification('Fundo removido.', 'success');
};

const handleViewMedia = ({ url, fileName }: { url: string, fileName: string }) => {
  mediaModalUrl.value = url;
  mediaModalFileName.value = fileName;
  showMediaModal.value = true;
};

const handleScroll = async () => {
  if (!messagesList.value) return;
  const { scrollTop, scrollHeight, clientHeight } = messagesList.value;
  showScrollButton.value = scrollTop + clientHeight < scrollHeight - 100;

  if (scrollTop < 50 && hasMoreMessages.value && !isLoadingMore.value && activeChannelId.value) {
    const oldScrollHeight = scrollHeight;
    await chatStore.loadMoreMessages(activeChannelId.value);
    nextTick(() => {
      if (messagesList.value) {
        messagesList.value.scrollTop = messagesList.value.scrollHeight - oldScrollHeight;
      }
    });
  }
};

const handleScrollMobile = async () => {
  if (!messagesListMobile.value) return;
  const { scrollTop, scrollHeight, clientHeight } = messagesListMobile.value;
  showScrollButton.value = scrollTop + clientHeight < scrollHeight - 100;

  if (scrollTop < 50 && hasMoreMessages.value && !isLoadingMore.value && activeChannelId.value) {
    const oldScrollHeight = scrollHeight;
    await chatStore.loadMoreMessages(activeChannelId.value);
    nextTick(() => {
      if (messagesListMobile.value) {
        messagesListMobile.value.scrollTop = messagesListMobile.value.scrollHeight - oldScrollHeight;
      }
    });
  }
};

const scrollToBottom = (force = false, instant = false) => {
  nextTick(() => {
    const list = isMobileView.value ? messagesListMobile.value : messagesList.value;
    if (list) {
      if (force || !showScrollButton.value) {
        list.scrollTo({
          top: list.scrollHeight,
          behavior: instant ? 'auto' : 'smooth'
        });
        showScrollButton.value = false;
      }
    }
  });
};

const closeMobileChat = () => {
  activeChannelId.value = null;
  chatStore.activeChannel = null;
  showMobileProfile.value = false;
};

const openNewChatModal = (mode: string) => {
  if (newConversationModalRef.value) {
    newConversationModalRef.value.open();
  }
};

const handleProfileInfoAction = async (action: string) => {
  if (!activeChannel.value) return;
  switch (action) {
    case 'mute':
    case 'pin':
    case 'delete':
    case 'leave':
      await handleChannelAction({ action: action === 'leave' ? 'delete' : action as any, channel: activeChannel.value });
      if (action === 'delete' || action === 'leave') closeMobileChat();
      break;
    case 'search':
      showDesktopInfoPanel.value = false;
      showMobileProfile.value = false;
      break;
  }
};

const handleChannelAction = async ({ action, channel }: { action: 'pin' | 'mute' | 'delete', channel: any }) => {
  const userId = userStore.profile?.id;
  if (!userId) return;

  switch (action) {
    case 'pin': await chatStore.togglePinChannel(channel, userId); break;
    case 'mute': await chatStore.toggleMuteChannel(channel, userId); break;
    case 'delete':
      if (confirm(`Sair e excluir a conversa "${channel.name}"?`)) {
        await chatStore.deleteChannel(channel.id, userId);
        if (activeChannelId.value === channel.id) {
          activeChannelId.value = null;
          chatStore.activeChannel = null;
          showDesktopInfoPanel.value = false;
        }
      }
      break;
  }
};

const setActiveChannel = async (channelId: number) => {
  if (activeChannelId.value === channelId && activeChannel.value) return;
  if (!channelId) { closeMobileChat(); return; }

  activeChannelId.value = channelId;
  loadingChannel.value = true;
  await chatStore.setActiveChannel(channelId);
  loadingChannel.value = false;

  showRepository.value = false;
  showDesktopInfoPanel.value = false;
  showMobileProfile.value = false;
  searchQuery.value = '';
  await supabase.rpc('update_last_read', { p_channel_id: channelId });
  if (userStore.profile?.id) await chatStore.fetchChannels(userStore.profile.id);
  showPresenceModal.value = false;

  scrollToBottom(true, true);
};

const startDirectMessage = async (user: any) => {
  if (!userStore.profile) return;
  const { data, error } = await supabase.rpc('find_or_create_dm_channel', { p_user1_id: userStore.profile.id, p_user2_id: user.id });
  if (!error) {
    await chatStore.fetchChannels(userStore.profile.id);
    await setActiveChannel(data);
  }
  showPresenceModal.value = false;
};

const filteredGroupedMessages = computed(() => {
    let items = messages.value || [];

    const myId = userStore.profile?.id;
    const myRole = userStore.profile?.role;
    const isAdmin = myRole === 'admin' || myRole === 'super_admin';

    items = items.filter(msg => {
        if (!msg.target_users || msg.target_users.length === 0) return true;
        if (msg.profile_id === myId) return true;
        if (isAdmin) return true;
        if (msg.target_users.includes(myId)) return true;
        return false;
    });

    if (searchQuery.value) {
        items = items.filter(msg => msg.content && msg.content.toLowerCase().includes(searchQuery.value.toLowerCase()));
    }
    if (!items.length) return [];

    const groups: { date: string; messages: any[] }[] = [];
    let lastDate = '';

    items.forEach(msg => {
        const date = new Date(msg.created_at);
        let formattedDate: string;
        if (isToday(date)) formattedDate = 'Hoje';
        else if (isYesterday(date)) formattedDate = 'Ontem';
        else formattedDate = format(date, "d 'de' MMMM", { locale: ptBR });

        if (formattedDate !== lastDate) {
            groups.push({ date: formattedDate, messages: [] });
            lastDate = formattedDate;
        }
        groups[groups.length - 1].messages.push(msg);
    });
    return groups;
});

const isConsecutiveMessage = (message: any, index: number, group: any[]) => {
    if (index === 0) return false;
    const prevMessage = group[index - 1];
    const timeDiff = differenceInMinutes(new Date(message.created_at), new Date(prevMessage.created_at));
    return prevMessage.profile_id === message.profile_id && timeDiff < 5 && prevMessage.message_type !== 'system' && message.message_type !== 'system';
};

const cancelEdit = () => { editingMessage.value = null; newMessage.value = ''; };
const cancelReply = () => { replyingToMessage.value = null; };

const handleSwipeReply = (message: any) => {
    cancelEdit();
    replyingToMessage.value = message;
};

const scrollToMessage = (msgId: string | number) => {
    const el = document.getElementById(`msg-${msgId}`);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        el.classList.add('highlight-pulse');
        setTimeout(() => {
            el.classList.remove('highlight-pulse');
        }, 2000);
    } else {
        showAppNotification('A mensagem original não está carregada na tela.', 'warning');
    }
};

const handleSend = () => {
    if (editingMessage.value) updateMessage();
    else sendMessage();
};

const updateMessage = async () => {
    if (!editingMessage.value || !newMessage.value.trim()) return;
    await supabase.from('messages').update({ content: newMessage.value }).eq('id', editingMessage.value.id);
    cancelEdit();
};

const sendMessage = async (contentOverride: any = null, messageType: string = 'text', mediaCaption: string | null = null) => {
  if (!activeChannelId.value || !userStore.profile) return;
  const content = contentOverride || newMessage.value.trim();
  if (!content) return;

  const replyId = replyingToMessage.value?.id || null;

  if (messageType === 'text') {
    await chatStore.sendMessage(content, activeChannelId.value, userStore.profile.id, replyId);
    newMessage.value = '';
    cancelReply();
  } else {
    const { error } = await supabase.from('messages').insert({
      content: content,
      channel_id: activeChannelId.value,
      profile_id: userStore.profile.id,
      reply_to_message_id: replyId,
      message_type: messageType,
      caption: mediaCaption
    });
    if (error) {
      console.error('Erro ao salvar mídia:', error);
      showAppNotification('Erro ao enviar mídia.');
    } else {
      cancelReply();
    }
  }

  scrollToBottom(true, false);
};

// ==========================================
// NOVA LÓGICA DE UPLOAD CENTRALIZADA (ACEITA DRAG E CLIQUE)
// ==========================================
const triggerFileInput = () => {
  if (isMobileView.value && fileInputMobile.value) fileInputMobile.value.click();
  else if (!isMobileView.value && fileInputDesktop.value) fileInputDesktop.value.click();
};

const handleFileUpload = (event: Event) => {
    const target = event.target as HTMLInputElement;
    if (!target.files || target.files.length === 0) return;
    processFiles(Array.from(target.files));
    if (target) target.value = '';
};

// Função unificada para Drag 'n Drop e Clique no Clip
const processFiles = (filesArray: File[]) => {
    if (!activeChannelId.value) return;

    const MAX_SIZE = 200 * 1024 * 1024; // 200 MB em Bytes
    const validFiles: File[] = [];
    const invalidFiles: {name: string, size: string}[] = [];

    for (const file of filesArray) {
        if (file.size > MAX_SIZE) {
            const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
            invalidFiles.push({ name: file.name, size: `${sizeMB} MB` });
        } else {
            validFiles.push(file);
        }
    }

    if (invalidFiles.length > 0) {
        rejectedFilesList.value = invalidFiles;
        rejectedFilesModal.value = true;
    }

    if (validFiles.length > 0) {
        pendingFiles.value = validFiles;
        showUploadPreview.value = true;
    }
};

const cancelUploadPreview = () => {
    pendingFiles.value = [];
    showUploadPreview.value = false;
};

const handleConfirmUpload = async ({ files, caption }: { files: File[], caption: string }) => {
    if (!activeChannelId.value || !userStore.profile) return;
    isUploadingMedia.value = true;

    try {
        let isFirst = true;
        for (const file of files) {
            const sanitizedFileName = file.name.replace(/[^\w.\-]/g, '_');
            const fileName = `${Date.now()}_${sanitizedFileName}`;
            const filePath = `channel_${activeChannelId.value}/${fileName}`;

            const { data, error } = await supabase.storage.from('media').upload(filePath, file);

            if (error) {
                showAppNotification(`Erro ao enviar ${file.name}`);
                continue;
            }

            const { data: { publicUrl } } = supabase.storage.from('media').getPublicUrl(data.path);
            let messageType = 'file';
            if (file.type.startsWith('image/')) messageType = 'image';
            if (file.type.startsWith('audio/')) messageType = 'audio';
            if (file.type.startsWith('video/')) messageType = 'video';

            const fileCaption = isFirst && caption && caption.trim() ? caption.trim() : null;
            await sendMessage(publicUrl, messageType, fileCaption);
            isFirst = false;
        }

        showUploadPreview.value = false;
        pendingFiles.value = [];
    } catch(e) {
        showAppNotification('Ocorreu um erro inesperado ao enviar arquivos.');
    } finally {
        isUploadingMedia.value = false;
        scrollToBottom(true, false);
    }
};

const onShowMenu = ({ event, message }: { event: MouseEvent, message: any }) => {
    menu.show = true; menu.x = event.clientX; menu.y = event.clientY; menu.message = message;
    menu.isMyMessage = message.profile_id === userStore.profile?.id;
};

const handleMenuAction = async (action: string) => {
    if (!menu.message) return;
    const message = menu.message;
    menu.show = false;

    switch(action) {
        case 'delete':
            if (confirm('Tem certeza que deseja excluir esta mensagem?')) {
                await supabase.from('messages').update({ is_deleted: true, content: 'Mensagem excluída' }).eq('id', message.id);
            }
            break;
        case 'edit':
            cancelReply();
            editingMessage.value = message;
            newMessage.value = message.content;
            break;
        case 'reply':
            handleSwipeReply(message);
            break;
        case 'forward':
            forwardingMessage.value = message;
            showForwardModal.value = true;
            break;
    }
};

const executeForward = async ({ channels: channelIds, message }: { channels: number[], message: any}) => {
    if (!message || channelIds.length === 0 || !userStore.profile) return;
    for (const channelId of channelIds) {
        await supabase.from('messages').insert({
            content: message.content,
            channel_id: channelId,
            profile_id: userStore.profile.id,
            message_type: message.message_type
        });
    }
    showForwardModal.value = false;
    showAppNotification('Mensagem encaminhada com sucesso.', 'success');
    scrollToBottom(true, false);
};

const handleMediaForward = (media: { url: string, type: string, name: string }) => {
    forwardingMessage.value = {
        content: media.url,
        message_type: media.type
    };
    showMediaModal.value = false;
    showForwardModal.value = true;
};

const handleConversationStart = async (channelId: number) => {
  if (userStore.profile?.id) await chatStore.fetchChannels(userStore.profile.id);
  await setActiveChannel(channelId);
};

const handleGroupCreated = async (newChannel: any) => {
  if (userStore.profile?.id) await chatStore.fetchChannels(userStore.profile.id);
  await setActiveChannel(newChannel.id);
};

const fetchAllUsersWithStatus = async () => {
  if (!userStore.profile?.id) return;
  const { data, error } = await supabase.rpc('get_all_users_with_status', { p_exclude_user_id: userStore.profile.id });
  if (!error) allUsersWithStatus.value = data || [];
};

watchEffect(() => {
    if (!allUsersWithStatus.value.length) return;
    const onlineUsersMap = new Map(onlineStatusStore.onlineUsers.map(p => [p.user_id, p.status]));
    allUsersWithStatus.value = allUsersWithStatus.value.map(user => ({
        ...user,
        status: onlineUsersMap.get(user.id) || user.status || 'offline'
    })).sort((a, b) => {
      const statusOrder = { online: 1, away: 2, offline: 3 };
      return (statusOrder[a.status as keyof typeof statusOrder] || 3) - (statusOrder[b.status as keyof typeof statusOrder] || 3);
    });
});

watch(messages, (newMessages, oldMessages) => {
    if (oldMessages && newMessages && newMessages.length > oldMessages.length) {
       if (newMessages[newMessages.length - 1].id !== oldMessages[oldMessages.length - 1]?.id) {
          scrollToBottom(false, false);
       }
    }

    if (newMessages && newMessages.length > 0 && activeChannel.value) {
        const lastMsg = newMessages[newMessages.length - 1];
        if (lastMsg.message_type === 'admin') {
            if (lastMsg.content.includes('BLOQUEOU')) activeChannel.value.is_locked = true;
            if (lastMsg.content.includes('DESBLOQUEOU')) activeChannel.value.is_locked = false;
        }
    }
}, { deep: true });

onMounted(async () => {
  window.addEventListener('resize', handleResize);
  if (userStore.profile?.id) {
    await chatStore.fetchChannels(userStore.profile.id);
    await fetchAllUsersWithStatus();

    // 👇 NOVA LÓGICA DE VERIFICAÇÃO DE URL 👇
    if (route.query.channel) {
      const chId = parseInt(route.query.channel as string);
      if (!isNaN(chId)) {
        await setActiveChannel(chId);
      }
    }
  }
});
onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  if (realtimeChannel) supabase.removeChannel(realtimeChannel);
  if (recordingInterval) window.clearInterval(recordingInterval);
});
</script>

<style lang="scss" scoped>
/* ========================================= */
/* ESTRUTURA GERAL E UPGRADE DE LIGHT MODE   */
/* ========================================= */
.app-chat-container {
  width: 100%;
  height: calc(100vh - 64px);
  overflow: hidden;
  background-color: rgb(var(--v-theme-background));
}

.desktop-layout {
  display: flex;
  flex-direction: row;
  height: 100%;
  width: 100%;

  .col-1-nav {
    background-color: #f4f5f7;
    border-right: 1px solid rgba(0, 0, 0, 0.08);
  }

  .col-2-list {
    background-color: rgb(var(--v-theme-surface));
    border-right: 1px solid rgba(0, 0, 0, 0.06);
    box-shadow: 2px 0 12px rgba(0,0,0,0.03);
    z-index: 5;
  }

  .col-4-info, .col-5-contacts {
    border-left: 1px solid rgba(0, 0, 0, 0.06);
    box-shadow: -2px 0 12px rgba(0,0,0,0.03);
  }
}

.col-1-nav { width: 72px; display: flex; flex-direction: column; justify-content: space-between; align-items: center; padding: 16px 0; flex-shrink: 0; z-index: 10; }
.nav-top, .nav-bottom { display: flex; flex-direction: column; align-items: center; }
.col-2-list { width: 380px; display: flex; flex-direction: column; flex-shrink: 0; }
.col-3-chat { flex: 1; display: flex; flex-direction: column; background-color: rgb(var(--v-theme-background)); position: relative; min-width: 0; min-height: 0;}
.col-4-info { width: 380px; display: flex; flex-direction: column; flex-shrink: 0; z-index: 6; }
.transition-all { transition: width 0.3s ease, flex 0.3s ease; }

.header-elevation {
  box-shadow: 0 2px 10px rgba(0,0,0,0.04);
  z-index: 10;
}

@media (prefers-color-scheme: dark) {
  .desktop-layout .col-1-nav { background-color: rgb(var(--v-theme-surface)); }
}

/* ========================================= */
/* DRAG AND DROP OVERLAY STYLING             */
/* ========================================= */
.drag-drop-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: rgba(var(--v-theme-background), 0.75);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(5px);
  z-index: 100; /* Fica acima das mensagens, mas abaixo do preview se abrir */
  pointer-events: none; /* Deixa o evento passar pro <main> pai */
}

.drag-drop-content {
  border: 3px dashed rgb(var(--v-theme-primary));
  max-width: 450px;
  width: 90%;
  box-shadow: 0 10px 30px rgba(0,0,0,0.15) !important;
}

/* ========================================= */
/* GAVETA DE CONTATOS (DESKTOP)              */
/* ========================================= */
.col-5-contacts {
  width: 76px;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  z-index: 7;
  overflow: hidden;
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.3s ease;

  &:hover {
    width: 280px;
    box-shadow: -8px 0 20px rgba(0,0,0,0.08);
  }

  .contacts-header {
    height: 60px;
    white-space: nowrap;
    border-bottom: 1px solid rgba(128, 128, 128, 0.15);
    background-color: rgba(var(--v-theme-surface-variant), 0.3);

    .icon-wrapper { width: 76px; }
    .header-title { opacity: 0; transition: opacity 0.2s ease; letter-spacing: 0.5px; }
  }

  &:hover .contacts-header .header-title { opacity: 1; }

  .contact-item {
    white-space: nowrap;
    transition: background-color 0.2s ease;

    .avatar-wrapper { width: 56px; }
    .contact-info { opacity: 0; transition: opacity 0.2s ease; }
  }

  &:hover .contact-info { opacity: 1; }

  .contacts-list {
    overflow-x: hidden;
    &::-webkit-scrollbar { width: 4px; }
    &::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 4px; }
  }
}

.hover-effect:hover { background-color: rgba(var(--v-theme-primary), 0.05) !important; }
.border-bottom { border-bottom: 1px solid rgba(128, 128, 128, 0.08); }
.tracking-wide { letter-spacing: 0.05em; }

/* ========================================= */
/* MOBILE LAYOUT                             */
/* ========================================= */
.mobile-layout { display: flex; flex-direction: column; width: 100%; height: 100%; overflow: hidden; }
.mobile-screen-chat { position: fixed !important; top: 0 !important; left: 0 !important; right: 0 !important; bottom: 0 !important; height: 100dvh !important; width: 100vw !important; z-index: 999999 !important; background-color: rgb(var(--v-theme-background)); overflow: hidden; min-height: 0;}
.mobile-fab { position: absolute; bottom: 24px; right: 24px; z-index: 100; }
.mobile-contacts-fab { position: absolute; bottom: 96px; right: 24px; z-index: 100; background-color: rgb(var(--v-theme-surface)) !important; color: rgb(var(--v-theme-primary)) !important; }
.mobile-settings-fab { position: absolute; bottom: 168px; right: 24px; z-index: 100; color: rgb(var(--v-theme-medium-emphasis)) !important; }

/* ========================================= */
/* TEXTURA DE FUNDO E ÁREA DE MENSAGENS      */
/* ========================================= */
.messages-area {
  flex: 1 1 0;
  min-height: 0;
  overflow-y: auto;
  padding: 16px 5%;
  display: flex;
  flex-direction: column;
  background-color: #efeae2;
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");

  @media (max-width: 768px) { padding: 12px 16px; }
}

@media (prefers-color-scheme: dark) {
  .messages-area {
    background-color: #0b141a;
    background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.03'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
  }
}

.messages-area::-webkit-scrollbar { width: 6px; }
.messages-area::-webkit-scrollbar-thumb { background-color: rgba(128, 128, 128, 0.3); border-radius: 4px; }

.date-divider {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 16px 0;
  z-index: 2;
}

.date-divider span {
  padding: 6px 16px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.02em;
  text-transform: uppercase;

  background-color: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  color: rgba(0, 0, 0, 0.7);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 0 0 1px rgba(255, 255, 255, 0.4) inset;
}

@media (prefers-color-scheme: dark) {
  .date-divider span {
    background-color: rgba(30, 41, 59, 0.75);
    color: rgba(255, 255, 255, 0.9);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05) inset;
  }
}

.scroll-bottom-btn { position: absolute; bottom: 80px; right: 24px; z-index: 10; opacity: 0.9; }
.mobile-scroll-btn { bottom: 70px; right: 16px; }

/* ========================================= */
/* ÁREA DE INPUT COM PROFUNDIDADE E PREVIEW  */
/* ========================================= */
.input-area {
  height: auto;
  min-height: 62px;
  display: flex;
  flex-direction: column;
  padding: 8px 16px;
  flex-shrink: 0;
  padding-bottom: calc(8px + env(safe-area-inset-bottom));
  z-index: 5;
  background-color: rgb(var(--v-theme-surface));

  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.05);
  border-top: 1px solid rgba(0, 0, 0, 0.03);
}

@media (prefers-color-scheme: dark) {
  .input-area { box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.2); border-top: 1px solid rgba(255, 255, 255, 0.05); }
}

.input-controls { display: flex; align-items: center; }
.input-field-wrapper {
  background-color: rgba(128, 128, 128, 0.06);
  border-radius: 24px;
  padding: 4px 16px;
  display: flex;
  align-items: center;
  min-height: 44px;
}
.chat-text-field :deep(.v-field) { background: transparent !important; box-shadow: none !important; }
.chat-text-field :deep(.v-field__input) { padding: 8px 0 !important; min-height: auto !important; }

/* REVISÃO DO PREVIEW */
.preview-area { display: flex; justify-content: space-between; align-items: center; padding: 8px 12px; background-color: rgba(128, 128, 128, 0.05); border-radius: 8px 8px 0 0; margin-bottom: 8px; border-left: 4px solid; }
.reply-preview { border-left-color: rgb(var(--v-theme-primary)); }
.edit-preview { border-left-color: rgb(var(--v-theme-warning)); }

.reply-preview-thumb { width: 40px; height: 40px; flex-shrink: 0; position: relative; }
.video-overlay-small { position: absolute; top:0; left:0; right:0; bottom:0; display:flex; align-items:center; justify-content:center; background:rgba(0,0,0,0.3); border-radius:4px; }


/* Gravação de Áudio Visuals */
.recording-ui { min-height: 44px; }
.pulse-anim { animation: pulse 1.5s infinite ease-in-out; }
@keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(1.1); } 100% { opacity: 1; transform: scale(1); } }

.live-waveform { height: 24px; gap: 2px; }
.wave-bar { width: 3px; background-color: rgb(var(--v-theme-primary)); border-radius: 2px; transition: height 0.1s ease; }

.pulse-send-btn { animation: gentleBounce 2s infinite ease-in-out; }
@keyframes gentleBounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-3px); } }

/* Animação para destacar a mensagem clicada */
@keyframes highlightPulse {
  0% { background-color: rgba(var(--v-theme-primary), 0.3); }
  100% { background-color: transparent; }
}

:deep(.highlight-pulse) {
  animation: highlightPulse 2s ease-out;
  border-radius: 8px;
}

.chat-wrapper {
  min-height: 0; /* ⬅️ Adicione para evitar que o wrapper cresça infinitamente */
}

/* ========================================= */
/* EMOJI PICKER ESTILOS                      */
/* ========================================= */
.emoji-picker-card {
  border-radius: 12px !important;
  box-shadow: 0 10px 30px rgba(0,0,0,0.15) !important;
  overflow: hidden;
}

.emoji-grid {
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  gap: 4px;
  align-content: start;
}

.emoji-item {
  font-size: 24px;
  text-align: center;
  padding: 4px;
  border-radius: 8px;
  transition: background-color 0.2s, transform 0.1s;
  user-select: none;
}

.emoji-item:hover {
  background-color: rgba(var(--v-theme-primary), 0.1);
  transform: scale(1.1);
}

</style>

<style>
body .v-overlay-container .v-overlay,
body .v-dialog,
body .v-navigation-drawer,
body .v-overlay--active { z-index: 9999999 !important; }
</style>
