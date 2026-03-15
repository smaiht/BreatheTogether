import SwiftUI
import AppKit

// MARK: - Settings

class BreathSettings: ObservableObject {
    static let shared = BreathSettings()
    @Published var fillPresetId: String { didSet { save("fillPresetId", fillPresetId) } }
    @Published var trackPresetId: String { didSet { save("trackPresetId", trackPresetId) } }
    @Published var fillCustom: Color { didSet { saveColor("fillCustom", fillCustom) } }
    @Published var trackCustom: Color { didSet { saveColor("trackCustom", trackCustom) } }
    @Published var position: String { didSet { save("position", position) } }
    @Published var customX: Double { didSet { UserDefaults.standard.set(customX, forKey: "customX") } }
    @Published var customY: Double { didSet { UserDefaults.standard.set(customY, forKey: "customY") } }
    @Published var trayIcon: String { didSet { save("trayIcon", trayIcon) } }
    @Published var trayText: String { didSet { save("trayText", trayText) } }
    @Published var draggable: Bool = false {
        didSet { UserDefaults.standard.set(draggable, forKey: "draggable") }
    }
    @Published var showOnline: Bool { didSet { UserDefaults.standard.set(showOnline, forKey: "showOnline") } }
    @Published var pollInterval: Double { didSet { UserDefaults.standard.set(pollInterval, forKey: "pollInterval") } }
    @Published var breathMode: String { didSet { save("breathMode", breathMode) } }
    @Published var breathGender: String { didSet { save("breathGender", breathGender) } }
    @Published var breathHeight: Double { didSet { UserDefaults.standard.set(breathHeight, forKey: "breathHeight") } }
    @Published var breathSegments: Int { didSet { UserDefaults.standard.set(breathSegments, forKey: "breathSegments") } }
    @Published var barWidth: Double { didSet { UserDefaults.standard.set(barWidth, forKey: "barWidth") } }
    var onChanged: (() -> Void)?
    var onDraggableChanged: (() -> Void)?
    var onOnlineChanged: (() -> Void)?
    var onIconChanged: (() -> Void)?

    init() {
        fillPresetId = UserDefaults.standard.string(forKey: "fillPresetId") ?? "white85"
        trackPresetId = UserDefaults.standard.string(forKey: "trackPresetId") ?? "white50"
        fillCustom = Self.loadColor("fillCustom") ?? .white
        trackCustom = Self.loadColor("trackCustom") ?? .gray
        position = UserDefaults.standard.string(forKey: "position") ?? "left"
        customX = UserDefaults.standard.object(forKey: "customX") != nil ? UserDefaults.standard.double(forKey: "customX") : 54
        customY = UserDefaults.standard.object(forKey: "customY") != nil ? UserDefaults.standard.double(forKey: "customY") : 1
        trayIcon = UserDefaults.standard.string(forKey: "trayIcon") ?? "custom"
        trayText = UserDefaults.standard.string(forKey: "trayText") ?? ""
        draggable = UserDefaults.standard.bool(forKey: "draggable")
        showOnline = UserDefaults.standard.object(forKey: "showOnline") != nil ? UserDefaults.standard.bool(forKey: "showOnline") : false
        pollInterval = UserDefaults.standard.object(forKey: "pollInterval") != nil ? UserDefaults.standard.double(forKey: "pollInterval") : 60
        breathMode = UserDefaults.standard.string(forKey: "breathMode") ?? "standard"
        breathGender = UserDefaults.standard.string(forKey: "breathGender") ?? "male"
        breathHeight = UserDefaults.standard.object(forKey: "breathHeight") != nil ? UserDefaults.standard.double(forKey: "breathHeight") : 175
        breathSegments = UserDefaults.standard.object(forKey: "breathSegments") != nil ? UserDefaults.standard.integer(forKey: "breathSegments") : 10
        barWidth = UserDefaults.standard.object(forKey: "barWidth") != nil ? UserDefaults.standard.double(forKey: "barWidth") : 220
    }

