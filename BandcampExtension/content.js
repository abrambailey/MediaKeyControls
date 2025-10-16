// Content script - runs on bandcamp.com pages
console.log('[Bandcamp Controls] Content script loaded');

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('[Bandcamp Controls] Received message:', message);

  if (message.action === 'playPause') {
    const button = document.querySelector('.playbutton');
    if (button) {
      button.click();
      console.log('[Bandcamp Controls] Clicked play/pause');
      sendResponse({ success: true, message: 'Clicked play/pause' });
    } else {
      console.log('[Bandcamp Controls] Play button not found');
      sendResponse({ success: false, message: 'Button not found' });
    }
  } else if (message.action === 'next') {
    const button = document.querySelector('.nextbutton');
    if (button && !button.classList.contains('hiddenelem')) {
      button.click();
      console.log('[Bandcamp Controls] Clicked next');
      sendResponse({ success: true, message: 'Clicked next' });
    } else {
      console.log('[Bandcamp Controls] Next button not available');
      sendResponse({ success: false, message: 'Next not available' });
    }
  } else if (message.action === 'previous') {
    const button = document.querySelector('.prevbutton');
    if (button && !button.classList.contains('hiddenelem')) {
      button.click();
      console.log('[Bandcamp Controls] Clicked previous');
      sendResponse({ success: true, message: 'Clicked previous' });
    } else {
      // Restart track by clicking progress bar
      const bar = document.querySelector('.progbar_empty');
      if (bar) {
        const rect = bar.getBoundingClientRect();
        const evt = new MouseEvent('click', {
          view: window,
          bubbles: true,
          cancelable: true,
          clientX: rect.left + 5,
          clientY: rect.top + 5
        });
        bar.dispatchEvent(evt);
        console.log('[Bandcamp Controls] Restarted track');
        sendResponse({ success: true, message: 'Restarted track' });
      } else {
        console.log('[Bandcamp Controls] Previous button not available');
        sendResponse({ success: false, message: 'Previous not available' });
      }
    }
  } else if (message.action === 'getPlayingState') {
    const button = document.querySelector('.playbutton');
    const isPlaying = button && button.classList.contains('playing');
    console.log('[Bandcamp Controls] Playing state:', isPlaying);
    sendResponse({ success: true, isPlaying: isPlaying });
  }

  return true; // Keep message channel open for async response
});

// Notify that we're ready
chrome.runtime.sendMessage({ type: 'contentScriptReady' });
