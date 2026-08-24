document.addEventListener('DOMContentLoaded', () => {
  const toggleBtn = document.getElementById('toggleBtn');
  const statusText = document.getElementById('statusText');

  chrome.storage.local.get(['bubbleEnabled'], (data) => {
    const isEnabled = data.bubbleEnabled !== false;
    updateUI(isEnabled);
  });

  toggleBtn.addEventListener('click', () => {
    chrome.storage.local.get(['bubbleEnabled'], (data) => {
      const currentlyEnabled = data.bubbleEnabled !== false;
      const nextState = !currentlyEnabled;

      chrome.storage.local.set({ bubbleEnabled: nextState }, () => {
        updateUI(nextState);

        const actionMessage = nextState ? 'SHOW_BUBBLE' : 'HIDE_BUBBLE';
        chrome.tabs.query({}, (tabs) => {
          tabs.forEach((tab) => {
            if (tab.id) {
              chrome.tabs.sendMessage(tab.id, { action: actionMessage }).catch(() => {});
            }
          });
        });
      });
    });
  });

  function updateUI(isEnabled) {
    if (isEnabled) {
      statusText.innerText = "Floating bubble is currently ON (Visible on all pages)";
      toggleBtn.innerText = "TURN OFF FLOATING BUBBLE";
      toggleBtn.className = "toggle-btn";
    } else {
      statusText.innerText = "Floating bubble is currently OFF (Hidden)";
      toggleBtn.innerText = "TURN ON FLOATING BUBBLE";
      toggleBtn.className = "toggle-btn off";
    }
  }
});