    var computedInhale: Double {
        if breathMode == "personal" {
            let rf = breathGender == "male"
                ? 17.9 - 0.07 * breathHeight
                : 15.88 - 0.06 * breathHeight
            return max(2, 60.0 / (2.0 * max(1, rf)))
        }
        return 5.5
    }
    var computedCycleDuration: Double { computedInhale * 2 }
    var computedSegments: Int { max(3, min(30, breathSegments)) }

    func apply() { onChanged?(); onIconChanged?(); onOnlineChanged?() }
    private func save(_ k: String, _ v: String) { UserDefaults.standard.set(v, forKey: k) }

    func resolve(_ presetId: String, _ custom: Color) -> CGColor {
        if presetId == "custom" { return NSColor(custom).cgColor }
        return ColorPreset.all.first { $0.id == presetId }?.color.cgColor ?? NSColor.white.cgColor
    }
    var fillCG: CGColor { resolve(fillPresetId, fillCustom) }
    var trackCG: CGColor { resolve(trackPresetId, trackCustom) }

    func barX(screenW: CGFloat, barW: CGFloat) -> CGFloat {
        switch position {
        case "left": return 54
        case "right": return screenW - barW - 20
        case "custom", "draggable": return customX
        default: return (screenW - barW) / 2
        }
    }
    func winY(screen: NSScreen, winH: CGFloat) -> CGFloat {
        switch position {
        case "left", "right": return screen.frame.maxY - 1 - winH
        case "custom", "draggable": return screen.frame.maxY - customY - winH
        default: return screen.frame.maxY - screen.safeAreaInsets.top - winH
        }
    }

    private func saveColor(_ k: String, _ c: Color) {
        if let d = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(c), requiringSecureCoding: false) {
            UserDefaults.standard.set(d, forKey: k)
        }
    }
    private static func loadColor(_ k: String) -> Color? {
        guard let d = UserDefaults.standard.data(forKey: k),
              let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: d) else { return nil }
        return Color(c)
    }
}

struct ColorPreset: Identifiable, Hashable {
    let id: String; let name: String; let color: NSColor
    static let all: [ColorPreset] = [
        .init(id: "white85", name: "White 85%", color: NSColor.white.withAlphaComponent(0.85)),
        .init(id: "white50", name: "White 50%", color: NSColor.white.withAlphaComponent(0.5)),
        .init(id: "white30", name: "White 30%", color: NSColor.white.withAlphaComponent(0.3)),
        .init(id: "systemBlue", name: "Blue", color: .systemBlue),
        .init(id: "systemGreen", name: "Green", color: .systemGreen),
        .init(id: "systemPurple", name: "Purple", color: .systemPurple),
        .init(id: "systemPink", name: "Pink", color: .systemPink),
        .init(id: "systemOrange", name: "Orange", color: .systemOrange),
        .init(id: "systemRed", name: "Red", color: .systemRed),
        .init(id: "systemTeal", name: "Teal", color: .systemTeal),
        .init(id: "controlAccent", name: "Accent Color", color: .controlAccentColor),
    ]
}

// MARK: - Views

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                AppearanceTab().tabItem { Label("Appearance", systemImage: "paintpalette") }
                IconTab().tabItem { Label("Icon", systemImage: "menubar.rectangle") }
                BreathingTab().tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
            }
            Divider()
            HStack {
                Spacer()
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                Button("Apply") { BreathSettings.shared.apply() }
                    .keyboardShortcut(.defaultAction)
            }.padding(.horizontal, 20).padding(.vertical, 12)
        }
        .frame(minWidth: 680, minHeight: 520)
    }
}

