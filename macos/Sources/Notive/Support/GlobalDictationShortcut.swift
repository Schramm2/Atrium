import AppKit
import ApplicationServices
import NotiveCore

@MainActor
final class GlobalDictationShortcut {
    static let shared = GlobalDictationShortcut()

    private weak var store: AppStore?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var optionSpaceActive = false
    private var optionSpaceStartTask: Task<Void, Never>?
    private var toggleTask: Task<Void, Never>?

    private init() {}

    func install(store: AppStore) {
        self.store = store
        installOptionSpaceTap()

        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.keyCode == 2,
                      event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                        .contains([.command, .shift]),
                      !event.isARepeat else { return }
                Task { @MainActor in self?.handle(event) }
            }
        }
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                MainActor.assumeIsolated {
                    self?.handle(event)
                }
                return event
            }
        }
    }

    func refreshAccessibility() {
        guard eventTap == nil else { return }
        installOptionSpaceTap()
    }

    private func installOptionSpaceTap() {
        guard eventTap == nil, AXIsProcessTrusted() else { return }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let owner = Unmanaged<GlobalDictationShortcut>
                .fromOpaque(userInfo)
                .takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                MainActor.assumeIsolated {
                    if let eventTap = owner.eventTap {
                        CGEvent.tapEnable(tap: eventTap, enable: true)
                    }
                }
                return Unmanaged.passUnretained(event)
            }
            let handled = MainActor.assumeIsolated {
                owner.handleOptionSpace(type: type, event: event)
            }
            return handled ? nil : Unmanaged.passUnretained(event)
        }
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        self.eventTap = eventTap
        eventTapSource = source
    }

    private func handleOptionSpace(type: CGEventType, event: CGEvent) -> Bool {
        guard event.getIntegerValueField(.keyboardEventKeycode) == 49 else { return false }
        if type == .keyDown,
           event.flags.contains(.maskAlternate),
           event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
            guard selectedShortcut == "Option + Space" else { return false }
            guard !optionSpaceActive, let store else { return true }
            optionSpaceActive = true
            optionSpaceStartTask?.cancel()
            optionSpaceStartTask = Task { await store.startDictation() }
            return true
        }
        if type == .keyUp, optionSpaceActive {
            optionSpaceActive = false
            guard let store else { return true }
            let startTask = optionSpaceStartTask
            optionSpaceStartTask = nil
            startTask?.cancel()
            Task {
                await startTask?.value
                if store.isDictating {
                    await store.stopDictation()
                    pasteIfPermitted(store.dictationText)
                }
            }
            return true
        }
        return false
    }

    private func handle(_ event: NSEvent) {
        guard selectedShortcut == "Command + Shift + D",
              event.keyCode == 2,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                .contains([.command, .shift]),
              !event.isARepeat,
              let store else { return }
        let previousTask = toggleTask
        toggleTask = Task {
            await previousTask?.value
            if store.isDictating {
                await store.stopDictation()
                pasteIfPermitted(store.dictationText)
            } else {
                await store.startDictation()
            }
        }
    }

    private var selectedShortcut: String {
        UserDefaults.standard.string(forKey: "notive.dictation.shortcut") ?? "Option + Space"
    }

    private func pasteIfPermitted(_ text: String) {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        guard AXIsProcessTrusted() else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
