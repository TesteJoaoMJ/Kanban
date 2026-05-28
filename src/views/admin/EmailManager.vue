<template>
  <section class="mail-app" :class="isDark ? 'theme-dark' : 'theme-light'">
    <header class="app-header">
      <div class="app-header__left">
        <div class="app-logo">
          <v-icon size="20">mdi-email-outline</v-icon>
        </div>
        <div class="app-title-group">
          <h1>Mail</h1>
          <p>Comunicação corporativa</p>
        </div>
      </div>

      <div class="app-header__center" v-if="isConnected && viewMode === 'inbox'">
        <v-text-field
          v-model="searchQuery"
          prepend-inner-icon="mdi-magnify"
          variant="solo-filled"
          density="comfortable"
          flat
          hide-details
          placeholder="Pesquisar nesta pasta"
          class="global-search"
        />
      </div>

      <div class="app-header__right">
        <v-btn
          v-if="isConnected && viewMode === 'inbox'"
          color="primary"
          variant="flat"
          class="text-none"
          prepend-icon="mdi-pencil"
          @click="openCompose"
        >
          Escrever
        </v-btn>

        <v-btn
          v-if="isConnected && viewMode === 'inbox'"
          variant="text"
          icon="mdi-refresh"
          :loading="isLoadingEmails"
          @click="fetchRealEmails(false)"
        >
          <v-tooltip activator="parent" location="bottom">Atualizar</v-tooltip>
        </v-btn>

        <v-btn
          variant="outlined"
          class="text-none"
          prepend-icon="mdi-account-circle-outline"
          @click="openAccountsModal"
        >
          Contas
        </v-btn>
      </div>
    </header>

    <div v-if="isLoadingAuth" class="state-panel state-panel--page">
      <v-progress-circular indeterminate color="primary" size="44" width="4" />
      <h2>Carregando e-mail</h2>
      <p>Validando autenticação e conexões disponíveis.</p>
    </div>

    <template v-else>
      <section v-if="!isConnected || viewMode === 'hub'" class="setup-screen custom-scrollbar">
        <div class="setup-shell">
          <div class="setup-hero">
            <div>
              <div class="section-kicker">Integrações</div>
              <h2>E-mail corporativo</h2>
              <p>
                Conecte sua conta para centralizar leitura, resposta e composição de mensagens dentro do ERP.
              </p>
            </div>

            <div class="setup-status">
              <div class="status-card">
                <span>Status</span>
                <strong>{{ hasGmailConnected ? 'Conectado' : 'Não conectado' }}</strong>
                <small>{{ syncedEmailAddress || 'Nenhuma conta ativa' }}</small>
              </div>
              <div class="status-card">
                <span>Provedor</span>
                <strong>Google Workspace</strong>
                <small>Gmail API</small>
              </div>
            </div>
          </div>

          <div class="provider-grid">
            <article class="provider-card provider-card--active">
              <div class="provider-card__main">
                <div class="provider-icon provider-icon--google">
                  <v-icon size="22">mdi-google</v-icon>
                </div>

                <div class="provider-copy">
                  <div class="provider-row">
                    <h3>Google Workspace</h3>
                    <v-chip size="small" :color="hasGmailConnected ? 'success' : 'default'" variant="tonal">
                      {{ hasGmailConnected ? 'Conectado' : 'Disponível' }}
                    </v-chip>
                  </div>

                  <p>
                    Leitura da caixa, envio de mensagens, resposta e paginação contínua de e-mails antigos.
                  </p>

                  <div class="provider-meta">
                    <span>Conta</span>
                    <strong>{{ syncedEmailAddress || 'Não sincronizada' }}</strong>
                  </div>
                </div>
              </div>

              <div class="provider-actions">
                <v-btn
                  v-if="hasGmailConnected"
                  color="primary"
                  variant="flat"
                  class="text-none"
                  @click="viewMode = 'inbox'"
                >
                  Abrir caixa postal
                </v-btn>
                <v-btn
                  v-else
                  color="primary"
                  variant="flat"
                  class="text-none"
                  @click="selectProvider('gmail')"
                >
                  Conectar conta
                </v-btn>
                <v-btn variant="outlined" class="text-none" @click="openAccountsModal">Gerenciar acesso</v-btn>
              </div>
            </article>

            <article class="provider-card provider-card--muted">
              <div class="provider-card__main">
                <div class="provider-icon provider-icon--outlook">
                  <v-icon size="22">mdi-microsoft-outlook</v-icon>
                </div>

                <div class="provider-copy">
                  <div class="provider-row">
                    <h3>Microsoft 365</h3>
                    <v-chip size="small" variant="tonal">Planejado</v-chip>
                  </div>
                  <p>Estrutura preparada para futura integração com Microsoft Graph.</p>
                </div>
              </div>

              <div class="provider-actions">
                <v-btn variant="outlined" class="text-none" disabled>Em breve</v-btn>
              </div>
            </article>
          </div>
        </div>
      </section>

      <section v-else class="workspace">
        <aside class="nav-pane">
          <div class="nav-pane__top">
            <v-btn
              color="primary"
              variant="flat"
              block
              class="text-none"
              prepend-icon="mdi-pencil"
              @click="openCompose"
            >
              Escrever
            </v-btn>
          </div>

          <div class="nav-section">
            <div class="nav-section__title">Pastas</div>
            <button
              v-for="folder in primaryFolders"
              :key="folder.id"
              type="button"
              class="nav-item"
              :class="{ 'nav-item--active': activeFolder === folder.id }"
              @click="changeFolder(folder.id)"
            >
              <span class="nav-item__left">
                <v-icon size="18">{{ folder.icon }}</v-icon>
                <span>{{ folder.label }}</span>
              </span>
              <small>{{ folder.shortcut }}</small>
            </button>
          </div>

          <div class="nav-section nav-section--meta">
            <div class="nav-section__title">Sessão</div>
            <div class="account-card">
              <div class="account-card__row">
                <span>Conta ativa</span>
                <strong :title="syncedEmailAddress">{{ syncedEmailAddress || 'Sincronizando...' }}</strong>
              </div>
              <div class="account-card__row">
                <span>Pasta atual</span>
                <strong>{{ currentFolderLabel }}</strong>
              </div>
              <div class="account-card__row">
                <span>Resultados</span>
                <strong>{{ realEmails.length }}</strong>
              </div>
            </div>
          </div>

          <div class="nav-pane__bottom">
            <v-btn variant="text" class="text-none justify-start" prepend-icon="mdi-connection" @click="viewMode = 'hub'">
              Integrações
            </v-btn>
            <v-btn variant="text" class="text-none justify-start" prepend-icon="mdi-account-circle-outline" @click="openAccountsModal">
              Contas conectadas
            </v-btn>
          </div>
        </aside>

        <section class="list-pane">
          <header class="list-pane__header">
            <div>
              <h2>{{ currentFolderLabel }}</h2>
              <p>{{ listStatusText }}</p>
            </div>
          </header>

          <div v-if="isLoadingEmails && !isPaginating" class="state-panel state-panel--embedded">
            <v-progress-circular indeterminate color="primary" size="36" width="4" />
            <h3>Carregando mensagens</h3>
            <p>Buscando e-mails da pasta selecionada.</p>
          </div>

          <div v-else-if="realEmails.length === 0" class="state-panel state-panel--embedded">
            <v-icon size="42">mdi-email-outline</v-icon>
            <h3>Nenhuma mensagem encontrada</h3>
            <p>Não há resultados para esta pasta ou para a busca atual.</p>
          </div>

          <div v-else class="mail-list custom-scrollbar">
            <button
              v-for="email in realEmails"
              :key="email.id"
              type="button"
              class="mail-item"
              :class="{
                'mail-item--active': selectedEmail?.id === email.id,
                'mail-item--unread': !email.isRead,
              }"
              @click="viewEmail(email)"
            >
              <div class="mail-item__avatar">{{ getSenderInitial(email) }}</div>
              <div class="mail-item__body">
                <div class="mail-item__top">
                  <strong>{{ email.fromName || email.fromEmail || 'Remetente desconhecido' }}</strong>
                  <span>{{ email.dateFormatted }}</span>
                </div>
                <div class="mail-item__subject">{{ email.subject || '(Sem assunto)' }}</div>
                <div class="mail-item__snippet">{{ email.snippet || 'Sem prévia disponível.' }}</div>
              </div>
            </button>

            <div class="mail-list__footer">
              <v-btn
                v-if="nextPageToken"
                color="primary"
                variant="text"
                class="text-none"
                :loading="isPaginating"
                @click="fetchRealEmails(true)"
              >
                Carregar mensagens antigas
              </v-btn>
              <span v-else>Fim da lista disponível nesta pasta.</span>
            </div>
          </div>
        </section>

        <section class="reader-pane">
          <div v-if="!selectedEmail" class="state-panel state-panel--embedded reader-empty">
            <v-icon size="56">mdi-email-open-outline</v-icon>
            <h3>Selecione uma mensagem</h3>
            <p>Abra um e-mail da lista para visualizar o conteúdo e responder.</p>
          </div>

          <template v-else>
            <header class="reader-pane__header">
              <div class="reader-title-block">
                <h2>{{ selectedEmail.subject || '(Sem assunto)' }}</h2>

                <div class="sender-block">
                  <div class="sender-block__avatar">{{ getSenderInitial(selectedEmail) }}</div>
                  <div class="sender-block__meta">
                    <strong>{{ selectedEmail.fromName || selectedEmail.fromEmail }}</strong>
                    <span>{{ selectedEmail.fromEmail || 'sem e-mail' }}</span>
                  </div>
                </div>
              </div>

              <div class="reader-actions">
                <div class="reader-date">{{ selectedEmail.dateFull }}</div>
                <div class="reader-actions__buttons">
                  <v-btn color="primary" variant="flat" class="text-none" prepend-icon="mdi-reply" @click="handleReply">
                    Responder
                  </v-btn>
                  <v-btn variant="outlined" class="text-none" prepend-icon="mdi-forward" @click="handleForward">
                    Encaminhar
                  </v-btn>
                </div>
              </div>
            </header>

            <div class="reader-pane__content custom-scrollbar">
              <div class="email-html-content" v-html="selectedEmail.bodyHtml"></div>
            </div>
          </template>
        </section>
      </section>
    </template>

    <v-dialog v-model="showComposeModal" max-width="880" persistent>
      <v-card class="compose-dialog">
        <div class="compose-dialog__header">
          <div>
            <div class="section-kicker">Mensagem</div>
            <h3>{{ composeDialogTitle }}</h3>
          </div>
          <v-btn icon="mdi-close" variant="text" @click="closeComposeModal" :disabled="isSending" />
        </div>

        <div class="compose-fields">
          <div class="compose-field-row">
            <label>Para</label>
            <v-text-field
              v-model="composeForm.to"
              variant="underlined"
              density="comfortable"
              hide-details
              placeholder="destinatario@empresa.com"
            />
          </div>

          <div class="compose-field-row">
            <label>Assunto</label>
            <v-text-field
              v-model="composeForm.subject"
              variant="underlined"
              density="comfortable"
              hide-details
              placeholder="Assunto do e-mail"
            />
          </div>
        </div>

        <div class="compose-editor-wrap">
          <textarea
            v-model="composeForm.body"
            class="compose-editor custom-scrollbar"
            placeholder="Escreva sua mensagem"
          ></textarea>
        </div>

        <div class="compose-dialog__footer">
          <span>{{ composeBodyLength }} caracteres</span>
          <div class="compose-dialog__footer-actions">
            <v-btn variant="text" class="text-none" @click="closeComposeModal" :disabled="isSending">Cancelar</v-btn>
            <v-btn color="primary" variant="flat" class="text-none" :loading="isSending" prepend-icon="mdi-send" @click="sendEmailReal">
              Enviar
            </v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showAccountsModal" max-width="560">
      <v-card class="accounts-dialog">
        <div class="accounts-dialog__header">
          <div>
            <div class="section-kicker">Acesso</div>
            <h3>Contas conectadas</h3>
          </div>
          <v-btn icon="mdi-close" variant="text" @click="showAccountsModal = false" />
        </div>

        <div v-if="isLoadingIdentities" class="accounts-dialog__loading">
          <v-progress-circular indeterminate color="primary" size="38" width="4" />
        </div>

        <div v-else-if="identities.length === 0" class="state-panel state-panel--embedded">
          <v-icon size="40">mdi-link-variant-off</v-icon>
          <h3>Nenhuma conta conectada</h3>
          <p>Conecte um provedor para habilitar o módulo.</p>
        </div>

        <div v-else class="accounts-list">
          <div v-for="identity in identities" :key="identity.id" class="identity-row">
            <div class="identity-row__left">
              <div class="identity-badge">
                <v-icon>{{ identity.provider === 'google' ? 'mdi-google' : 'mdi-microsoft-outlook' }}</v-icon>
              </div>
              <div class="identity-meta">
                <strong>{{ identity.provider === 'google' ? 'Google Workspace' : 'Microsoft 365' }}</strong>
                <span>{{ identity.identity_data?.email || 'Conta autenticada' }}</span>
              </div>
            </div>

            <v-btn
              variant="outlined"
              color="error"
              size="small"
              class="text-none"
              :loading="unlinkingId === identity.id"
              @click="forceUnlink(identity)"
            >
              Revogar
            </v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import { useThemeStore } from '@/stores/theme';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { supabase } from '@/api/supabase';

