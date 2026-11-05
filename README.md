# <p align="center">![icon_transparent.png](OpenParsec/Assets.xcassets/IconTransparent.imageset/icon_transparent.png) ![OpenParsec](OpenParsec/Assets.xcassets/LogoShadow.imageset/logo_shadow.png)</p>

OpenParsec is a simple, open-source Parsec client for iOS/iPadOS written in Swift using the SwiftUI framework and the Parsec SDK.

This project is still a major WIP, so apologies for the currently lackluster documentation. I'm also very new to both Swift and SwiftUI so I'm sure there are many places for improvement.

Before building, make sure you have the Parsec SDK framework symlinked or copied to the `Frameworks` folder. Builds were tested on Xcode Version 12.5.

## Downloads
<a href="https://stikstore.app/altdirect/?url=https://github.com/hugeBlack/OpenParsec/releases/download/nightly/altstore.json" target="_blank">
   <img src="https://raw.githubusercontent.com/StikStore/altdirect/refs/heads/main/assets/png/AltSource_Blue.png" alt="Add AltSource" width="200">
</a>
<a href="https://github.com/hugeBlack/OpenParsec/releases/download/nightly/OpenParsec.ipa" target="_blank">
   <img src="https://raw.githubusercontent.com/StikStore/altdirect/refs/heads/main/assets/png/Download_Blue.png" alt="Download .ipa" width="200">
</a>

## Touch Control
You can set the touch mode you want to use in settings. Touchpad mode and direct touch mode are supported.

When streaming, you can tap with 3 fingers to bring up the on-screen keyboard.

You can toggle if you want to use 2 fingers to scroll or zoom in the overlay menu.

## Mouse & keyboard
USB mouse & keyboard are supported. 

## Game Controllers
When streaming, press any trigger button in your controller and parsec will recognize it. Make sure to configure the host properly (install virtual USB driver etc.) before using game controllers.

## Lag / Low Bitrate Issue
If you encounter lags from nowhere or your bitrate hardly goes over 10 Mbps, download Steam Link and do a network test. If you see constant lag spike in the graph, then it's a problem with Apple and there's little we can do to solve this problem. See [here](https://github.com/moonlight-stream/moonlight-ios/issues/627) for more disscussion. 

If you can't change your wireless router's channel to 149 like me, my personal experience is that you can try to power off the device you are using to stream as well as any nearby Apple devices, especially Mac, then only power on the device you are using to stream and do the aforementioned network test again. You can turn on other devices if the lag spike is gone and it may sustain for couple hours or days.
## Custom glass keypad

While streaming, open the Parsec menu and choose **Show Keypad**. The default
layout includes WASD, Space and a tap-only Alt + Tab shortcut.
Tap the **square-and-pencil icon** below the Parsec icon to open the keypad
directly in Edit mode. Choose **Done** in the keypad toolbar when finished.

- Choose **Edit** in the floating keypad toolbar to move buttons. Drag any button
  anywhere in the stream area; positions are saved and adapt to rotation.
- Use **+** to add a button, or **Edit** beneath an existing button to change its
  label, keys or behavior. Select several keys to create a chord. Save applies
  your changes; Delete removes a button.
- **Hold** keeps the chord down until you lift your finger. **Toggle** latches it
  until the next tap. **Tap only** immediately presses and releases once, even
  when your finger stays on the button, preventing press-and-hold repeat.
- The editor's **Keypad opacity** slider adjusts all buttons from 15% to 100%.
- Choose **Done** to play. Multiple fingers can hold separate buttons. The hand
  icon releases all keypad keys, and **×** hides the keypad. Reopen it from the
  Parsec menu. Editing, hiding, interruption and connection cleanup release keys.

The Liquid Glass-inspired treatment uses system blur, rounded surfaces and
highlighted borders on iOS 14 and later, with an opaque Reduce Transparency
fallback. It does not require iOS 26. Layout and opacity are saved on this device.
Tap-only controls send simultaneous chords, not timed macros. Host OS shortcut
behavior and permissions still apply. Avoid pressing the same key on both the
physical keyboard and the custom keypad at once: their ownership is independent.

### Validation

Run `Tests/run-keypad-tests.sh` on a machine with Swift installed. It tests hold,
tap-only, toggle, modifier ordering, shared keys, cancellation, release cleanup
and saved-button round trips. Build the `OpenParsec` scheme in Xcode with the
Parsec SDK submodule initialized, as described above.

Device checks: hold W and Space with two fingers; latch Shift and release it;
hold a tap-only Alt + Tab without repeating; drag buttons in Edit mode; rotate;
relaunch to check persistence; background or disconnect with keys held; and
verify the host receives key releases. Check Reduce Transparency and VoiceOver.
