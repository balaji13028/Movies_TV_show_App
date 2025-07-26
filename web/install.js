// let deferredPrompt;

// window.addEventListener('beforeinstallprompt', (e) => {
//     e.preventDefault();
//     deferredPrompt = e;
//     window.dispatchEvent(new Event('deferredPromptReady'));
// });

// window.promptInstall = function() {
//     if (deferredPrompt) {
//         deferredPrompt.prompt();
//         deferredPrompt.userChoice.then((choiceResult) => {
//             if (choiceResult.outcome === 'accepted') {
//                 console.log('User accepted the A2HS prompt');
//             } else {
//                 console.log('User dismissed the A2HS prompt');
//             }
//             deferredPrompt = null;
//         });
//     }
// };


// <!-- Capture PWA install prompt event -->
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    deferredPrompt = e;
});

function promptInstall() {
    deferredPrompt.prompt();
}

// Listen for app install event
window.addEventListener('appinstalled', () => {
    deferredPrompt = null;
    appInstalled();
});

// Track how PWA was launched (either from browser or as PWA)
function getLaunchMode() {
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
    if (deferredPrompt) hasPrompt();
    if (document.referrer.startsWith('android-app://')) {
        appLaunchedAsTWA();
    } else if (navigator.standalone || isStandalone) {
        appLaunchedAsPWA();
    } else {
        window.appLaunchedInBrowser();
    }
}