interface EmailSummary {
  id: string;
  threadId?: string;
  subject: string;
  fromName: string;
  fromEmail: string;
  snippet: string;
  dateFormatted: string;
  dateFull: string;
  rawPayload: any;
  isRead: boolean;
  bodyHtml?: string;
}

interface IdentityRow {
  id: string;
  provider: string;
  identity_data?: {
    email?: string;
  };
}

const themeStore = useThemeStore();
const userStore = useUserStore();
const appStore = useAppStore();

const isDark = computed(() => themeStore.currentMode !== 'light');

const isConnected = ref(false);
const isLoadingAuth = ref(true);
const userAccessToken = ref('');
const hasGmailConnected = ref(false);
const currentUserEmail = ref('');
const syncedEmailAddress = ref('');

const viewMode = ref<'hub' | 'inbox'>('hub');
const activeFolder = ref('INBOX');
const searchQuery = ref('');
const searchDebounce = ref<number | null>(null);

const realEmails = ref<EmailSummary[]>([]);
const isLoadingEmails = ref(false);
const isPaginating = ref(false);
const nextPageToken = ref('');
const selectedEmail = ref<EmailSummary | null>(null);

const showComposeModal = ref(false);
const isReplying = ref(false);
const isSending = ref(false);
const composeForm = ref({ to: '', subject: '', body: '' });

