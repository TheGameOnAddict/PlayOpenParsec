import Foundation

enum KeypadMode: String, Codable, CaseIterable {
    case hold = "Hold", toggle = "Toggle", tap = "Tap only"
}

struct KeypadButton: Identifiable, Codable {
    var id = UUID()
    var label: String
    var keys: [UInt32]
    var mode: KeypadMode = .hold
    // Fractions of the available travel keep buttons reachable after rotation.
    var x: Double = 0.5
    var y: Double = 0.5
}

enum KeypadKeys {
    static let all: [(name: String, code: UInt32)] = {
        var keys: [(String, UInt32)] = [("Ctrl", 224), ("Shift", 225), ("Alt", 226), ("Win / Cmd", 227)]
        keys += (0..<26).map { (String(UnicodeScalar(65 + $0)!), UInt32(4 + $0)) }
        keys += (1...9).map { (String($0), UInt32(29 + $0)) }
        keys += [("0", 39), ("Enter", 40), ("Esc", 41), ("Backspace", 42), ("Tab", 43), ("Space", 44),
                 ("-", 45), ("=", 46), ("[", 47), ("]", 48), ("Backslash", 49), (";", 51),
                 ("Quote", 52), ("`", 53), (",", 54), (".", 55), ("/", 56), ("Caps Lock", 57)]
        keys += (1...12).map { ("F\($0)", UInt32(57 + $0)) }
        keys += [("Print Screen", 70), ("Scroll Lock", 71), ("Pause", 72), ("Insert", 73), ("Home", 74),
                 ("Page Up", 75), ("Delete", 76), ("End", 77), ("Page Down", 78),
                 ("Right", 79), ("Left", 80), ("Down", 81), ("Up", 82)]
        return keys
    }()

    static func name(_ code: UInt32) -> String { all.first { $0.code == code }?.name ?? "\(code)" }
}

// Each button owns its chord. Shared modifiers stay down until the last owner releases.
final class KeypadInput {
    private(set) var active: [UUID: [UInt32]] = [:]
    private var counts: [UInt32: Int] = [:]
    private let send: (UInt32, Bool) -> Void

    init(send: @escaping (UInt32, Bool) -> Void) { self.send = send }

    func down(_ button: KeypadButton) {
        if button.mode == .toggle, active[button.id] != nil { release(button.id); return }
        guard active[button.id] == nil else { return }
        // Modifiers always precede ordinary keys, regardless of selection order.
        let keys = Array(Set(button.keys)).sorted {
            let a = (224...231).contains($0), b = (224...231).contains($1)
            return a == b ? $0 < $1 : a
        }
        active[button.id] = keys
        for key in keys {
            if counts[key, default: 0] == 0 { send(key, true) }
            counts[key, default: 0] += 1
        }
        if button.mode == .tap { release(button.id) }
    }

    func up(_ button: KeypadButton) {
        if button.mode == .hold { release(button.id) }
    }

    func release(_ id: UUID) {
        guard let keys = active.removeValue(forKey: id) else { return }
        for key in keys.reversed() {
            let remaining = counts[key, default: 1] - 1
            if remaining == 0 { counts.removeValue(forKey: key); send(key, false) }
            else { counts[key] = remaining }
        }
    }

    func releaseAll() { for id in Array(active.keys) { release(id) } }
}
