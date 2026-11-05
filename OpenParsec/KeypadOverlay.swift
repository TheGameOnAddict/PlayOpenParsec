import SwiftUI
import UIKit

final class KeypadStore: ObservableObject {
    @Published var buttons: [KeypadButton] { didSet { save() } }
    @Published var opacity: Double { didSet { save() } }
    @Published var revision = 0
    let input = KeypadInput { CParsec.sendKeyboardMessage(keyCode: $0, pressed: $1) }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "keypad.buttons.v1"),
           let saved = try? JSONDecoder().decode([KeypadButton].self, from: data),
           saved.allSatisfy({ $0.x.isFinite && $0.y.isFinite && !$0.keys.isEmpty }) {
            buttons = saved
        } else {
            buttons = [
                KeypadButton(label: "W", keys: [26], x: 0.16, y: 0.62),
                KeypadButton(label: "A", keys: [4], x: 0.07, y: 0.79),
                KeypadButton(label: "S", keys: [22], x: 0.16, y: 0.79),
                KeypadButton(label: "D", keys: [7], x: 0.25, y: 0.79),
                KeypadButton(label: "Space", keys: [44], x: 0.88, y: 0.79),
                KeypadButton(label: "Alt + Tab", keys: [226, 43], mode: .tap, x: 0.85, y: 0.16)
            ]
        }
        let stored = defaults.object(forKey: "keypad.opacity.v1") as? Double ?? 0.8
        opacity = stored.isFinite ? min(1, max(0.15, stored)) : 0.8
    }

    func save() {
        if let data = try? JSONEncoder().encode(buttons) {
            UserDefaults.standard.set(data, forKey: "keypad.buttons.v1")
        }
        UserDefaults.standard.set(opacity, forKey: "keypad.opacity.v1")
    }

    func releaseAll() { input.releaseAll(); revision += 1 }
    func down(_ button: KeypadButton) { input.down(button); revision += 1 }
    func up(_ button: KeypadButton) { input.up(button); revision += 1 }
}

// UIKit tracking provides immediate down/up, cancellation and independent fingers.
private final class KeypadTouchControl: UIControl {
    var down: () -> Void = {}
    var up: () -> Void = {}
    var cancel: () -> Void = {}
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { down(); return true }
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) { up() }
    override func cancelTracking(with event: UIEvent?) { cancel() }
    override func accessibilityActivate() -> Bool { down(); up(); return true }
}

private struct KeypadTouchSurface: UIViewRepresentable {
    let label: String
    let down: () -> Void
    let up: () -> Void
    let cancel: () -> Void
    func makeUIView(context: Context) -> KeypadTouchControl {
        let control = KeypadTouchControl()
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        control.isExclusiveTouch = false
        return control
    }
    func updateUIView(_ control: KeypadTouchControl, context: Context) {
        control.accessibilityLabel = label
        control.down = down; control.up = up; control.cancel = cancel
    }
}

private struct KeypadGlass: UIViewRepresentable {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = reduceTransparency ? nil : UIBlurEffect(style: .systemUltraThinMaterialDark)
        view.backgroundColor = reduceTransparency ? .darkGray : .clear
    }
}

private struct KeypadGlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KeypadGlass())
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LinearGradient(gradient: Gradient(colors: [.white.opacity(0.65), .white.opacity(0.08), .white.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 12, y: 5)
    }
}