const showAccountsModal = ref(false);
const identities = ref<IdentityRow[]>([]);
const isLoadingIdentities = ref(false);
const unlinkingId = ref('');

const primaryFolders = [
  { id: 'INBOX', label: 'Caixa de entrada', icon: 'mdi-inbox-arrow-down-outline', shortcut: 'INBOX' },
  { id: 'SENT', label: 'Enviados', icon: 'mdi-send-outline', shortcut: 'SENT' },
  { id: 'DRAFT', label: 'Rascunhos', icon: 'mdi-file-document-outline', shortcut: 'DRAFT' },
  { id: 'SPAM', label: 'Spam', icon: 'mdi-alert-octagon-outline', shortcut: 'SPAM' },
  { id: 'TRASH', label: 'Lixeira', icon: 'mdi-delete-outline', shortcut: 'TRASH' },
] as const;

const folderNameMap: Record<string, string> = {
  INBOX: 'Caixa de entrada',
  SENT: 'Enviados',
  DRAFT: 'Rascunhos',
  SPAM: 'Spam',
  TRASH: 'Lixeira',
};

const currentFolderLabel = computed(() => folderNameMap[activeFolder.value] || 'Pasta');
const listStatusText = computed(() => {
  if (isLoadingEmails.value && !isPaginating.value) return 'Sincronizando mensagens';
  if (realEmails.value.length === 0) return 'Sem resultados';
  if (nextPageToken.value) return `${realEmails.value.length} mensagens carregadas`;
  return `${realEmails.value.length} mensagens`;
});

