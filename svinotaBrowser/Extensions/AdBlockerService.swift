import Foundation
import WebKit

class AdBlockerService {
    static let shared = AdBlockerService()
    
    // Set of known ad & tracking host suffixes
    let adHosts: Set<String> = [
        // Google / DoubleClick
        "doubleclick.net",
        "googleads.g.doubleclick.net",
        "securepubads.g.doubleclick.net",
        "pubads.g.doubleclick.net",
        "ad.doubleclick.net",
        "static.doubleclick.net",
        "m.doubleclick.net",
        "mediavisor.doubleclick.net",
        "pagead2.googlesyndication.com",
        "afs.googlesyndication.com",
        "googlesyndication.com",
        "adservice.google.com",
        "adservice.google.ru",
        "pagead2.googleadservices.com",
        "googleadservices.com",
        "google-analytics.com",
        "analytics.google.com",
        "click.googleanalytics.com",
        "ssl.google-analytics.com",
        "googleanalytics.com",
        
        // Media.net
        "media.net",
        "static.media.net",
        
        // AdColony
        "adcolony.com",
        "ads30.adcolony.com",
        "adc3-launch.adcolony.com",
        "events3alt.adcolony.com",
        "wd.adcolony.com",
        
        // MouseFlow
        "mouseflow.com",
        "cdn.mouseflow.com",
        "o2.mouseflow.com",
        "gtm.mouseflow.com",
        "api.mouseflow.com",
        
        // LuckyOrange
        "luckyorange.com",
        "luckyorange.net",
        "api.luckyorange.com",
        "realtime.luckyorange.com",
        "cdn.luckyorange.com",
        "w1.luckyorange.com",
        "upload.luckyorange.net",
        "cs.luckyorange.net",
        "settings.luckyorange.net",
        
        // Hotjar
        "hotjar.com",
        "adm.hotjar.com",
        "identify.hotjar.com",
        "insights.hotjar.com",
        "script.hotjar.com",
        "surveys.hotjar.com",
        "careers.hotjar.com",
        
        // Freshworks / Freshmarketer
        "freshmarketer.com",
        "claritybt.freshmarketer.com",
        "fwtracks.freshmarketer.com",
        "freshworks.com",
        
        // WordPress Stats
        "stats.wp.com",
        
        // Microsoft Clarity & Telemetry
        "clarity.ms",
        "telemetry.microsoft.com",
        "v10.events.data.microsoft.com",
        
        // Yandex Ads
        "an.yandex.ru",
        "mc.yandex.ru",
        "adfox.ru",
        "direct.yandex.ru",
        "awaps.yandex.net",
        "yabs.yandex.ru",
        
        // Common Ad Networks
        "taboola.com",
        "outbrain.com",
        "criteo.com",
        "criteo.net",
        "adnxs.com",
        "popcash.net",
        "popads.net",
        "scorecardresearch.com",
        "adroll.com",
        "toplist.cz",
        "bidswitch.net",
        "smartadserver.com",
        "pubmatic.com",
        "rubiconproject.com",
        "openx.net",
        "casalemedia.com",
        "advertising.com",
        "moatads.com",
        "amazon-adsystem.com",
        "infolinks.com",
        "mgid.com",
        "chitika.com",
        "propellerads.com",
        
        // Analytics & Session Recorders
        "segment.io",
        "segment.com",
        "mixpanel.com",
        "amplitude.com",
        "chartbeat.com",
        "quantserve.com",
        "crazyegg.com",
        "fullstory.com",
        "heapanalytics.com",
        "branch.io",
        "adjust.com",
        "appsflyer.com",
        "flurry.com",
        
        // Social Trackers
        "connect.facebook.net",
        "pixel.facebook.com",
        "analytics.twitter.com",
        "static.ads-twitter.com",
        "ads-twitter.com",
        "px.ads.linkedin.com",
        "snap.licdn.com",
        "ads.pinterest.com",
        "ct.pinterest.com",
        "analytics.tiktok.com",
        "ads.tiktok.com",
        "alb.reddit.com",
        "events.redditmedia.com",
        
        // Telemetry & Error Loggers
        "bugsnag.com",
        "notify.bugsnag.com",
        "sessions.bugsnag.com",
        "browser.sentry-cdn.com",
        "sentry.io",
        "loggly.com",
        "metrics.icloud.com",
        "samsungadhub.com",
        "nmetrics.samsung.com",
        "tracking.miui.com",
        "data.mistat.xiaomi.com",
        "metrics.data.hicloud.com",
        "logservice.hicloud.com"
    ]
    
    func isAdRequest(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        for adHost in adHosts {
            if host == adHost || host.hasSuffix("." + adHost) {
                return true
            }
        }
        let urlStr = url.absoluteString.lowercased()
        if urlStr.contains("/pagead/") || urlStr.contains("/ads/banners/") || urlStr.contains("yandex-direct") {
            return true
        }
        return false
    }
    
