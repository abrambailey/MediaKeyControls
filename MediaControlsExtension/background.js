// Background service worker - handles native messaging
console.log('[Media Controls] Background script loaded');

let port = null;
let lastActiveTabId = null; // Track the last tab that successfully responded
let lastUpdateTime = 0; // Track when we last updated the active tab

// Restore last active tab from storage
chrome.storage.session.get(['lastActiveTabId'], (result) => {
  if (result.lastActiveTabId) {
    lastActiveTabId = result.lastActiveTabId;
    console.log('[Media Controls] 💾 Restored last active tab:', lastActiveTabId);
  }
});

// Track tab activations
chrome.tabs.onActivated.addListener((activeInfo) => {
  chrome.tabs.get(activeInfo.tabId, (tab) => {
    if (tab && tab.url && (tab.url.includes('bandcamp.com') || tab.url.includes('youtube.com/watch'))) {
      console.log('[Media Controls] 👆 User activated media tab:', activeInfo.tabId, 'URL:', tab.url);
    }
  });
});

// Track tab updates (URL changes, etc.)
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url && (changeInfo.url.includes('bandcamp.com') || changeInfo.url.includes('youtube.com/watch'))) {
    console.log('[Media Controls] 🔄 Media tab updated:', tabId, 'New URL:', changeInfo.url);
  }
});

// Connect to native messaging host
function connectNative() {
  console.log('[Media Controls] Connecting to native host...');

  try {
    port = chrome.runtime.connectNative('com.mediakeycontrols');

    port.onMessage.addListener((message) => {
      console.log('[Media Controls] 📨 Received from native:', message);

      // Try active media tab first, then last active, then any media tab
      chrome.tabs.query({ url: ['*://*.bandcamp.com/*', '*://*.youtube.com/watch*'], active: true, currentWindow: true }, (activeTabs) => {
        console.log('[Media Controls] 🔍 Query results - Active media tabs:', activeTabs.length);

        if (activeTabs.length > 0) {
          console.log('[Media Controls] ✅ Using currently active tab:', activeTabs[0].id, 'URL:', activeTabs[0].url);
          sendToTab(activeTabs[0].id, message);
        } else {
          // No active media tab - try to find the right one
          chrome.tabs.query({ url: ['*://*.bandcamp.com/*', '*://*.youtube.com/watch*'] }, (allTabs) => {
            console.log('[Media Controls] 🔍 Query results - All media tabs:', allTabs.length);
            allTabs.forEach((tab, index) => {
              console.log(`[Media Controls]   Tab ${index}: ID=${tab.id}, URL=${tab.url}, Title="${tab.title}"`);
            });

            if (allTabs.length === 0) {
              console.log('[Media Controls] ❌ No media tabs found');
              if (port) {
                port.postMessage({ success: false, message: 'No media tab open' });
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

              // Save the currently active tab so we can return to it
              chrome.tabs.query({ active: true, currentWindow: true }, (currentTabs) => {
                const previousTab = currentTabs.length > 0 ? currentTabs[0] : null;
                const needsSwitch = previousTab && previousTab.id !== targetTab.id;

                if (needsSwitch) {
                  console.log('[Bandcamp Controls] 💾 Saving current tab:', previousTab.id, 'URL:', previousTab.url);
                  console.log('[Bandcamp Controls] 🔄 Switching to media tab...');
                }

                chrome.tabs.update(targetTab.id, { active: true }, () => {
                  console.log('[Bandcamp Controls] ✅ Tab activated, waiting 50ms...');
                  setTimeout(() => {
                    sendToTab(targetTab.id, message, () => {
                      // After command is sent, switch back to original tab
                      if (needsSwitch && previousTab) {
                        setTimeout(() => {
                          chrome.tabs.update(previousTab.id, { active: true }, () => {
                            console.log('[Bandcamp Controls] ⬅️ Switched back to original tab:', previousTab.id);
                          });
                        }, 100); // Small delay to ensure command executed
                      }
                    });
                  }, 50);
                });
              });
            }
          });
        }
      });
    });

    function sendToTab(tabId, message, callback) {
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

        // Call the callback if provided
        if (callback) {
          callback();
        }
      });
    }

    port.onDisconnect.addListener(() => {
      console.log('[Media Controls] Disconnected from native host');
      port = null;
      // Try to reconnect after a delay
      setTimeout(connectNative, 2000);
    });

    console.log('[Media Controls] Connected to native host');
  } catch (error) {
    console.error('[Media Controls] Failed to connect:', error);
    // Retry after delay
    setTimeout(connectNative, 2000);
  }
}

// Start connection when extension loads
connectNative();

// Listen for content script ready messages
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'contentScriptReady') {
    console.log('[Media Controls] Content script ready in tab:', sender.tab.id);
  }
});

// Periodically check playing state and notify native host
function checkPlayingState() {
  chrome.tabs.query({ url: ['*://*.bandcamp.com/*', '*://*.youtube.com/watch*'] }, (tabs) => {
    const hasTabs = tabs.length > 0;

    if (hasTabs) {
      // Check each tab for playing state
      let isAnyPlaying = false;
      let checkedCount = 0;

      if (tabs.length === 0) {
        notifyTabState(false, false);
        return;
      }

      tabs.forEach((tab) => {
        chrome.tabs.sendMessage(tab.id, { action: 'getPlayingState' }, (response) => {
          checkedCount++;
          if (response && response.isPlaying) {
            isAnyPlaying = true;
          }

          // Once we've checked all tabs, notify
          if (checkedCount === tabs.length) {
            notifyTabState(hasTabs, isAnyPlaying);
          }
        });
      });
    } else {
      notifyTabState(false, false);
    }
  });
}

function notifyTabState(hasTabs, isPlaying) {
  // Send notification to native host via distributed notifications
  // The native host will forward this to the main app
  if (port) {
    port.postMessage({
      type: 'tabState',
      hasTabs: hasTabs,
      isPlaying: isPlaying
    });
  }
  console.log('[Media Controls] 📊 Tab state - hasTabs:', hasTabs, 'isPlaying:', isPlaying);
}

// Check playing state every 2 seconds
setInterval(checkPlayingState, 2000);
// Also check immediately on load
checkPlayingState();