struct BreathingTab: View {
    @ObservedObject var s = BreathSettings.shared
    var rf: Double {
        s.breathGender == "male"
            ? 17.9 - 0.07 * s.breathHeight
            : 15.88 - 0.06 * s.breathHeight
    }
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left: breathing mode
            VStack(alignment: .leading, spacing: 10) {
                Text("Breathing rhythm").font(.headline)

                Radio("Standard", on: s.breathMode == "standard") { s.breathMode = "standard" }
                Text("Universal 5.50s rhythm — works for everyone. Breathe together with people around the world and share the energy.")
                    .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 22).padding(.bottom, 4)
                breathStats(inhale: 5.5, cycle: 11.0).padding(.leading, 22)

                Radio("Personal", on: s.breathMode == "personal") {
                    s.breathMode = "personal"
                    s.showOnline = false; s.onOnlineChanged?()
                }
                Text("Optimal rhythm based on your body. You breathe at your own pace — not in sync with others.")
                    .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 22).padding(.bottom, 4)

                let on = s.breathMode == "personal"

                VStack(alignment: .leading, spacing: 8) {
                    Radio("Male", on: s.breathGender == "male") { s.breathGender = "male" }
                    Radio("Female", on: s.breathGender == "female") { s.breathGender = "female" }

                    HStack(spacing: 4) {
                        Text("Height:")
                        TextField("", value: $s.breathHeight, format: .number).frame(width: 50)
                        Text("cm")
                    }

                    Text("Eston & Reilly respiratory rate model")
                        .font(.caption2).foregroundColor(.secondary.opacity(0.6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("♂  RF = 17.9 − 0.07 × height(cm)")
                        Text("♀  RF = 15.88 − 0.06 × height(cm)")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.3)))

                    let coef = s.breathGender == "male" ? "0.07" : "0.06"
                    let base = s.breathGender == "male" ? "17.9" : "15.88"
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RF = \(base) − \(coef) × \(Int(s.breathHeight)) = \(String(format: "%.2f", rf)) breaths/min")
                        Text("T  = 60 / (2 × \(String(format: "%.2f", rf))) = \(String(format: "%.2f", s.computedInhale))s")
                    }.font(.system(.caption, design: .monospaced))

                    breathStats(inhale: s.computedInhale, cycle: s.computedCycleDuration)
                }
                .padding(.leading, 22)
                .disabled(!on).opacity(on ? 1 : 0.4)
            }.frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right: online + segments
            VStack(alignment: .leading, spacing: 16) {
                Text("Online sync").font(.headline)
                Text("See how many people are breathing with you right now. Available in Standard mode — everyone shares the same rhythm.")
                    .font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)
                Toggle("Enable", isOn: $s.showOnline)
                    .onChange(of: s.showOnline) { _ in s.onOnlineChanged?() }
                    .toggleStyle(.switch)
                    .disabled(s.breathMode != "standard")
                    .opacity(s.breathMode == "standard" ? 1 : 0.4)
                HStack(spacing: 4) {
                    Text("Check every")
                    TextField("", value: $s.pollInterval, format: .number).frame(width: 40)
                    Text("sec")
                }.disabled(!s.showOnline || s.breathMode != "standard")
                    .opacity(s.showOnline && s.breathMode == "standard" ? 1 : 0.4)

                Spacer()
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(20)
    }

    func breathStats(inhale: Double, cycle: Double) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 2) {
            GridRow { Text("Inhale"); Text(String(format: "%.2fs", inhale)) }
            GridRow { Text("Exhale"); Text(String(format: "%.2fs", inhale)) }
            GridRow { Text("Cycle");  Text(String(format: "%.2fs", cycle)) }
        }.font(.system(.caption, design: .monospaced)).foregroundColor(.secondary)
    }
}

struct Radio: View {
    let label: String; let on: Bool; let action: () -> Void
    init(_ label: String, on: Bool, action: @escaping () -> Void) {
        self.label = label; self.on = on; self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(on ? .accentColor : .secondary)
                Text(label).foregroundColor(.primary)
            }
        }.buttonStyle(.plain)
    }
}

