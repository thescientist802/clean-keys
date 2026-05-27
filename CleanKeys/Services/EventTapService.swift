import Foundation
import CoreGraphics
import Carbon

class EventTapService {

    fileprivate let stateMachine: StateMachine
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    private var activeKeyCodes: Set<CGKeyCode> = []
    private let patternDetectionWindow: TimeInterval = 0.5
    private var lastKeyDownTimes: [CGKeyCode: Date] = [:]

    init(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
        setupStateObserver()
    }

    func start() {
        guard !isRunning else { return }

        activeKeyCodes.removeAll()
        lastKeyDownTimes.removeAll()

        let eventMask = CGEventMask(eventTypes: [.keyDown, .keyUp, .flagsChanged])
        guard let eventTap = CGEvent.tapCreate(
            tap: .cSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }

        tap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, CFRunLoopMode.commonModes)
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }

        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, CFRunLoopMode.commonModes)
        }

        tap = nil
        runLoopSource = nil
        isRunning = false
        activeKeyCodes.removeAll()
        lastKeyDownTimes.removeAll()
    }

    func reinstall() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
    }

    @discardableResult
    func isFailSafeDetected(event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let now = Date()

        let escapeKey = CGKeyCode(kVK_Escape)
        let ctrlKey = CGKeyCode(kVK_Control)
        let shiftKey = CGKeyCode(kVK_Shift)

        if event.type == .keyDown {
            activeKeyCodes.insert(keyCode)
            lastKeyDownTimes[keyCode] = now
        } else if event.type == .keyUp {
            activeKeyCodes.remove(keyCode)
            lastKeyDownTimes.removeValue(forKey: keyCode)
        } else if event.type == .flagsChanged {
            if event.flags.contains(.maskControl) {
                activeKeyCodes.insert(ctrlKey)
                lastKeyDownTimes[ctrlKey] = now
            } else {
                activeKeyCodes.remove(ctrlKey)
                lastKeyDownTimes.removeValue(forKey: ctrlKey)
            }

            if event.flags.contains(.maskShift) {
                activeKeyCodes.insert(shiftKey)
                lastKeyDownTimes[shiftKey] = now
            } else {
                activeKeyCodes.remove(shiftKey)
                lastKeyDownTimes.removeValue(forKey: shiftKey)
            }
        }

        let hasEscape = activeKeyCodes.contains(escapeKey) &&
            (now.timeIntervalSince(lastKeyDownTimes[escapeKey] ?? Date.distantPast) <= patternDetectionWindow)
        let hasCtrl = activeKeyCodes.contains(ctrlKey) &&
            (now.timeIntervalSince(lastKeyDownTimes[ctrlKey] ?? Date.distantPast) <= patternDetectionWindow)
        let hasShift = activeKeyCodes.contains(shiftKey) &&
            (now.timeIntervalSince(lastKeyDownTimes[shiftKey] ?? Date.distantPast) <= patternDetectionWindow)

        return hasEscape && hasCtrl && hasShift
    }

    private func setupStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStateChange(_:)),
            name: .stateMachineDidChange,
            object: nil
        )
    }

    @objc private func handleStateChange(_ notification: Notification) {
        guard let newState = notification.userInfo?["newState"] as? AppState else { return }

        switch newState {
        case .cleaning:
            start()
        case .exiting, .normal:
            stop()
        default:
            break
        }
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Event Tap Callback

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer
) -> Unmanaged<CGEvent>? {

    let service = Unmanaged<EventTapService>.fromOpaque(UnsafeRawPointer(userInfo)).takeUnretainedValue()

    guard type == .keyDown || type == .keyUp || type == .flagsChanged else { return Unmanaged.passUnretained(event) }

    if service.stateMachine.state == .cleaning {
        if Settings.shared.hardwareFailSafeEnabled, service.isFailSafeDetected(event: event) {
            service.stateMachine.transition(to: .exiting)
            return nil
        }
        return nil
    }

    return Unmanaged.passUnretained(event)
}

// MARK: - CGEventMask Extension

extension CGEventMask {
    init(eventTypes types: [CGEventType]) {
        var value: CGEventMask = 0
        for eventType in types {
            value |= CGEventMask(1 << eventType.rawValue)
        }
        self.init(value)
    }
}