const composeDialogTitle = computed(() => (isReplying.value ? 'Responder mensagem' : 'Nova mensagem'));
const composeBodyLength = computed(() => composeForm.value.body.trim().length);

watch(searchQuery, () => {
  if (searchDebounce.value) window.clearTimeout(searchDebounce.value);
  searchDebounce.value = window.setTimeout(() => {
    fetchRealEmails(false);
  }, 350);
});

function parseSender(fromHeader: string) {
  if (!fromHeader) return { name: 'Desconhecido', email: '' };

  const match = fromHeader.match(/(.*)<(.*)>/);
  if (match) {
    return {
      name: match[1].replace(/"/g, '').trim() || match[2].trim(),
      email: match[2].trim(),
    };
  }

  return { name: fromHeader, email: fromHeader };
}

function decodeBase64(encodedStr: string) {
  try {
    const normalized = encodedStr.replace(/-/g, '+').replace(/_/g, '/');
    const binary = window.atob(normalized);
    const bytes = new Uint8Array(binary.length);

    for (let i = 0; i < binary.length; i += 1) {
      bytes[i] = binary.charCodeAt(i);
    }

    return new TextDecoder('utf-8').decode(bytes);
  } catch {
    return 'Erro ao decodificar conteúdo.';
  }
}

function sanitizeHtml(html: string) {
  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');

    doc.querySelectorAll('script, style, iframe, object, embed, link, meta').forEach((node) => node.remove());

    doc.querySelectorAll('*').forEach((node) => {
      [...node.attributes].forEach((attr) => {
        const attrName = attr.name.toLowerCase();
        const attrValue = attr.value?.toLowerCase?.() || '';

        if (attrName.startsWith('on')) node.removeAttribute(attr.name);
        if ((attrName === 'src' || attrName === 'href') && attrValue.startsWith('javascript:')) {
          node.removeAttribute(attr.name);
        }
      });
    });

    return doc.body.innerHTML || '<div class="email-fallback">Mensagem sem conteúdo visível.</div>';
  } catch {
    return '<div class="email-fallback">Não foi possível renderizar o HTML desta mensagem.</div>';
  }
}

function getMessageBody(payload: any) {
  const findPart = (parts: any[], mimeType: string): string | null => {
    for (const part of parts) {
      if (part.mimeType === mimeType && part.body?.data) return decodeBase64(part.body.data);
      if (part.parts?.length) {
        const nested = findPart(part.parts, mimeType);
        if (nested) return nested;
      }
    }

    return null;
  };

  if (payload?.parts?.length) {
    const html = findPart(payload.parts, 'text/html');
    if (html) return sanitizeHtml(html);

    const text = findPart(payload.parts, 'text/plain');
    if (text) return sanitizeHtml(text.replace(/\n/g, '<br>'));
  }

  if (payload?.body?.data) {
    const decoded = decodeBase64(payload.body.data);
    if (payload.mimeType === 'text/plain') return sanitizeHtml(decoded.replace(/\n/g, '<br>'));
    return sanitizeHtml(decoded);
  }

  return '<div class="email-fallback">Mensagem sem corpo legível.</div>';
}

function getSenderInitial(email: Partial<EmailSummary>) {
  const source = email.fromName || email.fromEmail || '?';
  return source.trim().charAt(0).toUpperCase();
}

function closeComposeModal() {
  if (isSending.value) return;
  showComposeModal.value = false;
}

function openCompose() {
  isReplying.value = false;
  composeForm.value = { to: '', subject: '', body: '' };
  showComposeModal.value = true;
}

function handleReply() {
  if (!selectedEmail.value) return;

  isReplying.value = true;
  composeForm.value = {
    to: selectedEmail.value.fromEmail,
    subject: selectedEmail.value.subject?.startsWith('Re:') ? selectedEmail.value.subject : `Re: ${selectedEmail.value.subject || ''}`,
    body: `\n\n\n--- Em ${selectedEmail.value.dateFull}, ${selectedEmail.value.fromName || selectedEmail.value.fromEmail} escreveu ---\n${selectedEmail.value.snippet || ''}`,
  };
  showComposeModal.value = true;
}

function handleForward() {
  if (!selectedEmail.value) return;

  isReplying.value = false;
  composeForm.value = {
    to: '',
    subject: `Fwd: ${selectedEmail.value.subject || '(Sem assunto)'}`,
    body: `\n\n\n--- Mensagem encaminhada ---\nDe: ${selectedEmail.value.fromName || ''} <${selectedEmail.value.fromEmail || ''}>\nData: ${selectedEmail.value.dateFull}\nAssunto: ${selectedEmail.value.subject || '(Sem assunto)'}\n\n`,
  };
  showComposeModal.value = true;
}

