import Foundation
import CoreGraphics
import Carbon

/// Installs a session event tap on a dedicated run loop thread (required for reliable CGEvent taps).
final class EventTapService {

    fileprivate let stateMachine: StateMachine

    private var tapThread: Thread?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let stateLock = NSLock()
    private var isRunning = false
    private var shouldStopTapLoop = false
    private var tapThreadFinished = DispatchSemaphore(value: 0)

    private var activeKeyCodes: Set<CGKeyCode> = []
    private let patternDetectionWindow: TimeInterval = 0.5
    private var lastKeyDownTimes: [CGKeyCode: Date] = [:]

    init(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
        setupStateObserver()
    }

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }

        let ready = DispatchSemaphore(value: 0)
        var installSucceeded = false

        let thread = Thread { [weak self] in
            guard let self else {
                ready.signal()
                return
            }
            installSucceeded = self.installTapOnCurrentRunLoop()
            ready.signal()
            guard installSucceeded else { return }

            while !self.shouldStopTapLoop {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
            }
            self.uninstallTapFromCurrentRunLoop()
            self.tapThreadFinished.signal()
        }
        thread.name = "com.scientist.CleanKeys.EventTap"
        thread.qualityOfService = .userInteractive
        tapThread = thread
        thread.start()

        ready.wait()
        if installSucceeded {
            stateLock.lock()
            isRunning = true
            shouldStopTapLoop = false
            stateLock.unlock()
        } else {
            tapThread = nil
            shouldStopTapLoop = true
        }
        return installSucceeded
    }

    func stop() {
        stateLock.lock()
        let wasRunning = isRunning
        isRunning = false
        shouldStopTapLoop = true
        stateLock.unlock()

        guard wasRunning else {
            tapThread = nil
            return
        }

        _ = tapThreadFinished.wait(timeout: .now() + 2)
        tapThreadFinished = DispatchSemaphore(value: 0)
        tapThread = nil

        activeKeyCodes.removeAll()
        lastKeyDownTimes.removeAll()
    }

    func reinstall() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            _ = self?.start()
        }
    }

    // MARK: - Tap installation

    private func installTapOnCurrentRunLoop() -> Bool {
        shouldStopTapLoop = false

        let eventMask = CGEventMask(eventTypes: [
            .keyDown, .keyUp, .flagsChanged, SystemKeyEventFilter.systemDefinedEventType
        ])

        let configurations: [(CGEventTapLocation, CGEventTapPlacement)] = [
            (.cgSessionEventTap, .headInsertEventTap),
            (.cgAnnotatedSessionEventTap, .headInsertEventTap),
        ]

        for (location, placement) in configurations {
            guard let eventTap = CGEvent.tapCreate(
                tap: location,
                place: placement,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: eventTapCallback,
                userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            ) else {
                continue
            }

            tap = eventTap
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return true
        }

        fputs("CleanKeys: Failed to create event tap (check Input Monitoring for this app build)\n", stderr)
        return false
    }

    private func uninstallTapFromCurrentRunLoop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    // MARK: - Fail-safe pattern

    @discardableResult
    func isFailSafeDetected(event: CGEvent) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }

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
            (now.timeIntervalSince(lastKeyDownTimes[escapeKey] ?? .distantPast) <= patternDetectionWindow)
        let hasCtrl = activeKeyCodes.contains(ctrlKey) &&
            (now.timeIntervalSince(lastKeyDownTimes[ctrlKey] ?? .distantPast) <= patternDetectionWindow)
        let hasShift = activeKeyCodes.contains(shiftKey) &&
            (now.timeIntervalSince(lastKeyDownTimes[shiftKey] ?? .distantPast) <= patternDetectionWindow)

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
        guard (notification.object as? StateMachine) === stateMachine else { return }
        guard let newState = notification.userInfo?["newState"] as? AppState else { return }

        switch newState {
        case .cleaning:
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                if !self.start() {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .eventTapFailed, object: self)
                    }
                }
            }
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
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo {
            let service = Unmanaged<EventTapService>.fromOpaque(userInfo).takeUnretainedValue()
            if let tap = service.tapForReenable() {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        return Unmanaged.passUnretained(event)
    }

    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let service = Unmanaged<EventTapService>.fromOpaque(userInfo).takeUnretainedValue()

    let systemDefined = SystemKeyEventFilter.systemDefinedEventType
    guard type == .keyDown || type == .keyUp || type == .flagsChanged || type == systemDefined else {
        return Unmanaged.passUnretained(event)
    }

    if service.stateMachine.state == .cleaning {
        if type == systemDefined, SystemKeyEventFilter.isHardwareControlEvent(event) {
            return nil
        }

        if Settings.shared.hardwareFailSafeEnabled, service.isFailSafeDetected(event: event) {
            DispatchQueue.main.async {
                service.stateMachine.transition(to: .exiting)
            }
            return nil
        }
        return nil
    }

    return Unmanaged.passUnretained(event)
}

// MARK: - Tap recovery

extension EventTapService {
    fileprivate func tapForReenable() -> CFMachPort? {
        tap
    }
}

// MARK: - CGEventMask Extension

extension CGEventMask {
    init(eventTypes types: [CGEventType]) {
        var mask: UInt64 = 0
        for eventType in types {
            mask |= 1 << eventType.rawValue
        }
        self = CGEventMask(mask)
    }
}
