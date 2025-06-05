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
    
    enum CodingKeys: String, CodingKey {
        case name
        case unified
        case shortName = "short_name"
        case shortNames = "short_names"
        case category
        case sortOrder = "sort_order"
        case addedIn = "added_in"
        case hasImgApple = "has_img_apple"
    }
    
    // Convert Unicode string to actual emoji
    var emoji: String {
        guard !unified.isEmpty else { return "" }
        
        // Handle compound emojis (with hyphens)
        let codePoints = unified.components(separatedBy: "-")
        
        var chars: [Character] = []
        for codePoint in codePoints {
            if let scalar = UnicodeScalar(Int(codePoint, radix: 16) ?? 0) {
                chars.append(Character(scalar))
            }
        }
        
        return String(chars)
    }
}

// MARK: - Emoji Database Manager
class EmojiDatabase: ObservableObject {
    @Published var allEmojis: [EmojiData] = []
    @Published var isLoaded = false
    
    private var categorizedEmojis: [String: [EmojiData]] = [:]
    
    init() {
        loadEmojis()
    }
    
    func loadEmojis() {
        guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json") else {
            print("❌ Could not find emoji.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let emojis = try JSONDecoder().decode([EmojiData].self, from: data)
            
            DispatchQueue.main.async {
                // Filter out emojis that don't render on Apple platforms
                self.allEmojis = emojis.filter { $0.hasImgApple }
                self.categorizeEmojis()
                self.isLoaded = true
                print("✅ Loaded \(self.allEmojis.count) emojis")
            }
        } catch {
            print("❌ Error loading emojis: \(error)")
        }
    }
    
    private func categorizeEmojis() {
        categorizedEmojis = Dictionary(grouping: allEmojis) { $0.category }
    }
    
    // MARK: - Search Functions
    func searchEmojis(query: String) -> [EmojiData] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        return allEmojis.filter { emoji in
            // Search in name
            emoji.name.lowercased().contains(lowercaseQuery) ||
            // Search in short names
            emoji.shortNames.contains { $0.lowercased().contains(lowercaseQuery) } ||
            // Search in category
            emoji.category.lowercased().contains(lowercaseQuery)
        }
    }
    
    func getEmojisByCategory(_ category: String) -> [EmojiData] {
        return categorizedEmojis[category] ?? []
    }
    
    func getAllCategories() -> [String] {
        return Array(categorizedEmojis.keys).sorted()
    }
    
    // MARK: - Quick Access for Popular Emojis
    func getPopularEmojis() -> [EmojiData] {
        // Return some commonly used emojis
        let popularShortNames = ["heart", "smile", "thumbsup", "fire", "star", "party", "clap", "100"]
        
        return popularShortNames.compactMap { shortName in
            allEmojis.first { $0.shortNames.contains(shortName) }
        }
    }
    
    // MARK: - Category-specific getters
    func getSmileysAndEmotions() -> [EmojiData] {
        return getEmojisByCategory("Smileys & Emotion")
    }
    
    func getHeartsAndLove() -> [EmojiData] {
        return allEmojis.filter { emoji in
            emoji.category == "Smileys & Emotion" && 
            (emoji.shortNames.contains { $0.contains("heart") } || 
             emoji.name.lowercased().contains("heart") ||
             emoji.name.lowercased().contains("love") ||
             emoji.name.lowercased().contains("kiss"))
        }
    }
    
    func getGestures() -> [EmojiData] {
        return getEmojisByCategory("People & Body").filter { emoji in
            emoji.name.lowercased().contains("hand") ||
            emoji.name.lowercased().contains("finger") ||
            emoji.name.lowercased().contains("thumbs") ||
            emoji.name.lowercased().contains("wave") ||
            emoji.name.lowercased().contains("clap")
        }
    }
    
    func getAnimalsAndNature() -> [EmojiData] {
        return getEmojisByCategory("Animals & Nature")
    }
    
    func getFoodAndDrink() -> [EmojiData] {
        return getEmojisByCategory("Food & Drink")
    }
    
    func getActivities() -> [EmojiData] {
        return getEmojisByCategory("Activities")
    }
    
    func getSymbols() -> [EmojiData] {
        return getEmojisByCategory("Symbols")
    }
} 