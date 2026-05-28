<template>
  <div :class="['mj-auth-shell', isDark ? 'theme-dark' : 'theme-light']">

    <div v-if="isLoading" class="boot-screen">
      <div class="boot-box">
        <img :src="currentLogo" alt="MJ Process" class="boot-logo" />
        <div class="boot-line"></div>
        <p class="boot-text">Estabelecendo conexão segura...</p>
      </div>
    </div>

    <transition name="fade" mode="out-in">

      <div v-if="authMode === 'welcome_boot'" key="welcome-screen" class="welcome-fullscreen">
        <div class="welcome-content-minimal">
          <h2 class="welcome-title-minimal">BEM-VINDO(A)</h2>
          <h1 class="welcome-name-minimal">{{ currentLead?.name?.split(' ')[0]?.toUpperCase() || 'CLIENTE' }}</h1>
          <div class="welcome-loader mt-8"></div>
        </div>
      </div>

      <div v-else key="main-auth" class="auth-layout">

        <aside class="auth-visual d-none d-md-flex">
          <div class="scrolling-grid">
            <div class="scroll-track down">
              <div v-for="n in 6" :key="`c1-${n}`" class="stamp-wrapper">
                <img :src="getStamp(n)" class="scroll-img" />
              </div>
            </div>
            <div class="scroll-track up">
              <div v-for="n in 6" :key="`c2-${n}`" class="stamp-wrapper">
                <img :src="getStamp(n + 2)" class="scroll-img" style="filter: hue-rotate(15deg);" />
              </div>
            </div>
            <div class="scroll-track down">
              <div v-for="n in 6" :key="`c3-${n}`" class="stamp-wrapper">
                <img :src="getStamp(n + 4)" class="scroll-img" style="filter: grayscale(0.1);" />
              </div>
            </div>
          </div>

          <div class="auth-visual-fade"></div>

          <div class="auth-visual-content">
            <div class="premium-badge mb-6">
              <v-icon size="14" color="warning" class="mr-2">mdi-star-four-points</v-icon>
              Ecossistema MJ
            </div>
            <h1 class="display-title">Bem-vindo(a)<br>ao Portal.</h1>
            <p class="display-copy">
              Acesse ferramentas de simulação, orçamentos rápidos e nosso acervo de estampas exclusivas.
            </p>
          </div>
        </aside>

        <main class="auth-panel">
          <div class="auth-card">

            <div class="auth-topbar mb-10 d-flex align-center justify-space-between">
              <img :src="currentLogo" alt="Logo" class="brand-logo" />
              <v-btn icon variant="tonal" size="small" class="theme-toggle rounded-lg" @click="toggleTheme">
                <v-icon size="20">{{ isDark ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
              </v-btn>
            </div>

            <transition name="fade-slide" mode="out-in">

              <div v-if="authMode === 'login' || authMode === 'register'" key="auth-step">
                <div class="mb-8">
                  <h2 class="section-title">{{ authMode === 'login' ? 'Acessar Conta' : 'Criar Conta' }}</h2>
                  <p class="section-copy">
                    {{ authMode === 'login' ? 'Insira suas credenciais para continuar.' : 'Inicie seu cadastro para validação empresarial.' }}
                  </p>
                </div>

                <v-alert v-if="authError" type="error" variant="tonal" class="mb-6 rounded-lg text-body-2 font-weight-medium border-error" closable @click:close="authError = ''">{{ authError }}</v-alert>
                <v-alert v-if="authSuccess" type="success" variant="tonal" class="mb-6 rounded-lg text-body-2 font-weight-medium border-success" closable @click:close="authSuccess = ''">{{ authSuccess }}</v-alert>

                <form @submit.prevent="handleEmailAuth" class="auth-form">
                  <div class="field-group">
                    <label class="field-label">E-mail corporativo</label>
                    <div class="input-wrapper">
                      <v-icon class="input-icon">mdi-email-outline</v-icon>
                      <input v-model="authForm.email" type="email" class="mj-input with-icon" :disabled="isSubmitting" placeholder="voce@suaempresa.com.br" required />
                    </div>
                  </div>

                  <div class="field-group mt-5">
                    <div class="d-flex justify-space-between align-center">
                      <label class="field-label">Senha</label>
                      <a v-if="authMode === 'login'" href="#" class="forgot-link" @click.prevent="authMode = 'forgot_password'">Esqueceu a senha?</a>
                    </div>
                    <div class="input-wrapper">
                      <v-icon class="input-icon">mdi-lock-outline</v-icon>
                      <input v-model="authForm.password" type="password" class="mj-input with-icon" :disabled="isSubmitting" placeholder="••••••••" required />
                    </div>
                  </div>

                  <div v-if="authMode === 'register'" class="field-group mt-5">
                    <label class="field-label">Confirmar Senha</label>
                    <div class="input-wrapper">
                      <v-icon class="input-icon">mdi-lock-check-outline</v-icon>
                      <input v-model="authForm.confirmPassword" type="password" class="mj-input with-icon" :class="{'input-error': !passwordsMatch && authForm.confirmPassword}" :disabled="isSubmitting" placeholder="••••••••" required />
                    </div>
                    <span v-if="!passwordsMatch && authForm.confirmPassword" class="error-text mt-2">As senhas não coincidem.</span>
                  </div>

                  <v-btn v-if="!isSubmitting" type="submit" color="primary" size="large" block class="cta-btn mt-8" elevation="0">
                    {{ authMode === 'login' ? 'Entrar no Portal' : 'Continuar Cadastro' }}
                  </v-btn>
                  <div v-else class="submit-loading mt-8">
                    <v-progress-circular indeterminate size="24" width="3" color="primary" />
                    <span class="ml-3 font-weight-bold text-primary">Processando...</span>
                  </div>
                </form>

                <div class="divider-container">
                  <div class="divider-line"></div>
                  <span class="divider-text text-muted-custom">OU CONTINUE COM</span>
                  <div class="divider-line"></div>
                </div>

                <v-btn block variant="outlined" class="social-btn" height="52" @click="loginSocial('google')">
                  <v-icon start color="error" size="24" class="mr-2">mdi-google</v-icon> Google
                </v-btn>

                <div class="text-center mt-8">
                  <p class="text-body-2 text-muted-custom">
                    {{ authMode === 'login' ? 'Não tem uma conta?' : 'Já possui cadastro?' }}
                    <a href="#" class="switch-link ml-1" @click.prevent="toggleAuthMode">
                      {{ authMode === 'login' ? 'Crie sua conta' : 'Fazer login' }}
                    </a>
                  </p>
                </div>
              </div>

              <div v-else-if="authMode === 'forgot_password'" key="forgot-step">
                <v-btn icon="mdi-arrow-left" variant="text" size="small" class="mb-4 back-btn" @click="authMode = 'login'"></v-btn>
                <div class="mb-8">
                  <h2 class="section-title">Recuperar Senha</h2>
                  <p class="section-copy text-muted-custom">Informe seu e-mail cadastrado. Enviaremos um link seguro para você redefinir sua senha.</p>
                </div>
                <v-alert v-if="authError" type="error" variant="tonal" class="mb-6 rounded-lg text-body-2 font-weight-medium border-error" closable @click:close="authError = ''">{{ authError }}</v-alert>
                <v-alert v-if="authSuccess" type="success" variant="tonal" class="mb-6 rounded-lg text-body-2 font-weight-medium border-success">{{ authSuccess }}</v-alert>

                <form v-if="!authSuccess" @submit.prevent="handleForgotPassword" class="auth-form">
                  <div class="field-group">
                    <label class="field-label">E-mail corporativo</label>
                    <div class="input-wrapper">
                      <v-icon class="input-icon">mdi-email-outline</v-icon>
                      <input v-model="authForm.email" type="email" class="mj-input with-icon" :disabled="isSubmitting" placeholder="voce@suaempresa.com.br" required />
                    </div>
                  </div>
                  <v-btn v-if="!isSubmitting" type="submit" color="primary" size="large" block class="cta-btn mt-8" elevation="0">Enviar Link de Recuperação</v-btn>
                  <div v-else class="submit-loading mt-8"><v-progress-circular indeterminate size="24" width="3" color="primary" /></div>
                </form>
                <v-btn v-if="authSuccess" block variant="tonal" class="cta-btn mt-6 font-weight-bold" @click="authMode = 'login'">Voltar ao Login</v-btn>
              </div>

              <div v-else-if="authMode === 'onboarding'" key="onboarding-step" class="onboarding-wrapper">
                <div class="timeline-header mb-8">
                  <div class="timeline-track"><div class="timeline-progress" :style="`width: ${(onboardingStep - 1) * 50}%`"></div></div>
                  <div class="timeline-steps">
                    <div class="step-dot" :class="{ active: onboardingStep >= 1 }"><v-icon size="16" v-if="onboardingStep > 1">mdi-check</v-icon><span v-else>1</span></div>
                    <div class="step-dot" :class="{ active: onboardingStep >= 2 }"><v-icon size="16" v-if="onboardingStep > 2">mdi-check</v-icon><span v-else>2</span></div>
                    <div class="step-dot" :class="{ active: onboardingStep >= 3 }">3</div>
                  </div>
                </div>

                <v-alert v-if="onboardingError" type="error" variant="tonal" class="mb-6 rounded-lg text-body-2 font-weight-medium border-error" closable @click:close="onboardingError = ''">{{ onboardingError }}</v-alert>

                <transition name="slide-x" mode="out-in">
                  <div v-if="onboardingStep === 1" key="step1">
                    <h2 class="section-title mb-2">Validação de Marca</h2>
                    <p class="section-copy mb-8 text-muted-custom">O acesso é restrito a lojistas e confecções. Digite seu CNPJ para validação automática na Receita Federal.</p>
                    <div class="field-group">
                      <label class="field-label">CNPJ da Empresa</label>
                      <div class="d-flex gap-3">
                        <div class="input-wrapper flex-grow-1">
                          <v-icon class="input-icon">mdi-domain</v-icon>
                          <input v-model="leadForm.document" type="text" class="mj-input with-icon text-h6 tracking-wider" :disabled="isSearchingCnpj" placeholder="00.000.000/0000-00" v-maska="'##.###.###/####-##'" @keyup.enter="buscarCnpj" />
                        </div>
                        <v-btn color="primary" variant="flat" height="52" width="54" class="rounded-xl" :loading="isSearchingCnpj" @click="buscarCnpj" elevation="0"><v-icon size="24">mdi-magnify</v-icon></v-btn>
                      </div>
                      <span v-if="cnpjError" class="error-text mt-2">{{ cnpjError }}</span>
                    </div>
                    <v-btn v-if="leadForm.name && leadForm.document" color="success" size="large" block class="cta-btn mt-8" elevation="0" @click="onboardingStep = 2">Empresa Localizada. Continuar</v-btn>
                  </div>

                  <div v-else-if="onboardingStep === 2" key="step2">
                    <h2 class="section-title mb-2">Dados de Contato</h2>
                    <p class="section-copy mb-8 text-muted-custom">Precisamos do seu WhatsApp e Instagram para completar seu cadastro na plataforma.</p>
                    <div class="auth-form">
                      <div class="field-group">
                        <label class="field-label">Razão Social</label>
                        <input v-model="leadForm.name" type="text" class="mj-input read-only-input" disabled />
                      </div>
                      <div class="field-group mt-5">
                        <label class="field-label">Instagram da Marca <span class="text-error">*</span></label>
                        <div class="input-wrapper">
                          <v-icon class="input-icon text-pink">mdi-instagram</v-icon>
                          <input v-model="leadForm.instagram" type="text" class="mj-input with-icon" placeholder="@suamarca" required />
                        </div>
                      </div>
                      <div class="field-grid two-cols mt-5 gap-4">
                        <div class="field-group w-100">
                          <label class="field-label">WhatsApp <span class="text-error">*</span></label>
                          <div class="input-wrapper">
                            <v-icon class="input-icon text-success">mdi-whatsapp</v-icon>
                            <input v-model="leadForm.phone" type="tel" class="mj-input with-icon" placeholder="(00) 00000-0000" v-maska="'(##) #####-####'" required />
                          </div>
                        </div>
                        <div class="field-group w-100">
                          <label class="field-label">Cidade / UF</label>
                          <input v-model="leadForm.location" type="text" class="mj-input" placeholder="Ex: São Paulo / SP" required />
                        </div>
                      </div>
                      <div class="d-flex gap-4 mt-8">
                        <v-btn variant="tonal" size="large" class="rounded-xl px-4 cta-btn" @click="onboardingStep = 1"><v-icon>mdi-arrow-left</v-icon></v-btn>
                        <v-btn color="primary" size="large" class="cta-btn flex-grow-1" elevation="0" :disabled="!leadForm.instagram || leadForm.phone.length < 14" @click="onboardingStep = 3">Última etapa</v-btn>
                      </div>
                    </div>
                  </div>

                  <div v-else-if="onboardingStep === 3" key="step3">
                    <h2 class="section-title mb-2">Para finalizar...</h2>
                    <p class="section-copy mb-8 text-muted-custom">Como você conheceu a MJ? Isso nos ajuda a entender melhor nosso público.</p>
                    <div class="source-grid">
                      <button v-for="source in discoverySources" :key="source" class="source-card" :class="{ 'active': leadForm.discovery_source === source }" @click="leadForm.discovery_source = source">{{ source }}</button>
                    </div>
                    <div class="d-flex gap-4 mt-8">
                      <v-btn variant="tonal" size="large" class="rounded-xl px-4 cta-btn" :disabled="isSubmitting" @click="onboardingStep = 2"><v-icon>mdi-arrow-left</v-icon></v-btn>
                      <v-btn v-if="!isSubmitting" color="primary" size="large" class="cta-btn flex-grow-1" elevation="0" :disabled="!leadForm.discovery_source" @click="submitLead">Concluir Cadastro</v-btn>
                      <div v-else class="submit-loading flex-grow-1 rounded-xl"><v-progress-circular indeterminate size="24" width="3" color="primary" /></div>
                    </div>
                  </div>
                </transition>
              </div>

            </transition>
          </div>
        </main>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useTheme } from 'vuetify'
import { supabase } from '@/api/supabase'
import { vMaska } from 'maska/vue'

import LogoDark from '@/assets/logo.png'
import LogoLight from '@/assets/logomjlm.png'

import Stamp1 from '@/assets/1.jpg'
import Stamp2 from '@/assets/2.jpg'
import Stamp3 from '@/assets/3.jpg'
import Stamp4 from '@/assets/4.jpg'
import Stamp5 from '@/assets/5.jpg'

const theme = useTheme()
const router = useRouter()
const isDark = computed(() => theme.global.name.value === 'dark')
const currentLogo = computed(() => (isDark.value ? LogoDark : LogoLight))

const stampImages = [Stamp1, Stamp2, Stamp3, Stamp4, Stamp5]
const getStamp = (index: number) => stampImages[index % stampImages.length]

const isLoading = ref(true)
const isSubmitting = ref(false)
const isSearchingCnpj = ref(false)

const authMode = ref<'login' | 'register' | 'forgot_password' | 'onboarding' | 'welcome_boot'>('login')
const onboardingStep = ref(1)

const authError = ref('')
const authSuccess = ref('')
const onboardingError = ref('')
const cnpjError = ref('')

const currentUser = ref<any>(null)
const currentLead = ref<any>(null)

const authForm = ref({ email: '', password: '', confirmPassword: '' })
const leadForm = ref({ name: '', document: '', phone: '', location: '', instagram: '', discovery_source: '' })
const discoverySources = ['Instagram', 'Busca no Google', 'Indicação / Amigo', 'Representante', 'Outros']

const passwordsMatch = computed(() => {
  if (authMode.value !== 'register') return true
  if (!authForm.value.confirmPassword) return true
  return authForm.value.password === authForm.value.confirmPassword
})

const toggleTheme = () => {
  const newTheme = isDark.value ? 'light' : 'dark'
  if (typeof (theme as any).change === 'function') {
    (theme as any).change(newTheme)
  } else {
    theme.global.name.value = newTheme
  }
  localStorage.setItem('mj_theme', newTheme)
}

onMounted(async () => {
  isLoading.value = true
  const savedTheme = localStorage.getItem('mj_theme')
  if (savedTheme === 'dark' || savedTheme === 'light') {
    if (typeof (theme as any).change === 'function') {
      (theme as any).change(savedTheme)
    } else {
      theme.global.name.value = savedTheme
    }
  }

  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      await checkUserLead(session.user)
    }

    supabase.auth.onAuthStateChange(async (event, session) => {
      if (session && event === 'SIGNED_IN') {
        await checkUserLead(session.user)
      }
    })
  } catch (error) {
    console.error('Erro de sessão:', error)
  } finally {
    isLoading.value = false
  }
})