async function sendEmailReal() {
  if (!composeForm.value.to || !composeForm.value.subject || !composeForm.value.body) {
    appStore.showSnackbar('Preencha destinatário, assunto e conteúdo antes de enviar.', 'warning');
    return;
  }

  isSending.value = true;

  try {
    const utf8Subject = `=?utf-8?B?${btoa(unescape(encodeURIComponent(composeForm.value.subject)))}?=`;
    const bodyFormatted = sanitizeHtml(composeForm.value.body.replace(/\n/g, '<br>'));

    const messageParts = [
      `To: ${composeForm.value.to}`,
      `Subject: ${utf8Subject}`,
      'Content-Type: text/html; charset=utf-8',
      'MIME-Version: 1.0',
      '',
      bodyFormatted,
    ];

    const rawMessage = messageParts.join('\n');
    const encodedMessage = btoa(unescape(encodeURIComponent(rawMessage)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

    const response = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/messages/send', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${userAccessToken.value}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ raw: encodedMessage }),
    });

    if (!response.ok) {
      throw new Error('Falha ao enviar e-mail pela API do Gmail.');
    }

    appStore.showSnackbar('E-mail enviado com sucesso.', 'success');
    showComposeModal.value = false;

    if (activeFolder.value === 'SENT') {
      await fetchRealEmails(false);
    }
  } catch (error: any) {
    console.error('Erro no envio:', error);
    appStore.showSnackbar(error?.message || 'Erro ao enviar e-mail.', 'error');
  } finally {
    isSending.value = false;
  }
}

function changeFolder(folderId: string) {
  if (activeFolder.value === folderId) return;
  activeFolder.value = folderId;
  fetchRealEmails(false);
}

async function selectProvider(provider: 'gmail') {
  if (provider !== 'gmail') return;
  await initiateGmailOAuth();
}

async function initiateGmailOAuth() {
  try {
    const { error } = await supabase.auth.linkIdentity({
      provider: 'google',
      options: {
        redirectTo: window.location.origin + window.location.pathname,
        scopes: 'https://mail.google.com/ https://www.googleapis.com/auth/userinfo.email',
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      },
    });

    if (error) throw error;
  } catch (error: any) {
    appStore.showSnackbar(`Erro ao iniciar conexão: ${error.message}`, 'error');
  }
}

async function openAccountsModal() {
  showAccountsModal.value = true;
  isLoadingIdentities.value = true;

  try {
    const { data } = await supabase.auth.getUser();
    identities.value = (data.user?.identities?.filter((id: any) => id.provider !== 'email') || []) as IdentityRow[];
  } finally {
    isLoadingIdentities.value = false;
  }
}

async function forceUnlink(identity: IdentityRow) {
  unlinkingId.value = identity.id;

  try {
    await supabase.auth.unlinkIdentity(identity as any);

    if (userStore.user) {
      await supabase.from('email_accounts').delete().eq('user_id', userStore.user.id);
    }

    isConnected.value = false;
    hasGmailConnected.value = false;
    syncedEmailAddress.value = '';
    userAccessToken.value = '';
    realEmails.value = [];
    selectedEmail.value = null;
    viewMode.value = 'hub';

    const { data } = await supabase.auth.getUser();
    identities.value = (data.user?.identities?.filter((id: any) => id.provider !== 'email') || []) as IdentityRow[];

    appStore.showSnackbar('Acesso revogado com sucesso.', 'success');
  } catch (error: any) {
    appStore.showSnackbar(`Erro ao revogar acesso: ${error.message}`, 'error');
  } finally {
    unlinkingId.value = '';
  }
}

async function fetchSyncedProfile() {
  if (!userAccessToken.value) return;

  try {
    const response = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/profile', {
      headers: {
        Authorization: `Bearer ${userAccessToken.value}`,
      },
    });

    if (!response.ok) {
      syncedEmailAddress.value = 'Sessão indisponível';
      return;
    }

    const data = await response.json();
    syncedEmailAddress.value = data.emailAddress || 'Conta sem identificação';
  } catch (error) {
    console.error('Erro ao buscar perfil do Gmail:', error);
    syncedEmailAddress.value = 'Falha ao consultar perfil';
  }
}