struct AppearanceTab: View {
    @ObservedObject var s = BreathSettings.shared
    @State private var editX: String = ""
    @State private var editY: String = ""
    let presets: [(id: String, name: String, icon: String)] = [
        ("left", "Top left (54, 1)", "arrow.up.left"),
        ("right", "Top right", "arrow.up.right"),
        ("center", "Center (under notch)", "arrow.down"),
        ("custom", "Custom", "pencil"),
        ("draggable", "Draggable (use mouse)", "hand.draw"),
    ]
    func coordsForPosition(_ pos: String) -> (Double, Double) {
        let bw = s.barWidth
        switch pos {
        case "left": return (54, 1)
        case "right":
            let sw = NSScreen.main?.frame.width ?? 1440
            return (sw - bw - 20, 1)
        case "center":
            let sw = NSScreen.main?.frame.width ?? 1440
            return ((sw - bw) / 2, Double(NSScreen.main?.safeAreaInsets.top ?? 24))
        case "custom", "draggable": return (s.customX, s.customY)
        default: return (s.customX, s.customY)
        }
    }
    func syncFields() {
        let (x, y) = coordsForPosition(s.position)
        editX = String(Int(x))
        editY = String(Int(y))
    }
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Column 1: Position + Segments
            VStack(alignment: .leading, spacing: 10) {
                Text("Position").font(.headline)
                ForEach(presets, id: \.id) { p in
                    Button(action: {
                        s.position = p.id
                        if p.id == "draggable" { s.draggable = true; s.onDraggableChanged?() }
                        else { s.draggable = false; s.onDraggableChanged?() }
                        syncFields(); s.apply()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: s.position == p.id ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(s.position == p.id ? .accentColor : .secondary)
                            Image(systemName: p.icon).frame(width: 16)
                            Text(p.name).foregroundColor(.primary)
                        }
                    }.buttonStyle(.plain)
                }
                HStack {
                    Text("X:"); TextField("", text: $editX).frame(width: 50)
                    Text("Y:"); TextField("", text: $editY).frame(width: 50)
                    Button("Set") {
                        let x = Double(editX), y = Double(editY)
                        if let x, let y, x >= 0, y >= 0 { s.customX = x; s.customY = y }
                        else { s.customX = 54; s.customY = 1; editX = "54"; editY = "1" }
                        s.position = "custom"; s.draggable = false; s.onDraggableChanged?(); s.apply()
                    }
                }

                Divider()
                Text("Segments").font(.headline)
                HStack {
                    TextField("", value: $s.breathSegments, format: .number).frame(width: 40)
                    Stepper("", value: $s.breathSegments, in: 3...30).labelsHidden()
                }
                Text("\(BreathSettings.shared.computedSegments) × \(String(format: "%.2f", s.computedInhale / Double(s.computedSegments)))s each")
                    .font(.caption).foregroundColor(.secondary)

                Divider()
                Text("Bar width").font(.headline)
                HStack {
                    TextField("", value: $s.barWidth, format: .number).frame(width: 50)
                    Text("px")
                    Button("Set") { s.apply() }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Column 2: Fill color
            ColorColumn(title: "Fill", presetId: $s.fillPresetId, custom: $s.fillCustom)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Column 3: Track color
            ColorColumn(title: "Track", presetId: $s.trackPresetId, custom: $s.trackCustom)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .onAppear { syncFields() }
        .onChange(of: s.customX) { _ in if s.position == "draggable" { editX = String(Int(s.customX)) } }
        .onChange(of: s.customY) { _ in if s.position == "draggable" { editY = String(Int(s.customY)) } }
    }
}

struct ColorColumn: View {
    let title: String
    @Binding var presetId: String
    @Binding var custom: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(.headline, weight: .semibold))
                .padding(.bottom, 4)
            ForEach(ColorPreset.all) { p in
                RadioRow(label: p.name, swatch: Color(p.color), on: presetId == p.id) {
                    presetId = p.id; BreathSettings.shared.apply()
                }
            }
            RadioRow(label: "Custom…", swatch: custom, on: presetId == "custom") {
                presetId = "custom"; BreathSettings.shared.apply()
            }
            if presetId == "custom" {
                ColorPicker("", selection: $custom, supportsOpacity: true)
                    .labelsHidden()
                    .onChange(of: custom) { _ in BreathSettings.shared.apply() }
            }
        }
    }
}