struct KeypadOverlay: View {
    @ObservedObject var store: KeypadStore
    @Binding var visible: Bool
    @State private var editing = false
    @State private var selected: KeypadButton?
    @State private var dragOrigins: [UUID: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                ForEach(store.buttons) { button in
                    key(button, size: geometry.size)
                }
                HStack(spacing: 16) {
                    Button(editing ? "Done" : "Edit") {
                        store.releaseAll(); editing.toggle()
                    }
                    if editing {
                        Button(action: { selected = KeypadButton(label: "Space", keys: [44]) }) {
                            Image(systemName: "plus")
                        }.accessibilityLabel("Add keypad button")
                    }
                    Button(action: { store.releaseAll() }) {
                        Image(systemName: "hand.raised")
                    }.accessibilityLabel("Release all keypad keys")
                    Button(action: { store.releaseAll(); visible = false }) {
                        Image(systemName: "xmark")
                    }.accessibilityLabel("Hide keypad")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white).padding(16)
                .modifier(KeypadGlassStyle())
                .padding(.top, 26).padding(.trailing, 16)
            }
        }
        .sheet(item: $selected) { button in
            KeypadButtonEditor(button: button, opacity: $store.opacity, save: { updated in
                store.releaseAll()
                if let index = store.buttons.firstIndex(where: { $0.id == updated.id }) {
                    store.buttons[index] = updated
                } else { store.buttons.append(updated) }
                selected = nil
            }, delete: {
                store.releaseAll()
                store.buttons.removeAll { $0.id == button.id }
                selected = nil
            })
        }
        .onDisappear { store.releaseAll() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in store.releaseAll() }
    }

    private func key(_ button: KeypadButton, size: CGSize) -> some View {
        let width = min(CGFloat(104), max(44, size.width))
        let height: CGFloat = 64
        let travelX = max(1, size.width - width - 16)
        let travelY = max(1, size.height - height - 16)
        let active = store.input.active[button.id] != nil
        return VStack(spacing: 3) {
            Text(button.label).font(.system(size: 16, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.5)
            Text(editing ? "Drag · Edit below" : button.mode.rawValue)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.white).frame(width: width, height: height)
        .background(active ? Color(red: 0, green: 0.75, blue: 0.85).opacity(0.55) : Color.clear)
        .modifier(KeypadGlassStyle())
        .overlay(Group {
            if editing {
                VStack {
                    Spacer()
                    Button("Edit") { selected = button }
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                }
            } else {
                KeypadTouchSurface(label: "\(button.label), \(button.mode.rawValue)\(active ? ", active" : "")",
                    down: { store.down(button) }, up: { store.up(button) }, cancel: {
                        store.input.release(button.id); store.revision += 1
                    })
            }
        })
        .opacity(editing ? 1 : store.opacity)
        .position(x: 8 + width / 2 + CGFloat(min(1, max(0, button.x))) * travelX,
                  y: 8 + height / 2 + CGFloat(min(1, max(0, button.y))) * travelY)
        .simultaneousGesture(DragGesture(minimumDistance: 5).onChanged { value in
            guard editing, let index = store.buttons.firstIndex(where: { $0.id == button.id }) else { return }
            if dragOrigins[button.id] == nil { dragOrigins[button.id] = CGPoint(x: button.x, y: button.y) }
            guard let origin = dragOrigins[button.id] else { return }
            store.buttons[index].x = Double(min(1, max(0, origin.x + value.translation.width / travelX)))
            store.buttons[index].y = Double(min(1, max(0, origin.y + value.translation.height / travelY)))
        }.onEnded { _ in dragOrigins.removeValue(forKey: button.id) })
    }
}

private struct KeypadButtonEditor: View {
    @Environment(\.presentationMode) var presentation
    @State var button: KeypadButton
    @Binding var opacity: Double
    let save: (KeypadButton) -> Void
    let delete: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Button")) {
                    TextField("Label", text: $button.label)
                    Picker("Press behavior", selection: $button.mode) {
                        ForEach(KeypadMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Text("Hold: down until lifted. Toggle: tap to latch, tap again to release. Tap only: one press, with no holding or repeat.")
                        .font(.caption)
                }
                Section(header: Text("Keypad opacity")) {
                    Slider(value: $opacity, in: 0.15...1)
                    Text("\(Int(opacity * 100))% · Applies to all keypad buttons")
                }
                Section(header: Text("Key combination"), footer: Text("Select one key or a chord such as Alt + Tab. Modifiers press first and release last.")) {
                    Text(button.keys.map { KeypadKeys.name($0) }.joined(separator: " + "))
                    ForEach(KeypadKeys.all, id: \.code) { key in
                        Button(action: {
                            if button.keys.contains(key.code) { button.keys.removeAll { $0 == key.code } }
                            else { button.keys.append(key.code) }
                        }) {
                            HStack {
                                Text(key.name)
                                Spacer()
                                if button.keys.contains(key.code) { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                Section { Button("Delete button", action: delete).foregroundColor(.red) }
            }
            .navigationTitle("Keypad button")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentation.wrappedValue.dismiss() },
                trailing: Button("Save") { save(button) }
                    .disabled(button.keys.isEmpty || button.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
