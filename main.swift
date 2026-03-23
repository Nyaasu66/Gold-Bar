import Cocoa
import Foundation

// MARK: - Data Model

struct QuoteEntry: Decodable {
    struct SpreadProfilePrice: Decodable {
        let spreadProfile: String
        let bid: Double
        let ask: Double
    }
    let spreadProfilePrices: [SpreadProfilePrice]
    let ts: Int64
}

// MARK: - App

class GoldBarApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastBid: Double = 0
    private var lastAsk: Double = 0
    private var lastUpdated: Date?
    private var fetchError = false

    private lazy var timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private lazy var menuBidItem   = NSMenuItem(title: "Bid: —", action: nil, keyEquivalent: "")
    private lazy var menuAskItem   = NSMenuItem(title: "Ask: —", action: nil, keyEquivalent: "")
    private lazy var menuSpreadItem = NSMenuItem(title: "Spread: —", action: nil, keyEquivalent: "")
    private lazy var menuTimeItem  = NSMenuItem(title: "Updated: —", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.title = "XAU/USD …"
            btn.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        }

        buildMenu()
        fetchPrice()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchPrice()
        }
    }

    // MARK: Menu

    private func buildMenu() {
        let menu = NSMenu()

        for item in [menuBidItem, menuAskItem, menuSpreadItem, menuTimeItem] {
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let refresh = NSMenuItem(title: "立即刷新", action: #selector(refreshNow), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func refreshNow() {
        fetchPrice()
    }

    private func updateMenu() {
        let spread = lastAsk - lastBid
        let time = lastUpdated.map { timeFmt.string(from: $0) } ?? "—"
        menuBidItem.title    = String(format: "Bid:    $%.2f", lastBid)
        menuAskItem.title    = String(format: "Ask:    $%.2f", lastAsk)
        menuSpreadItem.title = String(format: "Spread: $%.2f", spread)
        menuTimeItem.title   = "Updated: \(time)"
    }

    // MARK: Fetch

    private func fetchPrice() {
        let url = URL(string: "https://forex-data-feed.swissquote.com/public-quotes/bboquotes/instrument/XAU/USD")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            guard let data,
                  let entries = try? JSONDecoder().decode([QuoteEntry].self, from: data),
                  let entry = entries.first,
                  let price = entry.spreadProfilePrices.first(where: { $0.spreadProfile == "standard" })
                              ?? entry.spreadProfilePrices.first
            else {
                DispatchQueue.main.async { self.setError() }
                return
            }

            let bid = price.bid
            let ask = price.ask
            let mid = (bid + ask) / 2.0

            DispatchQueue.main.async {
                self.fetchError = false
                self.lastBid = bid
                self.lastAsk = ask
                self.lastUpdated = Date()
                self.statusItem.button?.title = String(format: "XAU $%.2f", mid)
                self.updateMenu()
            }
        }.resume()
    }

    private func setError() {
        fetchError = true
        statusItem.button?.title = "XAU ⚠"
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = GoldBarApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // 不显示 Dock 图标
app.run()
