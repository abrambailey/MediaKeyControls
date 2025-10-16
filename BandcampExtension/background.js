// Background service worker - handles native messaging
console.log('[Bandcamp Controls] Background script loaded');

let port = null;
let lastActiveTabId = null; // Track the last tab that successfully responded
let lastUpdateTime = 0; // Track when we last updated the active tab

// Restore last active tab from storage
chrome.storage.session.get(['lastActiveTabId'], (result) => {
  if (result.lastActiveTabId) {
    lastActiveTabId = result.lastActiveTabId;
    console.log('[Bandcamp Controls] 💾 Restored last active tab:', lastActiveTabId);
  }
});

// Track tab activations
chrome.tabs.onActivated.addListener((activeInfo) => {
  chrome.tabs.get(activeInfo.tabId, (tab) => {
    if (tab && tab.url && tab.url.includes('bandcamp.com')) {
      console.log('[Bandcamp Controls] 👆 User activated Bandcamp tab:', activeInfo.tabId, 'URL:', tab.url);
    }
  });
});

// Track tab updates (URL changes, etc.)
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url && changeInfo.url.includes('bandcamp.com')) {
    console.log('[Bandcamp Controls] 🔄 Bandcamp tab updated:', tabId, 'New URL:', changeInfo.url);
  }
});

// Connect to native messaging host
function connectNative() {
  console.log('[Bandcamp Controls] Connecting to native host...');

  try {
    port = chrome.runtime.connectNative('com.bandcamp.controls');

    port.onMessage.addListener((message) => {
      console.log('[Bandcamp Controls] 📨 Received from native:', message);

      // Try active Bandcamp tab first, then last active, then any Bandcamp tab
      chrome.tabs.query({ url: '*://*.bandcamp.com/*', active: true, currentWindow: true }, (activeTabs) => {
        console.log('[Bandcamp Controls] 🔍 Query results - Active Bandcamp tabs:', activeTabs.length);

        if (activeTabs.length > 0) {
          console.log('[Bandcamp Controls] ✅ Using currently active tab:', activeTabs[0].id, 'URL:', activeTabs[0].url);
          sendToTab(activeTabs[0].id, message);
        } else {
          // No active Bandcamp tab - try to find the right one
          chrome.tabs.query({ url: '*://*.bandcamp.com/*' }, (allTabs) => {
            console.log('[Bandcamp Controls] 🔍 Query results - All Bandcamp tabs:', allTabs.length);
            allTabs.forEach((tab, index) => {
              console.log(`[Bandcamp Controls]   Tab ${index}: ID=${tab.id}, URL=${tab.url}, Title="${tab.title}"`);
            });

            if (allTabs.length === 0) {
              console.log('[Bandcamp Controls] ❌ No Bandcamp tabs found');
              if (port) {
                port.postMessage({ success: false, message: 'No Bandcamp tab open' });
              }
              return;
            }

            // Strategy: Try last active tab first, then find best candidate
            let targetTab = null;
            let selectionReason = '';

            // 1. Try the last tab that successfully responded
            if (lastActiveTabId) {
              targetTab = allTabs.find(t => t.id === lastActiveTabId);
              if (targetTab) {
                selectionReason = `last active tab (ID: ${lastActiveTabId})`;
                console.log('[Bandcamp Controls] 💡 Selected by strategy 1:', selectionReason);
              } else {
                console.log('[Bandcamp Controls] ⚠️ Last active tab', lastActiveTabId, 'not found in current tabs');
              }
            }

            // 2. If no last active, look for a tab that appears to be playing
            if (!targetTab) {
              targetTab = allTabs.find(t => t.title && (t.title.includes('▶') || t.title.includes('🎵')));
              if (targetTab) {
                selectionReason = `playing indicator in title: "${targetTab.title}"`;
                console.log('[Bandcamp Controls] 💡 Selected by strategy 2:', selectionReason);
              }
            }

            // 3. Fall back to most recently accessed tab
            if (!targetTab && allTabs.length > 0) {
              targetTab = allTabs[0];
              selectionReason = `most recent tab (first in list)`;
              console.log('[Bandcamp Controls] 💡 Selected by strategy 3:', selectionReason);
            }

            if (targetTab) {
              console.log('[Bandcamp Controls] 🎯 Final selection - Tab:', targetTab.id, 'URL:', targetTab.url, 'Reason:', selectionReason);
              console.log('[Bandcamp Controls] 🔄 Activating tab...');

              chrome.tabs.update(targetTab.id, { active: true }, () => {
                console.log('[Bandcamp Controls] ✅ Tab activated, waiting 50ms...');
                setTimeout(() => {
                  sendToTab(targetTab.id, message);
                }, 50);
              });
            }
          });
        }
      });
    });

    function sendToTab(tabId, message) {
      console.log('[Bandcamp Controls] 📤 Sending message to tab:', tabId, 'Message:', message);
      chrome.tabs.sendMessage(tabId, message, (response) => {
        if (chrome.runtime.lastError) {
          console.error('[Bandcamp Controls] ❌ Error sending to tab', tabId, ':', chrome.runtime.lastError.message);

          // Don't clear lastActiveTabId immediately - might just be a timing issue
          // Only clear if tab is definitely gone
          chrome.tabs.get(tabId, (tab) => {
            if (chrome.runtime.lastError || !tab) {
              console.log('[Bandcamp Controls] 🗑️ Tab', tabId, 'no longer exists, clearing from memory');
              if (lastActiveTabId === tabId) {
                console.log('[Bandcamp Controls] 💾 Clearing lastActiveTabId from storage');
                lastActiveTabId = null;
                chrome.storage.session.remove(['lastActiveTabId']);
              }
            } else {
              console.log('[Bandcamp Controls] ℹ️ Tab', tabId, 'still exists but content script not responding (URL:', tab.url, ')');
            }
          });
          if (port) {
            port.postMessage({ success: false, message: chrome.runtime.lastError.message });
          }
        } else {
          console.log('[Bandcamp Controls] ✅ Content script response from tab', tabId, ':', response);

          // Track successful tab and update timestamp
          if (response && response.success) {
            const now = Date.now();
            const timeSinceLastUpdate = now - lastUpdateTime;
            const isNewTab = lastActiveTabId !== tabId;

            if (isNewTab || timeSinceLastUpdate > 1000) {
              const oldTabId = lastActiveTabId;
              lastActiveTabId = tabId;
              lastUpdateTime = now;
              chrome.storage.session.set({ lastActiveTabId: tabId });

              if (isNewTab) {
                console.log('[Bandcamp Controls] 💾 Updated last active tab:', oldTabId, '→', tabId);
              } else {
                console.log('[Bandcamp Controls] 💾 Refreshed last active tab timestamp for tab:', tabId);
              }
            }
          } else {
            console.log('[Bandcamp Controls] ⚠️ Response success was false or undefined');
          }

          if (port) {
            port.postMessage(response || { success: true, message: 'Success' });
          }
        }
      });
    }

    port.onDisconnect.addListener(() => {
      console.log('[Bandcamp Controls] Disconnected from native host');
      port = null;
      // Try to reconnect after a delay
      setTimeout(connectNative, 2000);
    });

    console.log('[Bandcamp Controls] Connected to native host');
  } catch (error) {
    console.error('[Bandcamp Controls] Failed to connect:', error);
    // Retry after delay
    setTimeout(connectNative, 2000);
  }
}

// Start connection when extension loads
connectNative();

// Listen for content script ready messages
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'contentScriptReady') {
    console.log('[Bandcamp Controls] Content script ready in tab:', sender.tab.id);
  }
});