async function fetchRealEmails(loadMore = false) {
  if (!userAccessToken.value) return;

  if (loadMore) {
    if (!nextPageToken.value) return;
    isPaginating.value = true;
  } else {
    isLoadingEmails.value = true;
    selectedEmail.value = null;
    realEmails.value = [];
    nextPageToken.value = '';
  }

  try {
    let query = `labelIds=${encodeURIComponent(activeFolder.value)}&maxResults=35`;

    if (searchQuery.value.trim()) {
      query += `&q=${encodeURIComponent(searchQuery.value.trim())}`;
    }

    if (loadMore && nextPageToken.value) {
      query += `&pageToken=${encodeURIComponent(nextPageToken.value)}`;
    }

    const listResponse = await fetch(`https://gmail.googleapis.com/gmail/v1/users/me/messages?${query}`, {
      headers: {
        Authorization: `Bearer ${userAccessToken.value}`,
      },
    });

    if (!listResponse.ok) {
      throw new Error('Falha ao buscar mensagens no Gmail. O token pode ter expirado.');
    }

    const listData = await listResponse.json();
    nextPageToken.value = listData.nextPageToken || '';

    if (!listData.messages?.length) {
      if (!loadMore) realEmails.value = [];
      return;
    }

    const fullMessages = await Promise.all(
      listData.messages.map((msg: any) =>
        fetch(`https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}?format=full`, {
          headers: {
            Authorization: `Bearer ${userAccessToken.value}`,
          },
        }).then(async (response) => {
          if (!response.ok) throw new Error('Falha ao ler conteúdo de uma mensagem.');
          return response.json();
        }),
      ),
    );

    const processed: EmailSummary[] = fullMessages.map((msg: any) => {
      const headers = msg.payload?.headers || [];
      const subjectHeader = headers.find((header: any) => header.name === 'Subject');
      const fromHeader = headers.find((header: any) => header.name === 'From');
      const dateHeader = headers.find((header: any) => header.name === 'Date');
      const senderInfo = parseSender(fromHeader?.value || '');
      const rawDate = dateHeader?.value ? new Date(dateHeader.value) : new Date();
      const labels = msg.labelIds || [];

      return {
        id: msg.id,
        threadId: msg.threadId,
        subject: subjectHeader?.value || '(Sem assunto)',
        fromName: senderInfo.name,
        fromEmail: senderInfo.email,
        snippet: msg.snippet || '',
        dateFormatted: rawDate.toLocaleString('pt-BR', {
          day: '2-digit',
          month: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
        }),
        dateFull: rawDate.toLocaleString('pt-BR', {
          dateStyle: 'full',
          timeStyle: 'short',
        }),
        rawPayload: msg.payload,
        isRead: !labels.includes('UNREAD'),
      };
    });

    realEmails.value = loadMore ? [...realEmails.value, ...processed] : processed;
  } catch (error: any) {
    console.error('Erro ao buscar e-mails:', error);
    appStore.showSnackbar(error?.message || 'Erro ao buscar e-mails.', 'error');
  } finally {
    isLoadingEmails.value = false;
    isPaginating.value = false;
  }
}

function viewEmail(email: EmailSummary) {
  selectedEmail.value = {
    ...email,
    bodyHtml: getMessageBody(email.rawPayload),
  };
}

onMounted(async () => {
  try {
    const hash = window.location.hash;
    const search = window.location.search;

    if (search || hash) {
      window.history.replaceState(null, '', window.location.pathname);
    }

    if (hash && hash.includes('provider_token')) {
      const params = new URLSearchParams(hash.substring(1));
      const providerToken = params.get('provider_token');

      if (providerToken) {
        const {
          data: { session },
        } = await supabase.auth.getSession();

        const activeUser = session?.user || userStore.user;

        if (activeUser) {
          await supabase.from('email_accounts').upsert(
            {
              user_id: activeUser.id,
              provider: 'gmail',
              email_address: activeUser.email || 'usuario@gmail.com',
              access_token: providerToken,
              refresh_token: params.get('provider_refresh_token') || 'N/A',
              is_active: true,
            },
            { onConflict: 'user_id' },
          );

          isConnected.value = true;
          hasGmailConnected.value = true;
          viewMode.value = 'inbox';
          userAccessToken.value = providerToken;
          currentUserEmail.value = activeUser.email || '';

          await fetchSyncedProfile();
          await fetchRealEmails(false);
        }
      }
    } else {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      const activeUser = session?.user || userStore.user;

      if (activeUser) {
        currentUserEmail.value = activeUser.email || '';

        const { data } = await supabase
          .from('email_accounts')
          .select('access_token')
          .eq('user_id', activeUser.id)
          .maybeSingle();

        if (data?.access_token) {
          isConnected.value = true;
          hasGmailConnected.value = true;
          viewMode.value = 'inbox';
          userAccessToken.value = data.access_token;

          await fetchSyncedProfile();
          await fetchRealEmails(false);
        }
      }
    }
  } catch (error) {
    console.error('Erro geral no EmailManager:', error);
  } finally {
    isLoadingAuth.value = false;
  }
});
</script>

<style scoped>
.mail-app {
  --app-bg: #f3f4f6;
  --surface: #ffffff;
  --surface-soft: #f8fafc;
  --surface-muted: #f1f5f9;
  --border: #dbe1ea;
  --border-strong: #cfd8e3;
  --text: #0f172a;
  --text-soft: #475569;
  --text-muted: #64748b;
  --hover: #f8fafc;
  --active: #eff6ff;
  --shadow: 0 1px 2px rgba(15, 23, 42, 0.05), 0 8px 24px rgba(15, 23, 42, 0.04);

  display: flex;
  flex-direction: column;
  width: 100%;
  height: calc(100vh - 64px);
  min-height: calc(100vh - 64px);
  overflow: hidden;
  background: var(--app-bg);
  color: var(--text);
}

.theme-dark.mail-app {
  --app-bg: #0f172a;
  --surface: #111827;
  --surface-soft: #172033;
  --surface-muted: #1e293b;
  --border: #273449;
  --border-strong: #334155;
  --text: #e5e7eb;
  --text-soft: #cbd5e1;
  --text-muted: #94a3b8;
  --hover: #172033;
  --active: #1d304f;
  --shadow: 0 1px 2px rgba(2, 6, 23, 0.3), 0 10px 24px rgba(2, 6, 23, 0.28);
}