function toggleAuthMode() {
  authMode.value = authMode.value === 'login' ? 'register' : 'login'
  authError.value = ''
  authSuccess.value = ''
  authForm.value.password = ''
  authForm.value.confirmPassword = ''
}

// CENTRALIZADOR DE VALIDAÇÃO DE ACESSO
async function checkUserLead(user: any) {
  currentUser.value = user
  const { data: leadData } = await supabase.from('public_leads').select('*').eq('email', user.email).maybeSingle()
  currentLead.value = leadData

  const { data: profile } = await supabase.from('profiles').select('role, full_name').eq('id', user.id).maybeSingle()
  const isInternalCollaborator = profile && ['admin', 'vendedor', 'designer', 'producao', 'financeiro', 'super_admin'].includes(profile.role)

  // 1. Verificação de Dados Complementares (Gatekeeper)
  // Se o usuário não tem CNPJ ou Nome, ele PRECISA passar pelo onboarding, independente de ser Google ou Email
  if (!leadData || !leadData.document || !leadData.name) {
    // Exceção: Colaboradores MJ recebem bypass automático
    if (isInternalCollaborator) {
        const futureDate = new Date();
        futureDate.setFullYear(futureDate.getFullYear() + 10);
        const bypassCode = 'TEAM-MJ';

        const { data: newLead } = await supabase.from('public_leads').upsert({
            email: user.email,
            name: profile.full_name || 'Colaborador MJ',
            document: '00000000000',
            phone: '00000000000',
            location: 'Interno',
            instagram: '@mjprocess',
            discovery_source: 'Equipe Interna',
            account_status: 'approved',
            access_status: 'active',
            design_access_status: 'granted',
            temp_auth_code: bypassCode,
            temp_auth_expires_at: futureDate.toISOString()
        }, { onConflict: 'email' }).select('*').single();

        if (newLead) {
            localStorage.setItem('mj_active_code', bypassCode);
            router.push('/marketplace')
            return;
        }
    }

    // Usuário comum sem dados -> Força Onboarding
    authMode.value = 'onboarding'
    onboardingStep.value = 1
    return
  }

  // 2. Cadastro OK -> Login Liberado
  if (isInternalCollaborator) {
      const bypassCode = 'TEAM-MJ';
      localStorage.setItem('mj_active_code', bypassCode);
  }
  router.push('/marketplace')
}

