import Cocoa
import IOKit.hid

enum ScrollState {
    static var inverted = false
}

let scrollFields: [CGEventField] = [
    .scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2,
    .scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2,
    .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2,
]

func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let delegate = userInfo.map({ Unmanaged<AppDelegate>.fromOpaque($0).takeUnretainedValue() }) else {
        return Unmanaged.passUnretained(event)
    }
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = delegate.eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    guard type == .scrollWheel, ScrollState.inverted else {
        return Unmanaged.passUnretained(event)
    }
    let originals = scrollFields.map { event.getDoubleValueField($0) }
    for (field, value) in zip(scrollFields, originals) {
        event.setDoubleValueField(field, value: -value)
    }
    return Unmanaged.passUnretained(event)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.action = #selector(handleClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        tryInstallTap()
    }

    func tryInstallTap() {
        if installTap() { return }
        statusItem.button?.title = "⇅?"
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            if self.installTap() { timer.invalidate() }
        }
    }

    func installTap() -> Bool {
        guard eventTap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: eventTapCallback, userInfo: selfPtr
        ) else { return false }
        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        updateTitle()
        return true
    }

    @objc func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else if eventTap != nil {
            ScrollState.inverted.toggle()
            updateTitle()
        }
    }

    func updateTitle() {
        statusItem.button?.title = ScrollState.inverted ? "↓" : "↑"
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
