function getActivityFromUrl(url) {
  if (!url) return null;
  try {
    const hostname = new URL(url).hostname;
    if (hostname.includes('youtube.com')) return 'Assistindo YouTube';
    if (hostname.includes('netflix.com')) return 'Assistindo Netflix';
    if (hostname.includes('spotify.com')) return 'Ouvindo Spotify';
    if (hostname.includes('github.com')) return 'No GitHub';
    return `Navegando em ${hostname.replace('www.', '')}`;
  } catch (error) {
    return null;
  }
}

async function updateActivity(activity) {
  const { supabaseToken } = await chrome.storage.local.get('supabaseToken');

  // ========================================================================
  //    COLE SUA URL DO ARQUIVO .ENV AQUI
  // ========================================================================
  const SUPABASE_URL = "https://drprfuinwglmzquqtqzq.supabase.co"; // <-- COLE A SUA VITE_SUPABASE_URL AQUI
  // ========================================================================

  const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/update-activity`;

  if (!supabaseToken || !activity) return;

  try {
    await fetch(EDGE_FUNCTION_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseToken}`
      },
      body: JSON.stringify({ activity: activity })
    });
  } catch (error) {
    console.error('Erro ao atualizar atividade:', error);
  }
}

chrome.tabs.onActivated.addListener(activeInfo => {
  chrome.tabs.get(activeInfo.tabId, (tab) => {
    if (tab && tab.url) {
      const activity = getActivityFromUrl(tab.url);
      if (activity) {
        updateActivity(activity);
      }
    }
  });
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.active && tab.url) {
    const activity = getActivityFromUrl(tab.url);
    if (activity) {
      updateActivity(activity);
    }
  }
});
