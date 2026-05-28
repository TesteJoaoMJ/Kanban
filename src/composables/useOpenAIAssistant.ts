// src/composables/useOpenAIAssistant.ts
import { ref, onMounted, watch } from 'vue'
// import OpenAI from 'openai'; // <-- REMOVIDO! Não é mais usado no frontend.
import { useUserStore } from '@/stores/user'
import { supabase } from '@/api/supabase'
import { storeToRefs } from 'pinia'

// [MANTIDO] A interface é a mesma do seu arquivo
export interface Message {
  id: string
  role: 'user' | 'assistant' | 'system' // Adicionado 'system' para erros
  content: string
  replyingTo?: {
    id: string
    content: string
    author: string
  } | null
  editedFrom?: {
    id: string
    content: string
  } | null
}

// [MODIFICADO] Assinatura limpa. Não recebe mais 'apiKey' ou 'assistantId'.
export function useOpenAIAssistant() {
  const messages = ref<Message[]>([])
  const isLoading = ref(false)
  const threadId = ref<string | null>(null) // MANTIDO! Essencial.
  const userStore = useUserStore()
  const { profile } = storeToRefs(userStore)
  const isInitialized = ref(false)
  const error = ref<string | null>(null)

  // [REMOVIDO] Instância da OpenAI. Não é mais criada no frontend.

  // --- [MODIFICADO] createThread ---
  // A lógica foi movida para o backend. Esta função agora apenas
  // garante que o `threadId` do perfil seja carregado.
  const setupThreadForUser = async () => {
    const userThreadId = profile.value?.assistant_thread_id
    console.log(`>>> setupThread: Verificando thread. Perfil: ${profile.value?.id}. Thread no perfil: ${userThreadId}`)

    if (userThreadId) {
      console.log(`>>> setupThread: Usando thread existente ${userThreadId}.`)
      threadId.value = userThreadId
      return userThreadId
    } else {
      // Se o usuário não tem thread, a primeira mensagem para o 'hybrid-assistant'
      // irá criar uma e retorná-la.
      console.warn(`>>> setupThread: Perfil sem thread. A primeira mensagem irá criar uma.`)
      threadId.value = null // Sinaliza para o backend criar um novo
      return null
    }
  }

  // --- [REMOVIDO] loadMessageHistory ---
  // Não precisamos carregar o histórico no frontend. A API Assistants
  // já armazena isso no backend usando o 'threadId'.
  // Vamos apenas mostrar uma mensagem de boas-vindas.

  // --- [MODIFICADO] Função sendMessage ---
  // Esta é a mudança principal. Substitui todo o polling por uma única chamada.
  const sendMessage = async (
    content: string,
    replyContextMessage: Message | null = null,
    editContextMessage: Message | null = null
  ) => {

    console.log(`>>> sendMessage [Híbrido]: [INÍCIO] isInitialized=${isInitialized.value}, threadId=${threadId.value}`)
    if (!isInitialized.value || !profile.value) {
      console.error('>>> sendMessage [Híbrido]: [ERRO] Não inicializado.', { isInitialized: isInitialized.value, profile: !!profile.value })
      messages.value.push({ id: `err_send_state_${Date.now()}`, role: 'system', content: 'O assistente não está pronto.' })
      return
    }

    isLoading.value = true
    error.value = null
    const userName = profile.value.full_name || 'Usuário'

    // --- [MANTIDO] Lógica de Contexto para UI (do seu arquivo) ---
    let replyingToForUi: Message['replyingTo'] = null
    let editedFromForUi: Message['editedFrom'] = null
    if (replyContextMessage) {
      replyingToForUi = {
        id: replyContextMessage.id,
        content: replyContextMessage.content,
        author: replyContextMessage.role === 'assistant' ? 'MJ Bot' : userName,
      }
    } else if (editContextMessage) {
      editedFromForUi = {
        id: editContextMessage.id,
        content: editContextMessage.content,
      }
    }
    // --- FIM ---

    // Adiciona a mensagem do usuário à UI (do seu arquivo)
    const tempUserMessageId = `temp_user_${Date.now()}`
    messages.value.push({
      id: tempUserMessageId,
      role: 'user',
      content: content,
      replyingTo: replyingToForUi,
      editedFrom: editedFromForUi,
    })

    try {
      // [MODIFICAÇÃO DE SEGURANÇA]
      // Pega o 'role' do perfil. Se não houver perfil ou role,
      // assume 'user' como padrão por segurança.
      const userRole = profile.value?.role || 'user'

      // [A MÁGICA] Chama a função HÍBRIDA no backend
      // Passa a pergunta E o threadId (que pode ser nulo na 1ª vez)
      const { data, error: funcError } = await supabase.functions.invoke(
        'hybrid-assistant', // A função que vamos criar no Passo 3
        {
          body: {
            query: content,
            threadId: threadId.value,
            userRole: userRole // <-- [CORREÇÃO DE SEGURANÇA] Envia o 'role'
          },
        }
      )

      if (funcError) throw funcError
      if (data.error) throw new Error(data.error)

      // Se um novo thread foi criado no backend, salve-o
      if (data.newThreadId && !threadId.value) {
        console.log(`>>> sendMessage: Novo thread ${data.newThreadId} criado e salvo.`)
        threadId.value = data.newThreadId
        // Atualiza no Supabase E na store local
        await supabase
           .from('profiles')
           .update({ assistant_thread_id: data.newThreadId })
           .eq('id', profile.value.id)
        userStore.updateProfile({ assistant_thread_id: data.newThreadId })
      }

      // Adiciona a resposta do assistente (vinda de qualquer um dos "cérebros")
      messages.value.push({
        id: `asst_${Date.now()}`,
        role: 'assistant',
        content: data.answer || 'Desculpe, não recebi uma resposta válida.',
      })

      // Atualiza o ID da mensagem do usuário
      const msgIndex = messages.value.findIndex(m => m.id === tempUserMessageId)
      if (msgIndex !== -1) {
          messages.value[msgIndex].id = `user_${Date.now()}`
      }

    } catch (err: any) {
      console.error(`>>> sendMessage: [ERRO GERAL]`, err)
      messages.value.push({
        id: `err_send_${Date.now()}`,
        role: 'system',
        content: `Desculpe, ocorreu um erro: ${err.message || 'Erro desconhecido'}.`,
      })
    } finally {
      isLoading.value = false
    }
  }

  // --- [MODIFICADO] Lógica de Inicialização (do seu arquivo) ---
  let isInitializing = false
  const initializeChat = async () => {
    if (isInitializing) return
    if (!profile.value) {
      console.log(">>> initializeChat: [AGUARDANDO] Perfil do usuário...")
      isInitialized.value = false
      return
    }

    console.log(`>>> initializeChat: [INÍCIO] Híbrido para perfil ${profile.value.id}...`)
    isInitializing = true
    isInitialized.value = false
    isLoading.value = true
    messages.value = [] // Limpa histórico

    try {
      await setupThreadForUser()

      messages.value.push({
         id: 'system-init',
         role: 'system',
         content: 'Olá! Eu sou seu assistente. Posso ajudar com processos do sistema e dados do banco.'
      })
      isInitialized.value = true

    } catch (error: any) {
       console.error(">>> initializeChat: [ERRO]", error)
       messages.value.push({id: `err_init_${Date.now()}`, role: 'system', content: `Falha ao configurar a conversa: ${error.message}`});
    } finally {
      isLoading.value = false
      isInitializing = false
      console.log(`>>> initializeChat: [FIM] isInitialized=${isInitialized.value}, threadId=${threadId.value}`);
    }
  }

  // --- [MANTIDO] Gatilhos onMounted e watch (do seu arquivo) ---
  onMounted(() => {
    console.log(">>> onMounted: Composable montado.");
    setTimeout(() => {
      if (profile.value) {
        console.log(">>> onMounted: Perfil JÁ EXISTE após delay, chamando initializeChat.");
        initializeChat();
      } else {
        console.log(">>> onMounted: Perfil AINDA NÃO carregado após delay, aguardando watch.");
      }
    }, 100);
  });

  watch(profile, (newProfile, oldProfile) => {
    console.log(`>>> WATCH profile: Acionado. Novo ID: ${newProfile?.id}, Antigo ID: ${oldProfile?.id}`);
    const hasTrulyChanged = newProfile?.id !== oldProfile?.id;
    const isInitialLoad = !!newProfile && !oldProfile;
    if (hasTrulyChanged || isInitialLoad) {
      if (newProfile) {
        console.log(">>> WATCH profile: Novo perfil ou troca de usuário, chamando initializeChat.");
        initializeChat();
      } else {
        console.log(">>> WATCH profile: Logout detectado. Resetando estado.");
        isInitialized.value = false;
        threadId.value = null;
        messages.value = [];
        isInitializing = false;
      }
    }
  }, { immediate: false, deep: false });

  return {
    messages,
    isLoading,
    isInitialized,
    sendMessage,
    initializeChat
  }
}