.app-header {
  display: grid;
  grid-template-columns: 260px minmax(320px, 1fr) auto;
  align-items: center;
  gap: 20px;
  min-height: 72px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--border);
  background: var(--surface);
}

.app-header__left,
.app-header__right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.app-header__right {
  justify-content: flex-end;
}

.app-logo {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  background: var(--surface-muted);
  border: 1px solid var(--border);
}

.app-title-group h1,
.list-pane__header h2,
.reader-title-block h2,
.setup-hero h2,
.provider-copy h3,
.compose-dialog h3,
.accounts-dialog h3 {
  margin: 0;
  letter-spacing: -0.02em;
}

.app-title-group p,
.list-pane__header p,
.setup-hero p,
.provider-copy p,
.state-panel p,
.accounts-dialog p {
  margin: 0;
  color: var(--text-muted);
}

.app-title-group h1 {
  font-size: 18px;
  font-weight: 700;
}

.app-title-group p {
  font-size: 12px;
  margin-top: 2px;
}

.global-search :deep(.v-field) {
  border-radius: 12px;
  box-shadow: none;
  background: var(--surface-muted);
}

.setup-screen {
  flex: 1;
  overflow: auto;
  padding: 24px;
}

.setup-shell {
  max-width: 1180px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.setup-hero,
.provider-card,
.compose-dialog,
.accounts-dialog,
.nav-pane,
.list-pane,
.reader-pane {
  background: var(--surface);
  border: 1px solid var(--border);
  box-shadow: var(--shadow);
}

.setup-hero {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  padding: 24px;
  border-radius: 18px;
}

.setup-hero h2 {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
}

.section-kicker {
  font-size: 11px;
  line-height: 1;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 10px;
}

.setup-status {
  display: grid;
  grid-template-columns: repeat(2, minmax(180px, 1fr));
  gap: 12px;
}

.status-card {
  min-width: 180px;
  padding: 16px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface-soft);
}

.status-card span,
.status-card small,
.provider-meta span,
.account-card__row span,
.reader-date,
.mail-item__snippet,
.identity-meta span {
  color: var(--text-muted);
}

.status-card strong,
.provider-meta strong,
.account-card__row strong,
.identity-meta strong {
  display: block;
  margin-top: 6px;
  color: var(--text);
}

.provider-grid {
  display: grid;
  gap: 16px;
}

.provider-card {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  padding: 24px;
  border-radius: 18px;
}

.provider-card--muted {
  opacity: 0.9;
}

.provider-card__main {
  display: flex;
  gap: 18px;
  align-items: flex-start;
}

.provider-icon,
.identity-badge,
.sender-block__avatar,
.mail-item__avatar {
  display: grid;
  place-items: center;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface-muted);
}

.provider-icon {
  width: 48px;
  height: 48px;
}

.provider-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.provider-copy h3 {
  font-size: 18px;
  font-weight: 700;
}

.provider-meta {
  margin-top: 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.provider-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 180px;
  justify-content: center;
}

.workspace {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 248px 360px minmax(520px, 1fr);
  gap: 0;
}

.nav-pane,
.list-pane,
.reader-pane {
  min-height: 0;
  border-radius: 0;
  box-shadow: none;
  border-top: 0;
  border-bottom: 0;
}

.nav-pane,
.list-pane {
  border-right: 1px solid var(--border);
}

.nav-pane {
  display: flex;
  flex-direction: column;
  padding: 16px;
  gap: 20px;
}

.nav-section {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.nav-section__title {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  padding: 0 8px;
}

.nav-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  min-height: 40px;
  padding: 0 10px;
  border: 1px solid transparent;
  border-radius: 10px;
  background: transparent;
  color: var(--text-soft);
  cursor: pointer;
  text-align: left;
}

