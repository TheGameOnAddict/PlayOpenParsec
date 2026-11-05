import Foundation

struct Event: Equatable { let key: UInt32; let pressed: Bool }
var events: [Event] = []
let input = KeypadInput { events.append(Event(key: $0, pressed: $1)) }
func expect(_ expected: [Event], _ message: String) {
    precondition(events == expected, "\(message): \(events)")
    events.removeAll()
}
func e(_ key: UInt32, _ down: Bool) -> Event { Event(key: key, pressed: down) }

let hold = KeypadButton(label: "W", keys: [26])
input.down(hold); input.down(hold); input.up(hold)
expect([e(26, true), e(26, false)], "hold and duplicate touch")
let tap = KeypadButton(label: "Alt Tab", keys: [43, 226, 43], mode: .tap)
input.down(tap); input.up(tap)
expect([e(226, true), e(43, true), e(43, false), e(226, false)], "tap chord order and deduplication")
let toggle = KeypadButton(label: "Shift", keys: [225], mode: .toggle)
input.down(toggle); input.up(toggle)
expect([e(225, true)], "toggle remains down")
input.down(toggle); input.up(toggle)
expect([e(225, false)], "toggle releases on second tap")
let first = KeypadButton(label: "Ctrl A", keys: [224, 4])
let second = KeypadButton(label: "Ctrl C", keys: [224, 6])
input.down(first); input.down(second); input.up(first); input.up(second)
expect([e(224, true), e(4, true), e(6, true), e(4, false), e(6, false), e(224, false)], "shared modifier ownership")
input.down(toggle); input.releaseAll(); input.releaseAll()
expect([e(225, true), e(225, false)], "cleanup is idempotent")
input.down(hold); input.release(hold.id); input.up(hold)
expect([e(26, true), e(26, false)], "cancel then touch up")
input.down(toggle); input.releaseAll(); input.down(toggle)
expect([e(225, true), e(225, false), e(225, true)], "toggle can restart after cleanup")
input.releaseAll()
let original = KeypadButton(label: "Alt Tab", keys: [226, 43], mode: .tap, x: 0.2, y: 0.8)
let decoded = try JSONDecoder().decode(KeypadButton.self, from: JSONEncoder().encode(original))
precondition(decoded.id == original.id && decoded.keys == original.keys && decoded.mode == .tap && decoded.x == 0.2 && decoded.y == 0.8)
print("Keypad input and persistence tests passed")