async function handleEmailAuth() {
  authError.value = ''
  authSuccess.value = ''
  if (!authForm.value.email || !authForm.value.password) return
  if (authMode.value === 'register' && !passwordsMatch.value) { authError.value = 'Senhas não coincidem.'; return }

  isSubmitting.value = true
  try {
    if (authMode.value === 'login') {
      const { error } = await supabase.auth.signInWithPassword({ email: authForm.value.email, password: authForm.value.password })
      if (error) throw error
    } else {
      const { error, data } = await supabase.auth.signUp({ email: authForm.value.email, password: authForm.value.password })
      if (error) throw error
      // Para cadastros novos via e-mail, atualiza o currentUser para o submitLead usar
      if(data.user) currentUser.value = data.user
    }
  } catch (error: any) {
    authError.value = 'Erro: ' + (error.message.includes('Invalid login') ? 'Credenciais incorretas' : error.message)
    isSubmitting.value = false
  }
}

async function handleForgotPassword() {
  authError.value = ''
  if (!authForm.value.email) { authError.value = 'Informe seu e-mail.'; return }
  isSubmitting.value = true
  try {
    const { error } = await supabase.auth.resetPasswordForEmail(authForm.value.email, { redirectTo: window.location.origin + '/marketplace-login' })
    if (error) throw error
    authSuccess.value = 'Link enviado! Verifique seu e-mail.'
  } catch (error: any) { authError.value = 'Erro: ' + error.message }
  finally { isSubmitting.value = false }
}

