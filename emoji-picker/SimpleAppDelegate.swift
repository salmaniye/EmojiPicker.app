import AppKit
import SwiftUI
import Carbon
import Foundation

// MARK: - Emoji Database Models
struct EmojiData: Codable {
    let name: String
    let unified: String
    let shortName: String
    let shortNames: [String]
    let category: String
    let sortOrder: Int
    let addedIn: String
    let hasImgApple: Bool
    let keywords: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case unified
        case shortName = "short_name"
        case shortNames = "short_names"
        case category
        case sortOrder = "sort_order"
        case addedIn = "added_in"
        case hasImgApple = "has_img_apple"
        case keywords
    }
    
    // Convert Unicode string to actual emoji
    var emoji: String {
        guard !unified.isEmpty else { return "" }
        
        // Handle compound emojis (with hyphens like "1F468-200D-2764-FE0F-200D-1F468")
        let components = unified.split(separator: "-")
        var characters: [Character] = []
        
        for component in components {
            if let codePoint = UInt32(component, radix: 16),
               let scalar = UnicodeScalar(codePoint) {
                characters.append(Character(scalar))
            }
        }
        
        return String(characters)
    }
    
    // Get all searchable terms for this emoji
    var searchTerms: [String] {
        var terms = [shortName] + shortNames
        if let keywords = keywords {
            terms.append(contentsOf: keywords)
        }
        terms.append(name.lowercased())
        return terms.map { $0.lowercased() }
    }
}

// MARK: - Emoji Database Manager
class EmojiDataManager {
    static let shared = EmojiDataManager()
    var allEmojis: [EmojiData] = []
    
    private init() {
        loadEmojiDatabase()
    }
    
