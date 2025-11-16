//
//  ReadyPlayerMeAvatarView.swift
//  DAM-iOS
//
//  Ready Player Me WebView integration
//

import SwiftUI
import WebKit

struct ReadyPlayerMeView: View {
    @Environment(\.dismiss) var dismiss
    let onAvatarCreated: (String) -> Void
    var existingAvatarUrl: String? = nil
    
    @State private var webView: WKWebView?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var avatarUrlReceived = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ReadyPlayerMeWebView(
                    onAvatarCreated: { url in
                        print("🎯 ReadyPlayerMeView: Avatar URL received, calling callback")
                        avatarUrlReceived = true
                        onAvatarCreated(url)
                        // Don't auto-dismiss - let the parent (EditAvatarView) handle dismissal after saving
                        // The parent will dismiss when ready
                    },
                    isLoading: $isLoading,
                    showError: $showError,
                    errorMessage: $errorMessage,
                    existingAvatarUrl: existingAvatarUrl
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Loading Avatar Creator...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .navigationTitle("Customize Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

struct ReadyPlayerMeWebView: UIViewRepresentable {
    let onAvatarCreated: (String) -> Void
    @Binding var isLoading: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    var existingAvatarUrl: String? = nil
    
    private var readyPlayerMeURL: String {
        ReadyPlayerMeConfig.getAvatarCreatorURL(quickStart: true, existingAvatarUrl: existingAvatarUrl)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        configuration.userContentController.add(context.coordinator, name: "avatarExport")
        
        let script = WKUserScript(
            source: """
            (function() {
                console.log('🎭 Ready Player Me listener injected');
                let avatarExported = false;
                
                function handleAvatarExported(avatarUrl) {
                    if (avatarExported) {
                        console.log('⚠️ Avatar already exported, ignoring duplicate');
                        return;
                    }
                    avatarExported = true;
                    console.log('🎨 Avatar exported:', avatarUrl);
                    try {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.avatarExport) {
                            console.log('📤 Sending avatar URL to iOS app');
                            window.webkit.messageHandlers.avatarExport.postMessage({ url: avatarUrl });
                        } else {
                            console.error('❌ Message handler not found');
                        }
                    } catch (e) {
                        console.error('❌ Error sending message:', e);
                    }
                }
                
                // Listen for Ready Player Me Frame API events
                window.addEventListener('message', function(event) {
                    try {
                        if (!event.data) return;
                        
                        console.log('📨 Message received from:', event.origin);
                        console.log('📨 Message data:', typeof event.data === 'string' ? event.data : JSON.stringify(event.data));
                        
                        // Check if it's a Ready Player Me event
                        if (event.data && typeof event.data === 'object') {
                            const eventName = event.data.eventName || event.data.type || event.data.name || event.data.event;
                            const data = event.data.data || event.data;
                            
                            console.log('📨 Event name:', eventName);
                            
                            // Check for avatar exported events (various formats)
                            if (eventName === 'v1.avatar.exported' || 
                                eventName === 'avatar.exported' || 
                                eventName === 'v1.frame.avatar.exported' ||
                                eventName === 'frame.avatar.exported' ||
                                eventName === 'avatarExport') {
                                const avatarUrl = data?.url || 
                                                 data?.avatarUrl || 
                                                 data?.avatarURL ||
                                                 event.data.url || 
                                                 event.data.avatarUrl ||
                                                 event.data.avatarURL;
                                console.log('📨 Extracted avatar URL from event:', avatarUrl);
                                if (avatarUrl) {
                                    handleAvatarExported(avatarUrl);
                                }
                            }
                            
                            // Also check for URL directly in event.data
                            if (event.data.url && typeof event.data.url === 'string' && 
                                (event.data.url.includes('readyplayer.me') || event.data.url.includes('.glb'))) {
                                console.log('📨 Found URL directly in event.data.url:', event.data.url);
                                handleAvatarExported(event.data.url);
                            }
                        } else if (typeof event.data === 'string') {
                            // Sometimes the URL is sent as a plain string
                            if ((event.data.includes('readyplayer.me') || event.data.includes('.glb')) && 
                                !event.data.includes('readyplayer.me/avatar')) {
                                console.log('📨 Found URL as string:', event.data);
                                handleAvatarExported(event.data);
                            }
                        }
                    } catch (error) {
                        console.error('❌ Error processing message:', error);
                    }
                }, true);
                
                // Also listen for postMessage from parent/iframe
                if (window.parent && window.parent !== window) {
                    window.parent.addEventListener('message', function(event) {
                        console.log('📨 Parent message:', JSON.stringify(event.data));
                        if (event.data && event.data.url) {
                            handleAvatarExported(event.data.url);
                        }
                    }, true);
                }
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(script)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        
        if let url = URL(string: readyPlayerMeURL) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 30.0
            webView.load(request)
        } else {
            context.coordinator.parent.errorMessage = "Invalid Ready Player Me URL"
            context.coordinator.parent.showError = true
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ReadyPlayerMeWebView
        
        init(_ parent: ReadyPlayerMeWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let currentURL = webView.url?.absoluteString ?? "unknown"
            print("✅ WebView finished loading: \(currentURL)")
            print("🔍 Checking if Ready Player Me is properly configured...")
            
            // Verify appId is in the URL
            if let urlString = webView.url?.absoluteString {
                if urlString.contains("appId=69179e3a771c8dd1a3aedb66") {
                    print("✅ App ID found in URL")
                } else {
                    print("⚠️ App ID not found in URL - this might cause saving issues")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Enhanced script to monitor URL changes and messages
                let script = """
                (function() {
                    console.log('🔄 Reinjecting Ready Player Me listener after page load');
                    let avatarExported = false;
                    
                    function sendAvatarUrl(avatarUrl) {
                        if (avatarExported) {
                            console.log('⚠️ Avatar already exported, ignoring');
                            return;
                        }
                        avatarExported = true;
                        console.log('🎨 Sending avatar URL to iOS:', avatarUrl);
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.avatarExport) {
                            window.webkit.messageHandlers.avatarExport.postMessage({ url: avatarUrl });
                        }
                    }
                    
                    // Monitor URL changes more aggressively (Ready Player Me redirects after NEXT)
                    let lastUrl = window.location.href;
                    const urlCheckInterval = setInterval(function() {
                        try {
                            const currentUrl = window.location.href;
                            if (currentUrl !== lastUrl) {
                                lastUrl = currentUrl;
                                console.log('📍 URL changed to:', currentUrl);
                                
                                // Check if URL contains avatar ID (happens after NEXT click)
                                const avatarIdMatch = currentUrl.match(/[0-9a-f]{24}/);
                                if (avatarIdMatch && !currentUrl.includes('/avatar')) {
                                    const avatarId = avatarIdMatch[0];
                                    const avatarUrl = 'https://models.readyplayer.me/' + avatarId + '.glb';
                                    console.log('🎨 Detected avatar ID from URL change:', avatarId);
                                    sendAvatarUrl(avatarUrl);
                                    clearInterval(urlCheckInterval);
                                }
                                
                                // Also check for .glb in URL
                                if (currentUrl.includes('.glb') && !currentUrl.includes('/avatar')) {
                                    console.log('🎨 Found .glb in URL:', currentUrl);
                                    sendAvatarUrl(currentUrl);
                                    clearInterval(urlCheckInterval);
                                }
                            }
                        } catch (e) {
                            console.error('❌ Error in URL check:', e);
                        }
                    }, 300); // Check every 300ms
                    
                    // Enhanced message listener
                    const messageHandler = function(event) {
                        try {
                            if (!event.data || avatarExported) return;
                            
                            console.log('📨 Enhanced listener - message received from:', event.origin);
                            console.log('📨 Message data:', typeof event.data === 'string' ? event.data : JSON.stringify(event.data));
                            
                            if (event.data && typeof event.data === 'object') {
                                const eventName = event.data.eventName || event.data.type || event.data.name || event.data.event;
                                const data = event.data.data || event.data;
                                
                                console.log('📨 Event name:', eventName);
                                
                                // Check for all possible avatar exported event names
                                if (eventName === 'v1.avatar.exported' || 
                                    eventName === 'avatar.exported' || 
                                    eventName === 'v1.frame.avatar.exported' ||
                                    eventName === 'frame.avatar.exported' ||
                                    eventName === 'avatarExport' ||
                                    eventName === 'avatar-exported') {
                                    const avatarUrl = data?.url || 
                                                     data?.avatarUrl || 
                                                     data?.avatarURL ||
                                                     event.data.url || 
                                                     event.data.avatarUrl ||
                                                     event.data.avatarURL;
                                    console.log('🎨 Extracted avatar URL from event:', avatarUrl);
                                    if (avatarUrl) {
                                        sendAvatarUrl(avatarUrl);
                                        clearInterval(urlCheckInterval);
                                        window.removeEventListener('message', messageHandler);
                                    }
                                }
                                
                                // Also check for URL directly in event.data
                                if (event.data.url && typeof event.data.url === 'string' && 
                                    (event.data.url.includes('readyplayer.me') || event.data.url.includes('.glb')) &&
                                    !event.data.url.includes('/avatar')) {
                                    console.log('🎨 Found URL directly in event.data.url:', event.data.url);
                                    sendAvatarUrl(event.data.url);
                                    clearInterval(urlCheckInterval);
                                    window.removeEventListener('message', messageHandler);
                                }
                            } else if (typeof event.data === 'string') {
                                // Sometimes the URL is sent as a plain string
                                if ((event.data.includes('readyplayer.me') || event.data.includes('.glb')) && 
                                    !event.data.includes('/avatar')) {
                                    console.log('🎨 Found URL as string:', event.data);
                                    sendAvatarUrl(event.data);
                                    clearInterval(urlCheckInterval);
                                    window.removeEventListener('message', messageHandler);
                                }
                            }
                        } catch (error) {
                            console.error('❌ Error in message handler:', error);
                        }
                    };
                    
                    window.addEventListener('message', messageHandler, true);
                    
                    // Also try to access Ready Player Me Frame API directly
                    if (window.ReadyPlayerMe) {
                        console.log('✅ Ready Player Me Frame API found');
                        window.ReadyPlayerMe.addEventListener('v1.avatar.exported', function(event) {
                            console.log('🎨 Frame API event received:', event);
                            if (event.detail && event.detail.url) {
                                sendAvatarUrl(event.detail.url);
                            }
                        });
                    }
                    
                    // Cleanup after 5 minutes
                    setTimeout(function() {
                        clearInterval(urlCheckInterval);
                        window.removeEventListener('message', messageHandler);
                    }, 300000);
                })();
                """
                webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("❌ Error injecting script: \(error.localizedDescription)")
                    } else {
                        print("✅ Enhanced script injected successfully")
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = "Failed to load Ready Player Me: \(error.localizedDescription)"
            parent.showError = true
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = "Failed to load Ready Player Me: \(error.localizedDescription)"
            parent.showError = true
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("📬 Message received: name=\(message.name)")
            print("📬 Message body type: \(type(of: message.body))")
            print("📬 Message body: \(message.body)")
            
            if message.name == "avatarExport" {
                var avatarUrl: String?
                
                if let body = message.body as? [String: Any] {
                    avatarUrl = body["url"] as? String
                    print("📬 Extracted URL from dictionary: \(avatarUrl ?? "nil")")
                } else if let urlString = message.body as? String {
                    avatarUrl = urlString
                    print("📬 Extracted URL from string: \(avatarUrl ?? "nil")")
                }
                
                if let url = avatarUrl {
                    print("🎭 Avatar URL received: \(url)")
                    let avatarId = ReadyPlayerMeConfig.extractAvatarId(from: url)
                    print("🆔 Extracted avatar ID: \(avatarId)")
                    
                    let glbUrl: String
                    if url.hasSuffix(".glb") {
                        glbUrl = url
                    } else {
                        glbUrl = "https://models.readyplayer.me/\(avatarId).glb"
                    }
                    
                    print("📦 Final GLB URL: \(glbUrl)")
                    print("✅ Calling onAvatarCreated callback...")
                    
                    DispatchQueue.main.async {
                        self.parent.onAvatarCreated(glbUrl)
                    }
                } else {
                    print("❌ No avatar URL found in message")
                }
            } else {
                print("⚠️ Unknown message name: \(message.name)")
            }
        }
    }
}

struct ReadyPlayerMeView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyPlayerMeView { url in
            print("Avatar created: \(url)")
        }
    }
}