async function loginSocial(provider: 'google') {
  await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: window.location.origin + '/marketplace-login' } })
}

const buscarCnpj = async () => {
  const cnpj = leadForm.value.document?.replace(/\D/g, '')
  if(!cnpj || cnpj.length !== 14) { cnpjError.value = 'CNPJ inválido'; return }
  isSearchingCnpj.value = true
  cnpjError.value = ''

  try {
    let foundData = null;
    try {
      const res1 = await fetch(`https://publica.cnpj.ws/cnpj/${cnpj}`)
      if (res1.ok) {
        const json1 = await res1.json()
        foundData = {
          name: json1.razao_social,
          phone: `${json1.estabelecimento?.ddd1 || ''}${json1.estabelecimento?.telefone1 || ''}`,
          location: `${json1.estabelecimento?.cidade?.nome || ''} / ${json1.estabelecimento?.estado?.sigla || ''}`
        }
      }
    } catch (e1) { console.warn('CNPJ.ws falhou') }

    if (!foundData) {
      const res3 = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`)
      if (res3.ok) {
        const json3 = await res3.json()
        foundData = {
          name: json3.razao_social,
          phone: json3.ddd_telefone_1 || '',
          location: `${json3.municipio || ''} / ${json3.uf || ''}`
        }
      }
    }

    if (foundData) {
      leadForm.value.name = foundData.name
      leadForm.value.phone = foundData.phone.replace(/\D/g, '')
      leadForm.value.location = foundData.location
      setTimeout(() => { onboardingStep.value = 2 }, 600)
    } else {
        throw new Error('Empresa não encontrada ou falha nos serviços da Receita.')
    }
  } catch(e: any) {
    cnpjError.value = e.message
  } finally {
    isSearchingCnpj.value = false
  }
}

async function submitLead() {
  onboardingError.value = ''
  if (!leadForm.value.name || !leadForm.value.document || !leadForm.value.instagram) return

  // Garantia de Sessão
  if (!currentUser.value?.email) {
      onboardingError.value = 'Sessão expirada. Reinicie o login.'
      isSubmitting.value = false
      return
  }

  isSubmitting.value = true

  const payload = {
    email: String(currentUser.value.email),
    name: String(leadForm.value.name),
    document: String(leadForm.value.document),
    phone: String(leadForm.value.phone).replace(/\D/g, ''),
    location: String(leadForm.value.location),
    discovery_source: String(leadForm.value.discovery_source),
    instagram: String(leadForm.value.instagram),
    account_status: 'approved',
    access_status: 'active'
  }

  try {
    // 1. Verificações de Conflito
    const { data: docConflict } = await supabase.from('public_leads').select('id').eq('document', payload.document).neq('email', payload.email).maybeSingle();
    if (docConflict) throw new Error("CNPJ já cadastrado em outra conta.");

    const { data: instaConflict } = await supabase.from('public_leads').select('id').eq('instagram', payload.instagram).neq('email', payload.email).maybeSingle();
    if (instaConflict) throw new Error("Instagram já cadastrado em outra conta.");

    // 2. Salvamento Persistente
    const { error } = await supabase.from('public_leads').upsert(payload, { onConflict: 'email' });
    if (error) throw error;

    // 3. Finalização e Redirecionamento
    authMode.value = 'welcome_boot'
    setTimeout(() => { router.push('/marketplace') }, 2500)
  } catch (error: any) {
    onboardingError.value = error.message
    isSubmitting.value = false
  }
}
</script>

<style scoped>
/* VARIABLES & RESET */
.mj-auth-shell {
  min-height: 100vh;
  width: 100%;
  font-family: 'Inter', sans-serif;
  transition: background-color 0.3s ease;
  background: var(--bg-main);
  color: var(--text-main);
}

/* THEME: DARK */
.theme-dark {
  --bg-main: #000;
  --bg-surface: #09090b;
  --bg-surface-variant: #18181b;
  --text-main: #fafafa;
  --text-soft: #a1a1aa;
  --text-muted: #8f98a8;
  --border-color: #27272a;
  --border-focus: #3f3f46;
}

/* THEME: LIGHT */
.theme-light {
  --bg-main: #fff;
  --bg-surface: #fff;
  --bg-surface-variant: #f4f4f5;
  --text-main: #09090b;
  --text-soft: #52525b;
  --text-muted: #6d7890;
  --border-color: #e4e4e7;
  --border-focus: #d4d4d8;
}

/* BOOT SCREEN */
.boot-screen {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: var(--bg-main);
  display: flex;
  align-items: center;
  justify-content: center;
}
.boot-box {
  width: 240px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  align-items: center;
}
.boot-logo {
  height: 48px;
  object-fit: contain;
}
.boot-line {
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-primary), 0.8), transparent);
  border-radius: 4px;
  animation: pulseLine 1.5s infinite ease-in-out;
}
.boot-text {
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  text-transform: uppercase;
}
@keyframes pulseLine {
  0%, 100% { opacity: 0.3; transform: scaleX(0.8); }
  50% { opacity: 1; transform: scaleX(1); }
}

/* WELCOME SCREEN (AFTER ONBOARDING) */
.welcome-fullscreen {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: #000; /* Sempre escuro na entrada triunfal */
  display: flex;
  align-items: center;
  justify-content: center;
}
.welcome-content-minimal {
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.welcome-title-minimal {
  color: #a1a1aa;
  font-size: 0.9rem;
  letter-spacing: 0.4em;
  margin-bottom: 12px;
  font-weight: 500;
}
.welcome-name-minimal {
  color: #fff;
  font-size: 3.5rem;
  font-weight: 300;
  letter-spacing: 0.1em;
  line-height: 1;
}
.welcome-loader {
  width: 60px;
  height: 2px;
  background: rgba(255,255,255,0.1);
  position: relative;
  overflow: hidden;
  margin-top: 40px;
  border-radius: 2px;
}
.welcome-loader::after {
  content: '';
  position: absolute;
  inset: 0;
  width: 40%;
  background: #fff;
  animation: slideLoader 1.5s infinite cubic-bezier(0.4, 0, 0.2, 1);
}
@keyframes slideLoader {
  0% { transform: translateX(-150%); }
  100% { transform: translateX(350%); }
}

/* LAYOUT MACRO */
.auth-layout {
  display: grid;
  grid-template-columns: 1fr;
  min-height: 100vh;
}
@media (min-width: 960px) {
  .auth-layout {
    grid-template-columns: 1.2fr 1fr;
  }
}

/* LADO ESQUERDO: VISUAL / SCROLLING STAMPS */
.auth-visual {
  position: relative;
  background: #000;
  overflow: hidden;
}
.scrolling-grid {
  position: absolute;
  inset: -20%;
  display: flex;
  gap: 24px;
  transform: rotate(-8deg) scale(1.1);
  opacity: 0.8;
}
.scroll-track {
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 33.333%;
}
.stamp-wrapper {
  width: 100%;
  border-radius: 16px;
  overflow: hidden;
  background: #111;
}
.scroll-img {
  width: 100%;
  display: block;
  aspect-ratio: 3/4;
  object-fit: cover;
}
.auth-visual-fade {
  position: absolute;
  inset: 0;
  background: linear-gradient(0deg, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.4) 50%, rgba(0,0,0,0.1) 100%);
}
.auth-visual-content {
  position: absolute;
  bottom: 80px;
  left: 64px;
  right: 64px;
  z-index: 10;
}
.premium-badge {
  display: inline-flex;
  align-items: center;
  padding: 6px 12px;
  background: rgba(255,255,255,0.1);
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 999px;
  color: #fff;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.05em;
  backdrop-filter: blur(10px);
}
.display-title {
  font-size: clamp(3rem, 5vw, 4.5rem);
  font-weight: 800;
  color: #fff;
  line-height: 1.1;
  letter-spacing: -0.02em;
}
.display-copy {
  margin-top: 16px;
  font-size: 1.1rem;
  color: #a1a1aa;
  max-width: 480px;
  line-height: 1.6;
}

/* LADO DIREITO: PAINEL DE LOGIN */
.auth-panel {
  display: flex;
  flex-direction: column;
  padding: 32px 24px;
  background: var(--bg-surface);
  position: relative;
}
@media (min-width: 960px) {
  .auth-panel {
    padding: 48px 64px;
    justify-content: center;
  }
}
.auth-card {
  width: 100%;
  max-width: 420px;
  margin: 0 auto;
}

/* TOPBAR DO PAINEL */
.auth-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.brand-logo {
  height: 32px;
  object-fit: contain;
}
.theme-toggle {
  color: var(--text-muted);
}

/* TYPOGRAPHY SECTION */
.section-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.02em;
  line-height: 1.2;
}
.section-copy {
  font-size: 0.95rem;
  color: var(--text-muted);
  margin-top: 8px;
}

/* FORMS & INPUTS */
.auth-form {
  display: flex;
  flex-direction: column;
}
.field-group {
  display: flex;
  flex-direction: column;
}
.field-label {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 8px;
}
.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}
.input-icon {
  position: absolute;
  left: 16px;
  color: var(--text-muted);
  font-size: 20px;
  pointer-events: none;
}
.mj-input {
  width: 100%;
  height: 52px;
  background: var(--bg-surface-variant);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  color: var(--text-main);
  font-size: 0.95rem;
  transition: all 0.2s ease;
  outline: none;
}
.mj-input.with-icon {
  padding-left: 48px;
  padding-right: 16px;
}
.mj-input:not(.with-icon) {
  padding: 0 16px;
}
.mj-input:focus {
  border-color: rgb(var(--v-theme-primary));
  box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.1);
}
.mj-input:disabled, .mj-input.read-only-input {
  opacity: 0.7;
  cursor: not-allowed;
  background: var(--bg-surface);
}
.mj-input.input-error {
  border-color: rgb(var(--v-theme-error));
}
.error-text {
  color: rgb(var(--v-theme-error));
  font-size: 0.8rem;
  font-weight: 500;
}

.forgot-link, .switch-link {
  font-size: 0.85rem;
  font-weight: 600;
  color: rgb(var(--v-theme-primary));
  text-decoration: none;
  transition: opacity 0.2s;
}
.forgot-link:hover, .switch-link:hover {
  opacity: 0.8;
  text-decoration: underline;
}
.text-muted-custom {
  color: var(--text-muted);
}

.cta-btn {
  height: 52px !important;
  border-radius: 12px !important;
  font-weight: 700 !important;
  letter-spacing: 0.02em !important;
  text-transform: none !important;
}
.submit-loading {
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-surface-variant);
  border-radius: 12px;
}

/* DIVIDER */
.divider-container {
  display: flex;
  align-items: center;
  margin: 32px 0;
}
.divider-line {
  flex: 1;
  height: 1px;
  background: var(--border-color);
}
.divider-text {
  padding: 0 16px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.1em;
}

/* SOCIAL BTN */
.social-btn {
  border-radius: 12px !important;
  border-color: var(--border-color) !important;
  color: var(--text-main) !important;
  font-weight: 600 !important;
  text-transform: none !important;
  letter-spacing: 0 !important;
}

/* ONBOARDING TIMELINE */
.timeline-header {
  position: relative;
}
.timeline-track {
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--border-color);
  transform: translateY(-50%);
  z-index: 1;
}
.timeline-progress {
  height: 100%;
  background: rgb(var(--v-theme-primary));
  transition: width 0.4s ease;
}
.timeline-steps {
  position: relative;
  z-index: 2;
  display: flex;
  justify-content: space-between;
}
.step-dot {
  width: 32px;
  height: 32px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  background: var(--bg-surface);
  border: 2px solid var(--border-color);
  color: var(--text-muted);
  font-weight: 700;
  font-size: 13px;
  transition: all 0.3s ease;
}
.step-dot.active {
  background: rgb(var(--v-theme-primary));
  border-color: rgb(var(--v-theme-primary));
  color: #fff;
}
.source-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.source-card { height: 56px; border-radius: 12px; background: var(--bg-surface); border: 1px solid var(--border-color); font-weight: 600; font-size: 0.9rem; color: var(--text-soft); transition: all 0.2s ease; cursor: pointer; }
.source-card:hover { border-color: var(--border-focus); }
.source-card.active { background: rgba(var(--v-theme-primary), 0.05); color: rgb(var(--v-theme-primary)); border-color: rgb(var(--v-theme-primary)); }

.scroll-track.down { animation: scrollDown 70s linear infinite; }
.scroll-track.up { animation: scrollUp 70s linear infinite; }
@keyframes scrollDown { from { transform: translateY(-50%); } to { transform: translateY(0%); } }
@keyframes scrollUp { from { transform: translateY(0%); } to { transform: translateY(-50%); } }

.fade-enter-active, .fade-leave-active { transition: opacity 0.5s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.fade-slide-enter-from { opacity: 0; transform: translateY(10px); }
.fade-slide-leave-to { opacity: 0; transform: translateY(-10px); }
.slide-x-enter-active, .slide-x-leave-active { transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
.slide-x-enter-from { opacity: 0; transform: translateX(20px); }
.slide-x-leave-to { opacity: 0; transform: translateX(-20px); }
</style>