    private func loadEmojiDatabase() {
        guard let path = Bundle.main.path(forResource: "emoji", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data? else {
            print("❌ Could not find emoji.json file")
            loadFallbackEmojis()
            return
        }
        
        do {
            allEmojis = try JSONDecoder().decode([EmojiData].self, from: data)
            print("✅ Loaded \(allEmojis.count) emojis from database")
            
            // Debug: Show some sample emojis and categories
            let categories = Set(allEmojis.map { $0.category })
            print("📂 Found categories: \(categories)")
            print("🎯 Sample emojis: \(allEmojis.prefix(5).map { "\($0.emoji)(\($0.shortName))" })")
        } catch {
            print("❌ Error decoding emoji database: \(error)")
            loadFallbackEmojis()
        }
    }
    
    private func loadFallbackEmojis() {
        // No fallback - if JSON fails, app should show an error
        print("❌ Failed to load emoji database - no emojis available")
        allEmojis = []
    }
    
    // Search emojis by keyword
    func searchEmojis(query: String, limit: Int = 6) -> [String] {
        guard !query.isEmpty else {
            return getTopEmojis(limit: limit)
        }
        
        let lowercaseQuery = query.lowercased()
        var matchedEmojis: [(emoji: String, priority: Int)] = []
        
        for emojiData in allEmojis {
            let emoji = emojiData.emoji
            guard !emoji.isEmpty && emojiData.hasImgApple else { continue }
            
            // Check for matches in search terms
            for (index, term) in emojiData.searchTerms.enumerated() {
                if term.contains(lowercaseQuery) {
                    let priority: Int
                    
                    // Priority system:
                    // 1. Exact match with short_name (highest priority)
                    // 2. Starts with query in short_name
                    // 3. Contains query in short_name
                    // 4. Starts with query in other terms
                    // 5. Contains query in other terms
                    
                    if term == lowercaseQuery && index == 0 {
                        priority = 1000
                    } else if term.hasPrefix(lowercaseQuery) && index == 0 {
                        priority = 900
                    } else if term.contains(lowercaseQuery) && index == 0 {
                        priority = 800
                    } else if term.hasPrefix(lowercaseQuery) {
                        priority = 700
                    } else {
                        priority = 600
                    }
                    
                    matchedEmojis.append((emoji: emoji, priority: priority))
                    break // Don't add same emoji multiple times
                }
            }
        }
        
        // Sort by priority (highest first) and return emojis
        let sortedMatches = matchedEmojis.sorted { $0.priority > $1.priority }
        return Array(sortedMatches.prefix(limit).map { $0.emoji })
    }
    
    // Get popular/top emojis when no search query
    func getTopEmojis(limit: Int = 6) -> [String] {
        // Use the most popular emojis from the database based on sort order
        let popularEmojis = allEmojis
            .filter { $0.hasImgApple }
            .sorted { $0.sortOrder < $1.sortOrder }
            .prefix(limit)
            .compactMap { emojiData -> String? in
                let emoji = emojiData.emoji
                return emoji.isEmpty ? nil : emoji
            }
        
        return Array(popularEmojis)
    }
    
    // Get curated categories with emojis from the actual database
    func getCuratedCategories() -> [(name: String, emojis: [String])] {
        if allEmojis.isEmpty {
            // No fallback - return empty if database not loaded
            print("⚠️ No emoji database loaded - cannot get categories")
            return []
        }
        
        // Use the actual comprehensive database!
        let categoryMapping = [
            "😀 Smileys & People": "Smileys & Emotion",
            "🐶 Animals & Nature": "Animals & Nature", 
            "🍎 Food & Drink": "Food & Drink",
            "⚽ Activities": "Activities",
            "🚗 Travel & Places": "Travel & Places",
            "💡 Objects": "Objects",
            "💯 Symbols": "Symbols",
            "🏁 Flags": "Flags"
        ]
        
        var result: [(name: String, emojis: [String])] = []
        
        for (displayName, dbCategory) in categoryMapping {
            let categoryEmojis = allEmojis
                .filter { $0.category == dbCategory && $0.hasImgApple }
                .sorted { $0.sortOrder < $1.sortOrder }
                // Show ALL emojis in each category - no artificial limit!
                .compactMap { emojiData -> String? in
                    let emoji = emojiData.emoji
                    return emoji.isEmpty ? nil : emoji
                }
            
            if !categoryEmojis.isEmpty {
                result.append((displayName, Array(categoryEmojis)))
            }
        }
        
        // Add a special "Popular" category with top emojis from database
        let popularEmojis = allEmojis
            .filter { $0.hasImgApple }
            .sorted { $0.sortOrder < $1.sortOrder }
            .prefix(50) // Show more popular emojis but still keep it reasonable
            .compactMap { emojiData -> String? in
                let emoji = emojiData.emoji
                return emoji.isEmpty ? nil : emoji
            }
        
        if !popularEmojis.isEmpty {
            result.insert(("⭐ Popular", Array(popularEmojis)), at: 0)
        }
        
        return result
    }
}

class SimpleAppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    
    // Emoji tracking state
    var isTrackingEmoji = false
    var currentEmojiText = ""
    var dropdownWindow: NSWindow?
    var selectedEmojiIndex = 0
    var currentEmojis: [String] = []
    var eventTap: CFMachPort?
    var isInsertingEmoji = false // Flag to prevent self-interception
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - make it a menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        setupStatusBar()
        
        // Setup emoji shortcuts
        setupEmojiShortcuts()
        
