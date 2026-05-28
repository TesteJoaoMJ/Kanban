document.addEventListener('DOMContentLoaded', () => {
    // Referências aos elementos do HTML
    const loginView = document.getElementById('login-view');
    const statusView = document.getElementById('status-view');
    const tokenInput = document.getElementById('token-input');
    const saveButton = document.getElementById('save-button');
    const logoutButton = document.getElementById('logout-button');
    const userEmailSpan = document.getElementById('user-email');
    const messageArea = document.getElementById('message-area');

    // ========================================================================
    //    COLE SUAS CHAVES DO ARQUIVO .ENV AQUI
    // ========================================================================
    const SUPABASE_URL = "https://drprfuinwglmzquqtqzq.supabase.co"; // <-- COLE A SUA VITE_SUPABASE_URL AQUI
    const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRycHJmdWlud2dsbXpxdXF0cXpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2OTMyMzksImV4cCI6MjA2OTI2OTIzOX0.H2bhXrPMLxkfbvkyR6V5oPImd-RP-4dT2uBQLrbgVVc"; // <-- COLE A SUA VITE_SUPABASE_ANON_KEY AQUI
    // ========================================================================

    function showMessage(text, isError = false) {
        messageArea.textContent = text;
        messageArea.style.color = isError ? '#f44336' : '#4CAF50';
    }

    function updateView(isLoggedIn) {
        if (isLoggedIn) {
            loginView.classList.add('hidden');
            statusView.classList.remove('hidden');
        } else {
            loginView.classList.remove('hidden');
            statusView.classList.add('hidden');
            tokenInput.value = '';
        }
    }

    saveButton.addEventListener('click', () => {
        const token = tokenInput.value.trim();
        if (!token) {
            showMessage('Por favor, insira um token.', true);
            return;
        }
        chrome.storage.local.set({ supabaseToken: token }, () => {
            showMessage('Token salvo! A extensão está ativa.', false);
            checkLoginStatus();
        });
    });

    logoutButton.addEventListener('click', () => {
        chrome.storage.local.remove('supabaseToken', () => {
            userEmailSpan.textContent = '';
            showMessage('Desconectado com sucesso.', false);
            updateView(false);
        });
    });

    async function checkLoginStatus() {
        const result = await chrome.storage.local.get('supabaseToken');
        if (result.supabaseToken) {
            try {
                const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
                    headers: {
                        'apikey': SUPABASE_ANON_KEY,
                        'Authorization': `Bearer ${result.supabaseToken}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Token inválido ou expirado.');
                }

                const userData = await response.json();
                userEmailSpan.textContent = userData.email;
                updateView(true);

            } catch (error) {
                showMessage('Sessão expirada. Por favor, conecte-se novamente.', true);
                chrome.storage.local.remove('supabaseToken');
                updateView(false);
            }
        } else {
            updateView(false);
        }
    }

    checkLoginStatus();
});