.nav-item__left {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.nav-item:hover {
  background: var(--hover);
}

.nav-item--active {
  background: var(--active);
  border-color: var(--border);
  color: var(--text);
}

.nav-section--meta {
  margin-top: auto;
}

.account-card {
  border: 1px solid var(--border);
  border-radius: 14px;
  background: var(--surface-soft);
  overflow: hidden;
}

.account-card__row {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px 14px;
}

.account-card__row + .account-card__row {
  border-top: 1px solid var(--border);
}

.nav-pane__bottom {
  display: flex;
  flex-direction: column;
  align-items: stretch;
}

.list-pane {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.list-pane__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  border-bottom: 1px solid var(--border);
  background: var(--surface);
}

.list-pane__header h2,
.reader-title-block h2 {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 4px;
}

.mail-list,
.reader-pane__content {
  flex: 1;
  min-height: 0;
  overflow: auto;
}

.mail-item {
  width: 100%;
  display: grid;
  grid-template-columns: 40px minmax(0, 1fr);
  gap: 12px;
  align-items: start;
  padding: 14px 16px;
  border: 0;
  border-bottom: 1px solid var(--border);
  background: transparent;
  text-align: left;
  cursor: pointer;
}

.mail-item:hover {
  background: var(--hover);
}

.mail-item--active {
  background: var(--active);
}

.mail-item--unread .mail-item__subject,
.mail-item--unread .mail-item__top strong {
  font-weight: 700;
}

.mail-item__avatar,
.sender-block__avatar {
  width: 40px;
  height: 40px;
  font-size: 14px;
  font-weight: 700;
  color: var(--text-soft);
}

.mail-item__body {
  min-width: 0;
}

.mail-item__top {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
}

.mail-item__top strong,
.mail-item__subject {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.mail-item__top strong {
  max-width: 70%;
  color: var(--text);
}

.mail-item__top span {
  flex-shrink: 0;
  font-size: 12px;
  color: var(--text-muted);
}

.mail-item__subject {
  margin-top: 4px;
  color: var(--text-soft);
}

.mail-item__snippet {
  margin-top: 4px;
  font-size: 13px;
  line-height: 1.45;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.mail-list__footer {
  padding: 16px;
  display: flex;
  justify-content: center;
  border-top: 1px solid var(--border);
  color: var(--text-muted);
}

.reader-pane {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.reader-pane__header {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  padding: 22px 24px;
  border-bottom: 1px solid var(--border);
}

.reader-title-block,
.sender-block {
  min-width: 0;
}

.sender-block {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 18px;
}

.sender-block__meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.sender-block__meta strong,
.sender-block__meta span {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.reader-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 14px;
  flex-shrink: 0;
}

.reader-actions__buttons {
  display: flex;
  gap: 10px;
}

.reader-pane__content {
  padding: 24px;
  background: var(--surface);
}

.state-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  text-align: center;
}

.state-panel--page {
  flex: 1;
}

.state-panel--embedded {
  flex: 1;
  min-height: 280px;
  padding: 24px;
}

.reader-empty {
  background: var(--surface);
}

.compose-dialog,
.accounts-dialog {
  border-radius: 18px;
  overflow: hidden;
}

.compose-dialog__header,
.accounts-dialog__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 22px;
  border-bottom: 1px solid var(--border);
}

.compose-fields {
  padding: 8px 22px 0;
}

.compose-field-row {
  display: grid;
  grid-template-columns: 72px 1fr;
  gap: 14px;
  align-items: center;
}

.compose-field-row label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-soft);
}

.compose-editor-wrap {
  padding: 14px 22px 0;
}

.compose-editor {
  width: 100%;
  min-height: 360px;
  max-height: 56vh;
  resize: vertical;
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 16px;
  background: var(--surface);
  color: var(--text);
  font: inherit;
  line-height: 1.6;
  outline: none;
}

.compose-editor:focus {
  border-color: rgb(var(--v-theme-primary));
}

.compose-dialog__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 22px 20px;
  color: var(--text-muted);
}

.compose-dialog__footer-actions {
  display: flex;
  gap: 10px;
}

.accounts-dialog__loading {
  min-height: 220px;
  display: grid;
  place-items: center;
}

.accounts-list {
  padding: 10px 0;
}

.identity-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 22px;
}

.identity-row + .identity-row {
  border-top: 1px solid var(--border);
}

.identity-row__left {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.identity-badge {
  width: 40px;
  height: 40px;
}

.identity-meta {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.identity-meta strong,
.identity-meta span {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.email-html-content {
  max-width: 920px;
  margin: 0 auto;
  color: var(--text);
  line-height: 1.65;
  word-break: break-word;
}

.email-html-content :deep(img) {
  max-width: 100%;
  height: auto;
}

.email-html-content :deep(table) {
  max-width: 100%;
  display: block;
  overflow-x: auto;
}

.email-fallback {
  padding: 20px;
  border: 1px dashed var(--border-strong);
  border-radius: 12px;
  background: var(--surface-soft);
  color: var(--text-soft);
}

.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: var(--border-strong) transparent;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 10px;
  height: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--border-strong);
  border-radius: 999px;
  border: 2px solid transparent;
  background-clip: padding-box;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

@media (max-width: 1320px) {
  .workspace {
    grid-template-columns: 220px 340px minmax(420px, 1fr);
  }
}

@media (max-width: 1120px) {
  .app-header {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .app-header__center,
  .app-header__right {
    width: 100%;
  }

  .workspace {
    grid-template-columns: 220px 1fr;
    grid-template-areas:
      'nav list'
      'nav reader';
    grid-template-rows: 320px minmax(0, 1fr);
  }

  .nav-pane { grid-area: nav; }
  .list-pane { grid-area: list; }
  .reader-pane {
    grid-area: reader;
    border-top: 1px solid var(--border);
  }
}

@media (max-width: 860px) {
  .mail-app {
    height: auto;
    min-height: calc(100vh - 64px);
  }

  .workspace {
    display: flex;
    flex-direction: column;
  }

  .nav-pane,
  .list-pane,
  .reader-pane {
    border-right: 0;
    border-bottom: 1px solid var(--border);
  }

  .setup-hero,
  .provider-card,
  .reader-pane__header,
  .compose-dialog__footer {
    flex-direction: column;
    align-items: stretch;
  }

  .setup-status {
    grid-template-columns: 1fr;
  }

  .provider-actions {
    min-width: 0;
  }

  .compose-field-row {
    grid-template-columns: 1fr;
    gap: 4px;
  }
}
</style>