        print("🚀 Emoji Picker is ready!")
        print("💡 Type :heart or :smile in any app to get emoji suggestions")
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusBarItem?.button {
            statusButton.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Emoji Picker")
            statusButton.action = #selector(statusBarClicked)
            statusButton.target = self
        }
    }
    
    @objc func statusBarClicked() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Emoji Picker - Rocket Style", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "How to use: Type :emoji_name in any app", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Examples: :heart :smile :fire :thumbsup", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Debug info
        let permissionsStatus = AXIsProcessTrusted() ? "✅ Granted" : "❌ Not granted"
        menu.addItem(NSMenuItem(title: "Accessibility: \(permissionsStatus)", action: nil, keyEquivalent: ""))
        
        let statusItem = NSMenuItem(title: "Status: \(isTrackingEmoji ? "Tracking" : "Ready")", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Test Shortcuts", action: #selector(testShortcuts), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
        statusBarItem?.button?.performClick(nil)
        statusBarItem?.menu = nil
    }
    
    @objc func testShortcuts() {
        print("🧪 Testing shortcuts...")
        startEmojiTracking()
        currentEmojiText = "test"
        updateDropdown()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.stopEmojiTracking()
        }
    }
    
    func setupEmojiShortcuts() {
        print("🔧 setupEmojiShortcuts called")
        
        // Check accessibility permissions
        let trusted = AXIsProcessTrusted()
        print("🔒 Accessibility trusted: \(trusted)")
        
        if !trusted {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
            print("⚠️ Need accessibility permissions for emoji shortcuts")
            
            // Show alert to guide user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "To enable emoji shortcuts, please:\n\n1. Go to System Preferences > Security & Privacy > Privacy > Accessibility\n2. Add this app to the list\n3. Restart the app"
                alert.runModal()
            }
            return
        }
        
        // Set up POWERFUL CGEventTap that can actually BLOCK events!
        print("⚡ Setting up NUCLEAR CGEventTap...")
        setupPowerfulEventTap()
        
        print("🔥 Emoji shortcuts active!")
    }
    
    func setupPowerfulEventTap() {
        // Create a callback function that can intercept and modify/block events
        let eventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
            let appDelegate = Unmanaged<SimpleAppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
            return appDelegate.handleCGEvent(proxy: proxy, type: type, event: event)
        }
        
        // Create the event tap with the ability to modify/block events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ Failed to create CGEventTap!")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("⚡ NUCLEAR CGEventTap is ACTIVE and ready to BLOCK arrow keys!")
    }
    
    func handleCGEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Don't intercept our own emoji insertions!
        if isInsertingEmoji {
            print("🚫 Ignoring event during emoji insertion")
            return Unmanaged.passRetained(event)
        }
        
        // Convert CGEvent to NSEvent for easier handling
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passRetained(event)
        }
        
        let character = nsEvent.charactersIgnoringModifiers ?? ""
        let keyCode = nsEvent.keyCode
        
        print("⚡ CGEventTap intercepted: char: '\(character)' keyCode: \(keyCode) tracking: \(isTrackingEmoji)")
        
        // Handle colon to start tracking
        if character == ":" && !isTrackingEmoji {
            print("🎯 CGEventTap: Colon detected - starting emoji tracking!")
            startEmojiTracking()
            return Unmanaged.passRetained(event) // Let colon through normally
        }
        
        // If we're tracking emojis, handle special cases
        if isTrackingEmoji {
            if keyCode == 125 || keyCode == 126 || keyCode == 123 || keyCode == 124 { // ALL Arrow keys
                print("🛡️ BLOCKING ALL ARROW KEYS from reaching document!")
                handleArrowKey(nsEvent)
                return nil // BLOCK the arrow key completely!
            } else if keyCode == 36 { // Enter
                print("🛡️ BLOCKING ENTER from reaching document!")
                insertSelectedEmoji()
                return nil // BLOCK enter completely!
            } else if keyCode == 53 || character == " " { // Escape or Space
                print("🛡️ BLOCKING ESCAPE/SPACE from reaching document!")
                stopEmojiTracking()
                return nil // BLOCK these keys!
            } else if keyCode == 51 { // Backspace
                handleBackspace()
                return nil // BLOCK backspace when tracking!
            } else if !character.isEmpty {
                // Handle character input and BLOCK it from document
                handleCharacterInput(character)
                return nil // BLOCK the letters from appearing in document!
            }
        }
        
        // For all other cases, let the event through normally
        return Unmanaged.passRetained(event)
    }
    
    func handleArrowKey(_ event: NSEvent) {
        if event.keyCode == 125 { // Down arrow
            print("⬇️ CGEventTap: Down arrow - current selection: \(selectedEmojiIndex)")
            if selectedEmojiIndex < currentEmojis.count - 1 {
                selectedEmojiIndex += 1
                print("⬇️ Moving selection down to: \(selectedEmojiIndex)")
                updateDropdownSelection()
            }
        } else if event.keyCode == 126 { // Up arrow
            print("⬆️ CGEventTap: Up arrow - current selection: \(selectedEmojiIndex)")
            if selectedEmojiIndex > 0 {
                selectedEmojiIndex -= 1
                print("⬆️ Moving selection up to: \(selectedEmojiIndex)")
                updateDropdownSelection()
            }
        } else if event.keyCode == 123 { // Left arrow
            print("⬅️ CGEventTap: Left arrow - ignoring")
        } else if event.keyCode == 124 { // Right arrow
            print("➡️ CGEventTap: Right arrow - ignoring")
        }
    }
    
    func handleBackspace() {
        if !currentEmojiText.isEmpty {
            currentEmojiText.removeLast()
            selectedEmojiIndex = 0
            print("⌫ CGEventTap: Backspace - text now: '\(currentEmojiText)'")
            updateDropdown()
        } else {
            print("⌫ CGEventTap: Backspace - stopping tracking")
            stopEmojiTracking()
        }
    }
    
    func handleCharacterInput(_ character: String) {
        let cleanChar = character.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanChar.isEmpty && cleanChar != "\n" && cleanChar != "\r" && cleanChar != "\t" {
            currentEmojiText += cleanChar.lowercased()
            selectedEmojiIndex = 0
            print("📝 CGEventTap: Added character '\(cleanChar)' - text now: '\(currentEmojiText)'")
            updateDropdown()
        }
    }
    
    // Old handleKeyEvent function removed - now using powerful CGEventTap!
    
    func startEmojiTracking() {
        isTrackingEmoji = true
        currentEmojiText = ""
        selectedEmojiIndex = 0
        print("🚀 Started tracking emoji input")
        updateDropdown()
    }
    
    func stopEmojiTracking() {
        isTrackingEmoji = false
        currentEmojiText = ""
        selectedEmojiIndex = 0
        currentEmojis = []
        hideDropdown()
        print("🛑 Stopped tracking emoji input")
    }
    
    func updateDropdown() {
        let emojis = getMatchingEmojis()
        currentEmojis = Array(emojis.prefix(8))
        showScrollableDropdown()
    }
    
    func updateDropdownSelection() {
        // Just refresh the dropdown with the new selection
        showScrollableDropdown()
    }
    
    func insertSelectedEmoji() {
        guard selectedEmojiIndex < currentEmojis.count else {
            stopEmojiTracking()
            return
        }
        
        let selectedEmoji = currentEmojis[selectedEmojiIndex]
        insertFirstEmoji(selectedEmoji)
    }
    
    func showScrollableDropdown() {
        hideDropdown()
        
        // Center on screen like Spotlight
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let centerX = screenRect.midX
        let centerY = screenRect.midY
        
        // Create beautiful modern container
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Modern translucent background
        let backgroundView = NSVisualEffectView()
        backgroundView.frame = NSRect(x: 0, y: 0, width: 320, height: 420)
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 12
        containerView.addSubview(backgroundView)
        
        // Elegant header section
        if !currentEmojiText.isEmpty {
            let headerContainer = NSView()
            headerContainer.frame = NSRect(x: 16, y: 370, width: 288, height: 32)
            headerContainer.wantsLayer = true
            headerContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.8).cgColor
            headerContainer.layer?.cornerRadius = 8
            
            let searchLabel = NSTextField(labelWithString: ":\(currentEmojiText)")
            searchLabel.isEditable = false
            searchLabel.isBordered = false
            searchLabel.backgroundColor = NSColor.clear
            searchLabel.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .medium)
            searchLabel.textColor = NSColor.labelColor
            searchLabel.alignment = .center
            searchLabel.frame = NSRect(x: 0, y: 6, width: 288, height: 20)
            headerContainer.addSubview(searchLabel)
            containerView.addSubview(headerContainer)
        }
        
                        // Beautiful emoji list with modern cards
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 16, y: 70, width: 288, height: 280)
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.clear
        
        // Modern emoji list view
        let listView = NSView()
        
        for (index, emoji) in currentEmojis.enumerated() {
            // Modern card container
            let cardContainer = NSView()
            let reversedY = CGFloat(currentEmojis.count - 1 - index) * 44
            cardContainer.frame = NSRect(x: 8, y: reversedY, width: 272, height: 40)
            cardContainer.wantsLayer = true
            cardContainer.layer?.cornerRadius = 8
            
            // Elegant selection states
            if index == selectedEmojiIndex {
                cardContainer.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
                cardContainer.layer?.shadowColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
                cardContainer.layer?.shadowOffset = CGSize(width: 0, height: 2)
                cardContainer.layer?.shadowRadius = 4
                cardContainer.layer?.shadowOpacity = 1
            } else {
                cardContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor
                cardContainer.layer?.shadowColor = NSColor.black.withAlphaComponent(0.1).cgColor
                cardContainer.layer?.shadowOffset = CGSize(width: 0, height: 1)
                cardContainer.layer?.shadowRadius = 2
                cardContainer.layer?.shadowOpacity = 1
            }
            
            // Emoji icon
            let emojiLabel = NSTextField(labelWithString: emoji)
            emojiLabel.isEditable = false
            emojiLabel.isBordered = false
            emojiLabel.backgroundColor = NSColor.clear
            emojiLabel.font = NSFont.systemFont(ofSize: 20)
            emojiLabel.alignment = .center
            emojiLabel.frame = NSRect(x: 8, y: 8, width: 28, height: 24)
            cardContainer.addSubview(emojiLabel)
            
            // Emoji name
            let nameLabel = NSTextField(labelWithString: getEmojiName(emoji))
            nameLabel.isEditable = false
            nameLabel.isBordered = false
            nameLabel.backgroundColor = NSColor.clear
            nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
            nameLabel.textColor = index == selectedEmojiIndex ? NSColor.white : NSColor.labelColor
            nameLabel.alignment = .left
            nameLabel.frame = NSRect(x: 44, y: 13, width: 220, height: 16)
            cardContainer.addSubview(nameLabel)
            
            // Invisible button for clicking
            let button = NSButton()
            button.title = ""
            button.isBordered = false
            button.isTransparent = true
            button.target = self
            button.action = #selector(emojiButtonClicked(_:))
            button.frame = cardContainer.bounds
            button.tag = index
            cardContainer.addSubview(button)
            
            listView.addSubview(cardContainer)
        }
        
        let totalListHeight = CGFloat(currentEmojis.count) * 44
        listView.frame = NSRect(x: 0, y: 0, width: 288, height: max(totalListHeight, scrollView.frame.height))
        scrollView.documentView = listView
        containerView.addSubview(scrollView)
        
        // Beautiful "Show All" button
        let buttonContainer = NSView()
        buttonContainer.frame = NSRect(x: 16, y: 16, width: 288, height: 40)
        buttonContainer.wantsLayer = true
        buttonContainer.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.9).cgColor
        buttonContainer.layer?.cornerRadius = 10
        buttonContainer.layer?.shadowColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        buttonContainer.layer?.shadowOffset = CGSize(width: 0, height: 2)
        buttonContainer.layer?.shadowRadius = 4
        buttonContainer.layer?.shadowOpacity = 1
        
        let showAllButton = NSButton(title: "Browse All Emojis", target: self, action: #selector(showAllEmojis))
        showAllButton.isBordered = false
        showAllButton.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        showAllButton.contentTintColor = NSColor.white
        showAllButton.frame = buttonContainer.bounds
        buttonContainer.addSubview(showAllButton)
        containerView.addSubview(buttonContainer)
        
        // Create the beautiful window
        let windowX = centerX - 160
        let windowY = centerY - 210
        
        let panel = NSPanel(
            contentRect: NSRect(x: windowX, y: windowY, width: 320, height: 420),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = NSWindow.Level.floating
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.contentView = containerView
        panel.orderFront(nil)
        
        dropdownWindow = panel
        print("📝 Showing beautiful modern dropdown centered at (\(windowX), \(windowY)) with \(currentEmojis.count) emojis, selected: \(selectedEmojiIndex)")
    }
    
    func getEmojiName(_ emoji: String) -> String {
        // Look up the emoji name from the comprehensive database
        for emojiData in EmojiDataManager.shared.allEmojis {
            if emojiData.emoji == emoji {
                return emojiData.shortName
            }
        }
        return "" // Return empty string if emoji not found
    }
    
    func getTextCursorLocation() -> NSPoint {
        // First, let's get the current app name for debugging
        if let app = NSWorkspace.shared.frontmostApplication {
            print("🎮 Current app: \(app.localizedName ?? "unknown")")
        }
        
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        
        let appResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        if appResult == .success, let app = focusedApp {
            var focusedElement: CFTypeRef?
            let elementResult = AXUIElementCopyAttributeValue(
                app as! AXUIElement,
                kAXFocusedUIElementAttribute as CFString,
                &focusedElement
            )
            
            if elementResult == .success, let element = focusedElement {
                let axElement = element as! AXUIElement
                
                // Try to get the element position first (simpler approach)
                var position: CFTypeRef?
                let posResult = AXUIElementCopyAttributeValue(
                    axElement,
                    kAXPositionAttribute as CFString,
                    &position
                )
                
                if posResult == .success, let posValue = position {
                    var point = CGPoint.zero
                    if AXValueGetValue(posValue as! AXValue, .cgPoint, &point) {
                        print("✅ Found focused element position: \(point)")
                        return NSPoint(x: point.x + 20, y: point.y - 50)
                    }
                }
                
                // Try getting selected text range and its bounds
                var selectedRange: CFTypeRef?
                let rangeResult = AXUIElementCopyAttributeValue(
                    axElement,
                    kAXSelectedTextRangeAttribute as CFString,
                    &selectedRange
                )
                
                if rangeResult == .success, let range = selectedRange {
                    var bounds: CFTypeRef?
                    let boundsResult = AXUIElementCopyParameterizedAttributeValue(
                        axElement,
                        kAXBoundsForRangeParameterizedAttribute as CFString,
                        range,
                        &bounds
                    )
                    
                    if boundsResult == .success, let boundsValue = bounds {
                        var rect = CGRect.zero
                        if AXValueGetValue(boundsValue as! AXValue, .cgRect, &rect) {
                            print("✅ Found text range bounds: \(rect)")
                            return NSPoint(x: rect.origin.x, y: rect.origin.y - 50)
                        }
                    }
                }
            }
        }
        
        // Fallback: Position near the center of the screen
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let centerX = screenRect.midX
            let centerY = screenRect.midY
            
            print("🎯 Using screen center fallback: (\(centerX), \(centerY))")
            return NSPoint(x: centerX - 90, y: centerY)
        }
        
        // Last resort
        let mouseLocation = NSEvent.mouseLocation
        print("🎯 Using mouse location fallback: \(mouseLocation)")
        return NSPoint(x: mouseLocation.x + 30, y: mouseLocation.y + 40)
    }
    
    func getMatchingEmojis() -> [String] {
        // Use the comprehensive emoji database
        return EmojiDataManager.shared.searchEmojis(query: currentEmojiText, limit: 6)
    }
    
    @objc func emojiButtonClicked(_ sender: NSButton) {
        // Use the tag to get the correct emoji from currentEmojis array
        let index = sender.tag
        if index < currentEmojis.count {
            let emoji = currentEmojis[index]
            print("🖱️ Button clicked at index \(index): '\(emoji)'")
            insertFirstEmoji(emoji)
        }
    }
    
    @objc func showAllEmojis() {
        print("📱 Show all emojis clicked")
        currentEmojiText = ""
        selectedEmojiIndex = 0
        showComprehensiveEmojiPicker()
    }
    
    func showComprehensiveEmojiPicker() {
        hideDropdown()
        
        // Center on screen
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let centerX = screenRect.midX
        let centerY = screenRect.midY
        
        // Create beautiful container
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Modern background
        let backgroundView = NSVisualEffectView()
        backgroundView.frame = NSRect(x: 0, y: 0, width: 460, height: 500)
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 16
        containerView.addSubview(backgroundView)
        
        // Elegant title
        let titleLabel = NSTextField(labelWithString: "Emoji Universe")
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: 450, width: 420, height: 30)
        containerView.addSubview(titleLabel)
        
        // Scrollable content area
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 16, y: 60, width: 428, height: 370)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.backgroundColor = NSColor.clear
        containerView.addSubview(scrollView)
        
        let contentView = NSView()
        
        // Get categories from the comprehensive emoji database
        let categories = EmojiDataManager.shared.getCuratedCategories()
        print("🗂️ Found \(categories.count) categories for comprehensive picker")
        
        for (categoryName, emojis) in categories {
            print("📂 Category '\(categoryName)': \(emojis.count) emojis")
        }
        
        var yPos: CGFloat = 0
        var maxY: CGFloat = 0
        
        for (categoryName, emojis) in categories.reversed() {
            // Beautiful category header
            let categoryContainer = NSView()
            categoryContainer.frame = NSRect(x: 0, y: yPos, width: 428, height: 36)
            categoryContainer.wantsLayer = true
            categoryContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.7).cgColor
            categoryContainer.layer?.cornerRadius = 8
            
            let categoryLabel = NSTextField(labelWithString: categoryName)
            categoryLabel.isEditable = false
            categoryLabel.isBordered = false
            categoryLabel.backgroundColor = NSColor.clear
            categoryLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
            categoryLabel.textColor = NSColor.labelColor
            categoryLabel.frame = NSRect(x: 12, y: 8, width: 404, height: 20)
            categoryContainer.addSubview(categoryLabel)
            contentView.addSubview(categoryContainer)
            yPos += 44
            
            // Beautiful emoji grid (6 columns)
            let gridContainer = NSView()
            let rows = (emojis.count + 5) / 6
            let gridHeight = CGFloat(rows) * 50 + 12  // Increased row height
            gridContainer.frame = NSRect(x: 8, y: yPos, width: 412, height: gridHeight)
            gridContainer.wantsLayer = true
            gridContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3).cgColor
            gridContainer.layer?.cornerRadius = 12
            
            for (index, emoji) in emojis.enumerated() {
                let row = index / 6
                let col = index % 6
                
                let x = 6 + CGFloat(col) * 66
                let y = gridHeight - 50 - CGFloat(row) * 50  // Adjusted for new row height
                
                // Elegant emoji card
                let emojiCard = NSView()
                emojiCard.frame = NSRect(x: x, y: y, width: 60, height: 44)  // Increased card height
                emojiCard.wantsLayer = true
                emojiCard.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.8).cgColor
                emojiCard.layer?.cornerRadius = 8
                emojiCard.layer?.shadowColor = NSColor.black.withAlphaComponent(0.1).cgColor
                emojiCard.layer?.shadowOffset = CGSize(width: 0, height: 1)
                emojiCard.layer?.shadowRadius = 2
                emojiCard.layer?.shadowOpacity = 1
                
                let button = NSButton(title: emoji, target: self, action: #selector(categoryEmojiClicked(_:)))
                button.isBordered = false
                button.font = NSFont.systemFont(ofSize: 20)
                button.frame = emojiCard.bounds
                emojiCard.addSubview(button)
                gridContainer.addSubview(emojiCard)
            }
            
            contentView.addSubview(gridContainer)
            yPos += gridHeight + 16
            maxY = yPos
        }
        
        contentView.frame = NSRect(x: 0, y: 0, width: 428, height: max(maxY, 370))
        scrollView.documentView = contentView
        
        // Beautiful close button
        let closeContainer = NSView()
        closeContainer.frame = NSRect(x: 160, y: 16, width: 140, height: 36)
        closeContainer.wantsLayer = true
        closeContainer.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.8).cgColor
        closeContainer.layer?.cornerRadius = 10
        closeContainer.layer?.shadowColor = NSColor.systemRed.withAlphaComponent(0.2).cgColor
        closeContainer.layer?.shadowOffset = CGSize(width: 0, height: 2)
        closeContainer.layer?.shadowRadius = 4
        closeContainer.layer?.shadowOpacity = 1
        
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeCategoryPicker))
        closeButton.isBordered = false
        closeButton.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        closeButton.contentTintColor = NSColor.white
        closeButton.frame = closeContainer.bounds
        closeContainer.addSubview(closeButton)
        containerView.addSubview(closeContainer)
        
        // Create the beautiful window
        let windowX = centerX - 230
        let windowY = centerY - 250
        
        let panel = NSPanel(
            contentRect: NSRect(x: windowX, y: windowY, width: 460, height: 500),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.contentView = containerView
        panel.orderFront(nil)
        
        dropdownWindow = panel
        print("📱 Showing categorized emoji picker")
    }
    
    @objc func categoryEmojiClicked(_ sender: NSButton) {
        let emoji = sender.title
        print("🖱️ Category emoji clicked: '\(emoji)'")
        insertFirstEmoji(emoji)
    }
    
    @objc func closeCategoryPicker() {
        hideDropdown()
    }
    
    func getLetterFromKeyCode(_ keyCode: UInt16) -> String {
        // Map common letter key codes to characters
        switch keyCode {
        case 0: return "a"
        case 11: return "b"
        case 8: return "c"
        case 2: return "d"
        case 14: return "e"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 34: return "i"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 46: return "m"
        case 45: return "n"
        case 31: return "o"
        case 35: return "p"
        case 12: return "q"
        case 15: return "r"
        case 1: return "s"
        case 17: return "t"
        case 32: return "u"
        case 9: return "v"
        case 13: return "w"
        case 7: return "x"
        case 16: return "y"
        case 6: return "z"
        default: return ""
        }
    }
    
    func hideDropdown() {
        dropdownWindow?.orderOut(nil)
        dropdownWindow = nil
    }
    
    func insertFirstEmoji(_ emoji: String? = nil) {
        guard let selectedEmoji = emoji else { return }
        
        print("✨ Inserting emoji: '\(selectedEmoji)' (replacing ':\(currentEmojiText)')")
        
        // Hide dropdown first
        hideDropdown()
        
        // Smart deletion: If user only typed : then select, delete 1. If they typed :heart, letters were blocked so still delete 1
        let deleteCount = 1 // Always just the colon since letters are blocked
        print("🗑️ Will delete \(deleteCount) character (colon). Internal text: ':\(currentEmojiText)'")
        
        // Send backspaces to delete colon then type emoji
        DispatchQueue.main.async {
            print("🔥 Starting deletion and emoji insertion sequence...")
            
            // Set flag to prevent self-interception
            self.isInsertingEmoji = true
            
            // Send backspaces synchronously to delete the visible text
            for i in 0..<deleteCount {
                let source = CGEventSource(stateID: .hidSystemState)
                let backspaceDown = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true)
                let backspaceUp = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: false)
                
                backspaceDown?.post(tap: .cghidEventTap)
                backspaceUp?.post(tap: .cghidEventTap)
                
                print("⌫ Sent backspace \(i+1)/\(deleteCount)")
                Thread.sleep(forTimeInterval: 0.02)
            }
            
            // Longer delay before typing emoji
            Thread.sleep(forTimeInterval: 0.1)
            
            // Type the emoji
            print("🎯 About to type emoji: '\(selectedEmoji)'")
            self.typeText(selectedEmoji)
            print("✅ Finished typing emoji: '\(selectedEmoji)'")
            
            // IMPORTANT: Delay before clearing flag to ensure emoji is fully processed
            Thread.sleep(forTimeInterval: 0.2)
            
            // Clear flag and stop tracking
            self.isInsertingEmoji = false
            self.stopEmojiTracking()
        }
    }
    
    func typeText(_ text: String) {
        // Type text directly using CGEvent without using clipboard
        let source = CGEventSource(stateID: .hidSystemState)
        
        for character in text {
            let characterString = String(character)
            let utf16 = Array(characterString.utf16)
            
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            
            keyDown?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
            
            usleep(10000) // 10ms delay between characters
        }
    }
    
    func sendBackspace() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: false)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func sendPaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
} 