struct RadioRow: View {
    let label: String; let swatch: Color; let on: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(on ? .accentColor : .secondary)
                // Checkerboard bg so white/transparent colors are visible
                ZStack {
                    CheckerBoard()
                        .frame(width: 18, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(swatch)
                        .frame(width: 18, height: 12)
                }
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(.secondary.opacity(0.3), lineWidth: 0.5))
                Text(label).foregroundColor(.primary)
            }
        }.buttonStyle(.plain)
    }
}

struct CheckerBoard: View {
    var body: some View {
        Canvas { ctx, size in
            let s: CGFloat = 4
            for row in 0..<Int(ceil(size.height / s)) {
                for col in 0..<Int(ceil(size.width / s)) {
                    let c: Color = (row + col).isMultiple(of: 2) ? .white : Color(white: 0.78)
                    ctx.fill(Path(CGRect(x: CGFloat(col) * s, y: CGFloat(row) * s, width: s, height: s)), with: .color(c))
                }
            }
        }
    }
}


struct IconTab: View {
    @ObservedObject var s = BreathSettings.shared
    let icons: [(id: String, label: String)] = [
        ("custom", "Breath (custom drawn)"),
        ("wind", "Wind"),
        ("leaf", "Leaf"),
        ("lungs", "Lungs"),
        ("sparkles", "Sparkles"),
        ("cloud", "Cloud"),
        ("humidity", "Humidity"),
        ("text", "Custom text"),
    ]
    var body: some View {
        VStack { Spacer(); HStack { Spacer()
        VStack(alignment: .leading, spacing: 8) {
            ForEach(icons, id: \.id) { icon in
                Button(action: { s.trayIcon = icon.id; s.onIconChanged?() }) {
                    HStack(spacing: 8) {
                        Image(systemName: s.trayIcon == icon.id ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(s.trayIcon == icon.id ? .accentColor : .secondary)
                        if icon.id != "custom" && icon.id != "text" {
                            Image(systemName: icon.id).frame(width: 18)
                        }
                        Text(icon.label).foregroundColor(.primary)
                    }
                }.buttonStyle(.plain)
            }
            HStack {
                TextField("breathe", text: $s.trayText).frame(width: 140)
                Button("Set") { s.onIconChanged?() }
            }.disabled(s.trayIcon != "text")
        }.padding(20)
        Spacer() }; Spacer() }
    }
}

// MARK: - App

@main
struct BreatheTogetherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { SwiftUI.Settings { EmptyView() } }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayWindow: NSWindow!
    var settingsWindow: NSWindow?
    var segmentLayers: [CALayer] = []
    var onlineTimer: Timer?
    var onlineMenuItem: NSMenuItem!
    let barHeight: CGFloat = 4
    let segmentGap: CGFloat = 3

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.applicationIconImage = makeAppIcon()
        guard let screen = NSScreen.main else { return }
        let s = BreathSettings.shared
        let winH: CGFloat = barHeight + 4
        let bw = CGFloat(s.barWidth)
        let winX = s.barX(screenW: screen.frame.width, barW: bw)
        let winY = s.winY(screen: screen, winH: winH)

        overlayWindow = NSWindow(contentRect: NSRect(x: winX, y: winY, width: bw, height: winH),
                                  styleMask: .borderless, backing: .buffered, defer: false)
        overlayWindow.level = .statusBar
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let view = NSView(frame: NSRect(x: 0, y: 0, width: bw, height: winH))
        view.wantsLayer = true
        overlayWindow.contentView = view

