// Content script - runs on bandcamp.com and youtube.com pages
const isYouTube = window.location.hostname.includes('youtube.com');
const siteName = isYouTube ? 'YouTube' : 'Bandcamp';
console.log(`[Media Controls] Content script loaded on ${siteName}`);

// Site-specific selectors and logic
const handlers = {
  bandcamp: {
    playPause: () => {
      const button = document.querySelector('.playbutton');
      if (button) {
        button.click();
        return { success: true, message: 'Clicked play/pause' };
      }
      return { success: false, message: 'Button not found' };
    },
    next: () => {
      const button = document.querySelector('.nextbutton');
      if (button && !button.classList.contains('hiddenelem')) {
        button.click();
        return { success: true, message: 'Clicked next' };
      }
      return { success: false, message: 'Next not available' };
    },
    previous: () => {
      const button = document.querySelector('.prevbutton');
      if (button && !button.classList.contains('hiddenelem')) {
        button.click();
        return { success: true, message: 'Clicked previous' };
      }
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
        return { success: true, message: 'Restarted track' };
      }
      return { success: false, message: 'Previous not available' };
    },
    getPlayingState: () => {
      const button = document.querySelector('.playbutton');
      const isPlaying = button && button.classList.contains('playing');
      return { success: true, isPlaying: isPlaying };
    }
  },
  youtube: {
    playPause: () => {
      const button = document.querySelector('.ytp-play-button');
      if (button) {
        button.click();
        return { success: true, message: 'Clicked play/pause' };
      }
      return { success: false, message: 'Button not found' };
    },
    next: () => {
      const button = document.querySelector('.ytp-next-button');
      if (button && button.offsetParent !== null) {
        button.click();
        return { success: true, message: 'Clicked next' };
      }
      return { success: false, message: 'Next not available' };
    },
    previous: () => {
      const button = document.querySelector('.ytp-prev-button');
      if (button && button.offsetParent !== null) {
        button.click();
        return { success: true, message: 'Clicked previous' };
      }
      // Restart video by seeking to 0
      const video = document.querySelector('video');
      if (video) {
        video.currentTime = 0;
        return { success: true, message: 'Restarted video' };
      }
      return { success: false, message: 'Previous not available' };
    },
    getPlayingState: () => {
      const video = document.querySelector('video');
      const isPlaying = video && !video.paused;
      return { success: true, isPlaying: isPlaying };
    }
  }
};

const currentHandler = isYouTube ? handlers.youtube : handlers.bandcamp;

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log(`[Media Controls ${siteName}] Received message:`, message);

  let result;
  if (message.action === 'playPause') {
    result = currentHandler.playPause();
  } else if (message.action === 'next') {
    result = currentHandler.next();
  } else if (message.action === 'previous') {
    result = currentHandler.previous();
  } else if (message.action === 'getPlayingState') {
    result = currentHandler.getPlayingState();
  }

  if (result) {
    console.log(`[Media Controls ${siteName}] Result:`, result);
    sendResponse(result);
  }

  return true; // Keep message channel open for async response
});

// Notify that we're ready
chrome.runtime.sendMessage({ type: 'contentScriptReady' });

// Set up event listeners for playback state changes
function setupPlaybackListeners() {
  if (isYouTube) {
    // YouTube - listen to video element
    const video = document.querySelector('video');
    if (video) {
      video.addEventListener('play', () => {
        console.log(`[Media Controls ${siteName}] Play event detected`);
        chrome.runtime.sendMessage({
          type: 'playbackStateChanged',
          isPlaying: true,
          site: 'youtube'
        });
      });

      video.addEventListener('pause', () => {
        console.log(`[Media Controls ${siteName}] Pause event detected`);
        chrome.runtime.sendMessage({
          type: 'playbackStateChanged',
          isPlaying: false,
          site: 'youtube'
        });
      });

      console.log(`[Media Controls ${siteName}] Playback listeners attached to video element`);
    } else {
      // Video not ready yet, try again in a bit
      setTimeout(setupPlaybackListeners, 1000);
    }
  } else {
    // Bandcamp - watch for play button class changes
    const playButton = document.querySelector('.playbutton');
    if (playButton) {
      // Use MutationObserver to watch for class changes
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.attributeName === 'class') {
            const isPlaying = playButton.classList.contains('playing');
            console.log(`[Media Controls ${siteName}] Playback state changed: ${isPlaying}`);
            chrome.runtime.sendMessage({
              type: 'playbackStateChanged',
              isPlaying: isPlaying,
              site: 'bandcamp'
            });
          }
        });
      });

      observer.observe(playButton, { attributes: true });
      console.log(`[Media Controls ${siteName}] Playback listeners attached via MutationObserver`);
    } else {
      // Button not ready yet, try again in a bit
      setTimeout(setupPlaybackListeners, 1000);
    }
  }
}

// Start listening for playback changes
setupPlaybackListeners();