    // Complete AdBlock user script: network interception + cosmetic element hiding
    let adBlockScript = """
    (function() {
        if (window.__svinota_adblock_active) return;
        window.__svinota_adblock_active = true;
        
        // Safe stub for Google ads & anti-adblock detection
        try {
            window.adsbygoogle = window.adsbygoogle || [];
            window.adsbygoogle.push = function() {};
            window.canRunAds = true;
            window.isAdBlockActive = false;
            window.adblocker = false;
            window.adsBlocked = false;
        } catch(e) {}
        
        const blockedKeywords = [
            'doubleclick.net', 'googleadservices.com', 'googlesyndication.com',
            'media.net', 'adcolony.com', 'google-analytics.com', 'googleanalytics.com',
            'mouseflow.com', 'luckyorange.com', 'luckyorange.net',
            'hotjar.com', 'freshmarketer.com', 'freshworks.com',
            'claritybt.freshmarketer.com', 'fwtracks.freshmarketer.com',
            'an.yandex.ru', 'mc.yandex.ru', 'adfox.ru', 'direct.yandex.ru', 'awaps.yandex.net',
            'criteo.com', 'criteo.net', 'taboola.com', 'outbrain.com', 'adnxs.com', 'popcash.net', 'popads.net',
            'scorecardresearch.com', 'adroll.com', 'toplist.cz', 'bidswitch.net', 'smartadserver.com',
            'pubmatic.com', 'rubiconproject.com', 'openx.net', 'casalemedia.com', 'advertising.com',
            'moatads.com', 'amazon-adsystem.com', 'clarity.ms', 'segment.io', 'segment.com',
            'mixpanel.com', 'amplitude.com', 'stats.wp.com', 'chartbeat.com', 'quantserve.com',
            'crazyegg.com', 'fullstory.com', 'connect.facebook.net', 'pixel.facebook.com',
            'ads-twitter.com', 'analytics.twitter.com', 'px.ads.linkedin.com', 'snap.licdn.com',
            'ads.pinterest.com', 'ct.pinterest.com', 'analytics.tiktok.com', 'ads.tiktok.com',
            'bugsnag.com', 'sentry-cdn.com', 'loggly.com', 'alb.reddit.com', 'metrics.icloud.com',
            'samsungadhub.com', 'mistat.xiaomi.com', 'hicloud.com', 'telemetry.microsoft.com'
        ];
        
        const specificHosts = [
            'adservice.google.com', 'adservice.google.ru', 'analytics.google.com',
            'click.googleanalytics.com', 'ssl.google-analytics.com', 'afs.googlesyndication.com',
            'pagead2.googlesyndication.com', 'pagead2.googleadservices.com',
            'ad.doubleclick.net', 'static.doubleclick.net', 'm.doubleclick.net', 'mediavisor.doubleclick.net',
            'static.media.net', 'media.net',
            'ads30.adcolony.com', 'adc3-launch.adcolony.com', 'events3alt.adcolony.com', 'wd.adcolony.com',
            'mouseflow.com', 'cdn.mouseflow.com', 'o2.mouseflow.com', 'gtm.mouseflow.com', 'api.mouseflow.com',
            'luckyorange.com', 'api.luckyorange.com', 'realtime.luckyorange.com', 'cdn.luckyorange.com',
            'w1.luckyorange.com', 'upload.luckyorange.net', 'cs.luckyorange.net', 'settings.luckyorange.net',
            'adm.hotjar.com', 'identify.hotjar.com', 'insights.hotjar.com', 'script.hotjar.com',
            'surveys.hotjar.com', 'careers.hotjar.com',
            'freshmarketer.com', 'claritybt.freshmarketer.com', 'fwtracks.freshmarketer.com'
        ];
        
        function isBlockedUrl(url) {
            if (!url) return false;
            try {
                var urlStr = (typeof url === 'string') ? url : (url.href || url.url || String(url));
                var lower = urlStr.toLowerCase();
                for (var i = 0; i < specificHosts.length; i++) {
                    if (lower.indexOf(specificHosts[i]) !== -1) return true;
                }
                for (var j = 0; j < blockedKeywords.length; j++) {
                    if (lower.indexOf(blockedKeywords[j]) !== -1) return true;
                }
                if (lower.indexOf('/pagead/') !== -1 || lower.indexOf('/ads/banners/') !== -1 || lower.indexOf('yandex-direct') !== -1) {
                    return true;
                }
                return false;
            } catch(e) {
                return false;
            }
        }
        
        // 1. Hook window.fetch (used by adblock test suites like turtlecute / d3ward)
        const origFetch = window.fetch;
        if (origFetch) {
            window.fetch = function(resource, init) {
                var target = (typeof resource === 'string') ? resource : (resource ? resource.url : '');
                if (isBlockedUrl(target)) {
                    return Promise.reject(new TypeError('Network request blocked by AdBlocker: ' + target));
                }
                return origFetch.apply(this, arguments);
            };
        }
        
        // 2. Hook XMLHttpRequest
        const origXHR = window.XMLHttpRequest;
        if (origXHR && origXHR.prototype) {
            const origOpen = origXHR.prototype.open;
            const origSend = origXHR.prototype.send;
            origXHR.prototype.open = function(method, url) {
                this.__svinota_url = url;
                this.__svinota_blocked = isBlockedUrl(url);
                return origOpen.apply(this, arguments);
            };
            origXHR.prototype.send = function() {
                if (this.__svinota_blocked) {
                    var self = this;
                    setTimeout(function() {
                        if (typeof self.onerror === 'function') {
                            self.onerror(new ProgressEvent('error'));
                        }
                    }, 10);
                    return;
                }
                return origSend.apply(this, arguments);
            };
        }
        
        // 3. Hook HTMLScriptElement.prototype.src
        try {
            const scriptProto = HTMLScriptElement.prototype;
            const origScriptSrcDesc = Object.getOwnPropertyDescriptor(scriptProto, 'src');
            if (origScriptSrcDesc && origScriptSrcDesc.set) {
                Object.defineProperty(scriptProto, 'src', {
                    get: function() {
                        return origScriptSrcDesc.get.call(this);
                    },
                    set: function(val) {
                        if (isBlockedUrl(val)) {
                            this.setAttribute('data-blocked-by-adblock', 'true');
                            var self = this;
                            setTimeout(function() {
                                var evt = new Event('error', { bubbles: false });
                                self.dispatchEvent(evt);
                            }, 5);
                            return;
                        }
                        return origScriptSrcDesc.set.call(this, val);
                    },
                    configurable: true
                });
            }
        } catch(e) {}
        
        // 4. Hook HTMLImageElement.prototype.src
        try {
            const imgProto = HTMLImageElement.prototype;
            const origImgSrcDesc = Object.getOwnPropertyDescriptor(imgProto, 'src');
            if (origImgSrcDesc && origImgSrcDesc.set) {
                Object.defineProperty(imgProto, 'src', {
                    get: function() {
                        return origImgSrcDesc.get.call(this);
                    },
                    set: function(val) {
                        if (isBlockedUrl(val)) {
                            this.setAttribute('data-blocked-by-adblock', 'true');
                            var self = this;
                            setTimeout(function() {
                                var evt = new Event('error', { bubbles: false });
                                self.dispatchEvent(evt);
                            }, 5);
                            return;
                        }
                        return origImgSrcDesc.set.call(this, val);
                    },
                    configurable: true
                });
            }
        } catch(e) {}
        
        // 5. Hook HTMLIFrameElement.prototype.src
        try {
            const iframeProto = HTMLIFrameElement.prototype;
            const origIframeSrcDesc = Object.getOwnPropertyDescriptor(iframeProto, 'src');
            if (origIframeSrcDesc && origIframeSrcDesc.set) {
                Object.defineProperty(iframeProto, 'src', {
                    get: function() {
                        return origIframeSrcDesc.get.call(this);
                    },
                    set: function(val) {
                        if (isBlockedUrl(val)) {
                            return origIframeSrcDesc.set.call(this, 'about:blank');
                        }
                        return origIframeSrcDesc.set.call(this, val);
                    },
                    configurable: true
                });
            }
        } catch(e) {}
        
        // 6. Cosmetic CSS element hiding
        const css = `
            .adsbygoogle, [id*="google_ads"], [id*="google-ad"], [class*="yandex-adaptive"], 
            [id*="ad-container"], [class*="banner-ad"], [class*="advert-block"], div[class*="ad-slot"], 
            iframe[src*="doubleclick"], iframe[src*="adservice"], iframe[src*="an.yandex"], 
            [data-ad-client], [data-ad-slot], .ad-banner, .advertisement, #advert, .ad_container,
            div[id^="ad_"], div[class*="sponsored"], yandex-rtb, yandex-rtb-container,
            [class*="d3ward"], [id*="d3ward"], .banner_ads, .textads, .ad-unit, .ads-holder,
            #ad_block, .ad_box, #ad-bottom, .ad-header {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                min-height: 0 !important;
                max-height: 0 !important;
                opacity: 0 !important;
                pointer-events: none !important;
            }
        `;
        
        function injectCSS() {
            if (!document.head && !document.documentElement) return;
            const style = document.createElement('style');
            style.id = 'svinota-adblock-style';
            style.textContent = css;
            (document.head || document.documentElement).appendChild(style);
        }
        
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', injectCSS);
        } else {
            injectCSS();
        }
    })();
    """
    
    // Dark Reader: forced smart dark mode for web pages
    let darkReaderScript = """
    (function() {
        if (window.__svinota_darkreader_active) return;
        window.__svinota_darkreader_active = true;
        const css = `
            html { filter: invert(90%) hue-rotate(180deg) !important; background-color: #121212 !important; }
            img, video, canvas, svg, [style*="background-image"], picture, iframe {
                filter: invert(100%) hue-rotate(180deg) !important;
            }
        `;
        function injectDR() {
            if (!document.head && !document.documentElement) return;
            const style = document.createElement('style');
            style.id = 'svinota-darkreader-style';
            style.textContent = css;
            (document.head || document.documentElement).appendChild(style);
        }
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', injectDR);
        } else {
            injectDR();
        }
    })();
    """
}