        buildSegments(in: view.layer!, barY: (winH - barHeight) / 2)

        overlayWindow.orderFrontRegardless()
        s.onChanged = { [weak self] in self?.applySettings() }
        s.onDraggableChanged = { [weak self] in self?.updateDraggable() }
        updateDraggable()

        // Pause rendering when display sleeps — zero energy when nobody is looking
        let wsnc = NSWorkspace.shared.notificationCenter
        wsnc.addObserver(self, selector: #selector(displayDidWake),
                         name: NSWorkspace.screensDidWakeNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(displayDidSleep),
                         name: NSWorkspace.screensDidSleepNotification, object: nil)

        applySegmentAnimations(s: s)
        setupMenu()
        s.onOnlineChanged = { [weak self] in self?.startOnlinePolling() }
        s.onIconChanged = { [weak self] in self?.applyIcon() }
        startOnlinePolling()
        checkForUpdate()
    }

    // MARK: - Update checker

    static let currentVersion = "1.0.0"
    static let githubRepo = "smaiht/BreatheTogether" // TODO: set real repo!

    func checkForUpdate() {
        guard let url = URL(string: "https://api.github.com/repos/\(Self.githubRepo)/releases/latest") else { return }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            guard let data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let assets = json["assets"] as? [[String: Any]] else { return }
            let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            guard remote.compare(Self.currentVersion, options: .numeric) == .orderedDescending else { return }
            let dmgAsset = assets.first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
            guard let downloadURL = dmgAsset?["browser_download_url"] as? String else { return }
            DispatchQueue.main.async { self?.showUpdateAlert(version: remote, url: downloadURL) }
        }.resume()
    }

    func showUpdateAlert(version: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Breathe Together v\(version) is available. Download now?"
        alert.alertStyle = .informational
        alert.icon = makeAppIcon()
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn,
              let dmgURL = URL(string: url) else { return }
        downloadUpdate(from: dmgURL, version: version)
    }

    func downloadUpdate(from url: URL, version: String) {
        let dest = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads/BreatheTogether-\(version).dmg")
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL, error == nil else { return }
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.moveItem(at: tempURL, to: dest)
            DispatchQueue.main.async { NSWorkspace.shared.open(dest) }
        }.resume()
    }

    // MARK: - Online polling

    func startOnlinePolling() {
        onlineTimer?.invalidate()
        onlineTimer = nil
        let s = BreathSettings.shared
        guard s.showOnline else {
            onlineMenuItem?.title = "🌍 —"
            return
        }
        pollOnline()
        let interval = max(5, s.pollInterval)
        onlineTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pollOnline()
        }
    }

    func stopOnlinePolling() {
        onlineTimer?.invalidate()
        onlineTimer = nil
    }

    func pollOnline() {
        guard let url = URL(string: "https://ny.gy/api/online") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self, let data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let total = json["total"] as? Int else {
                    self?.onlineMenuItem?.title = "🌍 —"
                    return
                }
                self.onlineMenuItem?.title = "🌍 \(total) breathing in sync"
            }
        }.resume()
    }

    @objc func displayDidSleep() {
        segmentLayers.forEach { $0.removeAllAnimations() }
        stopOnlinePolling()
    }

    @objc func displayDidWake() {
        applySegmentAnimations(s: BreathSettings.shared)
        startOnlinePolling()
    }

    var dragMonitor: Any?

    func updateDraggable() {
        let on = BreathSettings.shared.draggable
        overlayWindow.ignoresMouseEvents = !on

        if let m = dragMonitor { NSEvent.removeMonitor(m); dragMonitor = nil }
        if on {
            var dragStart: NSPoint = .zero
            var winStart: NSPoint = .zero
            dragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged]) { [weak self] event in
                guard let self else { return event }
                let loc = NSEvent.mouseLocation
                if event.type == .leftMouseDown {
                    dragStart = loc
                    winStart = self.overlayWindow.frame.origin
                } else if event.type == .leftMouseDragged {
                    let newOrigin = NSPoint(x: winStart.x + loc.x - dragStart.x,
                                            y: winStart.y + loc.y - dragStart.y)
                    self.overlayWindow.setFrameOrigin(newOrigin)
                    let s = BreathSettings.shared
                    s.customX = Double(newOrigin.x)
                    if let screen = NSScreen.main {
                        s.customY = Double(screen.frame.maxY - newOrigin.y - self.overlayWindow.frame.height)
                    }
                }
                return event
            }
        }
    }

    func applySegmentAnimations(s: BreathSettings) {
        let inhale = s.computedInhale
        let cycleDuration = s.computedCycleDuration
        let segmentCount = s.computedSegments
        let step = inhale / Double(segmentCount)
        let now = CACurrentMediaTime()
        let epoch = Date().timeIntervalSince1970
        let cycleOffset = epoch.truncatingRemainder(dividingBy: cycleDuration)
        let baseTime = now - cycleOffset

        for (i, seg) in segmentLayers.enumerated() {
            seg.removeAllAnimations()
            let onTime = Double(i) * step / cycleDuration
            let offTime = (inhale + Double(segmentCount - 1 - i) * step) / cycleDuration

            let anim = CAKeyframeAnimation(keyPath: "backgroundColor")
            anim.calculationMode = .discrete
            anim.keyTimes = [0, NSNumber(value: onTime), NSNumber(value: offTime), 1] as [NSNumber]
            anim.values = [s.trackCG, s.fillCG, s.trackCG, s.trackCG]
            anim.duration = cycleDuration
            anim.repeatCount = .infinity
            anim.beginTime = baseTime
            anim.isRemovedOnCompletion = false
            seg.add(anim, forKey: "breath")
        }
    }

    func buildSegments(in parent: CALayer, barY: CGFloat) {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()
        let s = BreathSettings.shared
        let count = s.computedSegments
        let bw = max(CGFloat(count) * 2 + segmentGap * CGFloat(count - 1), CGFloat(s.barWidth))
        let segW = (bw - segmentGap * CGFloat(count - 1)) / CGFloat(count)
        for i in 0..<count {
            let seg = CALayer()
            seg.frame = CGRect(x: CGFloat(i) * (segW + segmentGap), y: barY, width: segW, height: barHeight)
            seg.cornerRadius = 1.5
            parent.addSublayer(seg)
            segmentLayers.append(seg)
        }
    }

    func applySettings() {
        guard let screen = NSScreen.main else { return }
        let s = BreathSettings.shared
        let bw = CGFloat(s.barWidth)
        let winH: CGFloat = barHeight + 4
        let winX = s.barX(screenW: screen.frame.width, barW: bw)
        overlayWindow.setFrame(NSRect(x: winX, y: s.winY(screen: screen, winH: winH), width: bw, height: winH), display: true)
        overlayWindow.contentView?.frame = NSRect(x: 0, y: 0, width: bw, height: winH)
        buildSegments(in: overlayWindow.contentView!.layer!, barY: (winH - barHeight) / 2)
        applySegmentAnimations(s: s)
    }

    func makeAppIcon() -> NSImage {
        let s: CGFloat = 256
        return NSImage(size: NSSize(width: s, height: s), flipped: false) { _ in
            // Blue circle background
            let bg = NSBezierPath(ovalIn: NSRect(x: 8, y: 8, width: s - 16, height: s - 16))
            NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1).setFill()
            bg.fill()
            // White breath curves
            let p = NSBezierPath()
            p.move(to: NSPoint(x: 48, y: 80))
            p.curve(to: NSPoint(x: 208, y: 80), controlPoint1: NSPoint(x: 88, y: 30), controlPoint2: NSPoint(x: 168, y: 130))
            p.move(to: NSPoint(x: 56, y: 128))
            p.curve(to: NSPoint(x: 200, y: 128), controlPoint1: NSPoint(x: 96, y: 178), controlPoint2: NSPoint(x: 160, y: 78))
            p.move(to: NSPoint(x: 64, y: 176))
            p.curve(to: NSPoint(x: 184, y: 184), controlPoint1: NSPoint(x: 92, y: 210), controlPoint2: NSPoint(x: 160, y: 155))
            p.lineWidth = 14; p.lineCapStyle = .round
            NSColor.white.setStroke(); p.stroke()
            return true
        }
    }

    func applyIcon() {
        guard let btn = statusItem?.button else { return }
        let s = BreathSettings.shared
        btn.image = nil
        btn.title = ""
        if s.trayIcon == "text" {
            btn.title = s.trayText.isEmpty ? "breathe" : s.trayText
        } else if s.trayIcon == "custom" {
            let size = NSSize(width: 18, height: 18)
            let img = NSImage(size: size, flipped: false) { _ in
                let p = NSBezierPath()
                p.move(to: NSPoint(x: 2, y: 5))
                p.curve(to: NSPoint(x: 16, y: 5), controlPoint1: NSPoint(x: 6, y: 1), controlPoint2: NSPoint(x: 12, y: 9))
                p.move(to: NSPoint(x: 3, y: 9))
                p.curve(to: NSPoint(x: 15, y: 9), controlPoint1: NSPoint(x: 7, y: 13), controlPoint2: NSPoint(x: 11, y: 5))
                p.move(to: NSPoint(x: 4, y: 13))
                p.curve(to: NSPoint(x: 13, y: 14), controlPoint1: NSPoint(x: 7, y: 16), controlPoint2: NSPoint(x: 11, y: 11))
                p.lineWidth = 1.5; p.lineCapStyle = .round
                NSColor.black.setStroke(); p.stroke()
                return true
            }
            img.isTemplate = true
            btn.image = img
        } else {
            let img = NSImage(systemSymbolName: s.trayIcon, accessibilityDescription: "Breathe")
            img?.isTemplate = true
            btn.image = img
        }
    }

    func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyIcon()
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Breathe Together", action: nil, keyEquivalent: ""))
        onlineMenuItem = NSMenuItem(title: "🌍 connecting…", action: #selector(noop), keyEquivalent: "")
        onlineMenuItem.target = self
        menu.addItem(onlineMenuItem)
        menu.addItem(NSMenuItem.separator())
        let ei = NSMenuItem(title: "Edit icon text…", action: #selector(editIconText), keyEquivalent: "e")
        ei.target = self; menu.addItem(ei)
        let si = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        si.target = self; menu.addItem(si)
        let ui = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdateManual), keyEquivalent: "u")
        ui.target = self; menu.addItem(ui)
        menu.addItem(NSMenuItem.separator())
        let qi = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        qi.target = self; menu.addItem(qi)
        statusItem.menu = menu
    }

    @objc func openSettings() {
        if let w = settingsWindow { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Breathe Settings"
        w.contentView = NSHostingView(rootView: SettingsView())
        w.center(); w.isReleasedWhenClosed = false; w.level = .floating
        settingsWindow = w
        w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() { NSApp.terminate(nil) }
    @objc func noop() {}
    @objc func checkForUpdateManual() { checkForUpdate() }

    @objc func editIconText() {
        let alert = NSAlert()
        alert.messageText = "Menu bar text"
        alert.informativeText = "A short word or phrase always visible in your menu bar — a gentle reminder to breathe, stay present, or anything meaningful to you.\n\nbreathe · be here · let go · 🌊 · ॐ"
        alert.icon = makeAppIcon()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 180, height: 24))
        input.stringValue = BreathSettings.shared.trayText.isEmpty ? "breathe" : BreathSettings.shared.trayText
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let s = BreathSettings.shared
            s.trayText = input.stringValue
            s.trayIcon = "text"
            applyIcon()
        }
    }

}
