import SwiftUI
import UserNotifications
import AudioToolbox
import AlarmKit
import AppIntents
import ActivityKit
import AVFoundation
import EventKit
import MediaPlayer

private func powAILocalized(_ key: String) -> String {
    AppLanguageManager.shared.localizedString(forKey: key)
}

private func powAILocalizedFormat(_ key: String, _ args: CVarArg...) -> String {
    String(format: powAILocalized(key), locale: AppLanguageManager.shared.locale, arguments: args)
}

private enum PowAI {
    static let base = Color(hex: "#0D0D0F")
    static let surface = Color(hex: "#16161C")
    static let card = Color(hex: "#1E1E27")
    static let orange = Color(hex: "#FF5E1A")
    static let amber = Color(hex: "#FFB347")
    static let slate = Color(hex: "#8B8FA8")
    static let slateLight = Color(hex: "#B2B6CC")
    static let green = Color(hex: "#34D399")
    static let cyan = Color(hex: "#22D3EE")

    static let orangeGlow = LinearGradient(
        colors: [orange, amber.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

private struct PowAICard<Content: View>: View {
    var accentColor: Color = PowAI.orange
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(PowAI.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.25), accentColor.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            )
    }
}

private struct PowAIChip: View {
    let label: String
    let icon: String
    var color: Color = PowAI.orange

    var body: some View {
        Label(label, systemImage: icon)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 0.5))
    }
}

private struct PowAISectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.5)
            .foregroundStyle(PowAI.orange)
    }
}

private struct PowAIInputField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PowAI.slate.opacity(0.2), lineWidth: 1)
            )
    }
}

private struct MissionTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PowAI.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(PowAI.orange.opacity(0.3), lineWidth: 1.5)
                    )
            )
    }
}

extension Notification.Name {
    static let powAIAlarmNotificationTapped = Notification.Name("powAIAlarmNotificationTapped")
}

struct PowAIAlarmOpenIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open PowAI Alarm"
    static var supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        guard !alarmID.isEmpty else { return .result() }
        await MainActor.run {
            NotificationCenter.default.post(name: .powAIAlarmNotificationTapped, object: alarmID)
        }
        return .result()
    }
}

struct AlarmSoundOption: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let fileName: String?
    private static let softAwakeningFileName = "powai_alarm_soft_awake.wav"

    static let options: [AlarmSoundOption] = [
        AlarmSoundOption(id: "default", title: "Default", systemImage: "bell.fill", fileName: nil),
        AlarmSoundOption(id: "beacon", title: "Beacon", systemImage: "dot.radiowaves.left.and.right", fileName: "powai_alarm_beacon.wav"),
        AlarmSoundOption(id: "radar", title: "Radar", systemImage: "antenna.radiowaves.left.and.right", fileName: "powai_alarm_radar.wav"),
        AlarmSoundOption(id: "siren", title: "Siren", systemImage: "waveform.path", fileName: "powai_alarm_siren.wav"),
        AlarmSoundOption(id: "pulse", title: "Pulse", systemImage: "waveform", fileName: "powai_alarm_pulse.wav"),
        AlarmSoundOption(id: "klaxon", title: "Klaxon", systemImage: "exclamationmark.triangle.fill", fileName: "powai_alarm_klaxon.wav"),
        AlarmSoundOption(id: "air_raid", title: "Air Raid", systemImage: "tornado", fileName: "powai_alarm_air_raid.wav"),
        AlarmSoundOption(id: "panic_buzzer", title: "Panic Buzzer", systemImage: "alarm.waves.left.and.right.fill", fileName: "powai_alarm_panic_buzzer.wav"),
        AlarmSoundOption(id: "wake_cannon", title: "Wake Cannon", systemImage: "speaker.wave.3.fill", fileName: "powai_alarm_wake_cannon.wav"),
        AlarmSoundOption(id: "rekordbox_siren", title: "RB Siren", systemImage: "megaphone.fill", fileName: "powai_rekordbox_siren.wav"),
        AlarmSoundOption(id: "rekordbox_horn", title: "RB Horn", systemImage: "speaker.wave.3.fill", fileName: "powai_rekordbox_horn.wav"),
        AlarmSoundOption(id: "rekordbox_noise", title: "RB Noise", systemImage: "waveform.badge.magnifyingglass", fileName: "powai_rekordbox_noise.wav"),
        AlarmSoundOption(id: "rekordbox_sinewave", title: "RB Sine", systemImage: "alternatingcurrent", fileName: "powai_rekordbox_sinewave.wav")
    ]

    static func option(for id: String?) -> AlarmSoundOption {
        let normalized = id?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "default"
        return options.first { $0.id == normalized } ?? options[0]
    }

    func notificationSound(softAwakening: Bool) -> UNNotificationSound {
        guard let fileName = lockScreenFileName(softAwakening: softAwakening) else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }

    func alarmKitSound(softAwakening: Bool) -> AlertConfiguration.AlertSound {
        guard let fileName = lockScreenFileName(softAwakening: softAwakening) else { return .default }
        return .named(fileName)
    }

    private func lockScreenFileName(softAwakening: Bool) -> String? {
        if softAwakening {
            return Self.softAwakeningFileName
        }
        return fileName
    }

    var bundleURL: URL? {
        guard let fileName else { return nil }
        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return Bundle.main.url(forResource: parts[0], withExtension: parts[1])
    }

    var localizedTitle: String {
        powAILocalized(title)
    }
}

enum AlarmSoundPreviewer {
    private static var player: AVAudioPlayer?

    static func play(_ sound: AlarmSoundOption) {
        player?.stop()
        player = nil

        guard let url = sound.bundleURL else {
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = 1
            audioPlayer.numberOfLoops = 0
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
        } catch {
            print("Alarm sound preview failed: \(error)")
            AudioServicesPlaySystemSound(1005)
        }
    }
}

struct AlarmItem: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var hour: Int
    var minute: Int
    var repeatDays: [Int]
    var challengeType: String
    var challengeTypes: [String]?
    var difficulty: String
    var barcodeValue: String?
    var typingPhrase: String?
    var wakeCheckMinutes: Int?
    var alarmSound: String?
    var softAwakeningEnabled: Bool?
    var hideSnoozeButton: Bool?
    var isEnabled: Bool

    var soundOption: AlarmSoundOption {
        AlarmSoundOption.option(for: alarmSound)
    }

    var soundText: String {
        soundOption.localizedTitle
    }

    var usesSoftAwakening: Bool {
        softAwakeningEnabled == true
    }

    var hidesSnoozeButton: Bool {
        hideSnoozeButton == true
    }

    var missions: [String] {
        let configured = challengeTypes?.filter { !($0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } ?? []
        return configured.isEmpty ? [challengeType] : configured
    }

    var missionText: String {
        missions.map { mission in
            switch mission {
            case "typing": return powAILocalized("Typing")
            case "memory": return powAILocalized("Memory")
            case "barcode": return "QR/Barcode"
            default: return powAILocalized("Math")
            }
        }
        .joined(separator: " + ")
    }

    var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var repeatText: String {
        guard !repeatDays.isEmpty else { return powAILocalized("Once") }
        let symbols = Calendar.current.shortWeekdaySymbols
        return repeatDays
            .sorted()
            .compactMap { day in symbols.indices.contains(day - 1) ? symbols[day - 1] : nil }
            .joined(separator: ", ")
    }
}

struct AlarmSaveRequest: Encodable {
    var title: String?
    var hour: Int
    var minute: Int
    var repeatDays: [Int]
    var challengeType: String?
    var challengeTypes: [String]?
    var difficulty: String?
    var barcodeValue: String?
    var typingPhrase: String?
    var wakeCheckMinutes: Int?
    var alarmSound: String?
    var softAwakeningEnabled: Bool?
    var hideSnoozeButton: Bool?
    var isEnabled: Bool?
}

struct MathChallenge {
    let prompt: String
    let answer: Int

    static func generate(difficulty: String) -> MathChallenge {
        switch difficulty.lowercased() {
        case "hard":
            let a = Int.random(in: 12...29)
            let b = Int.random(in: 8...19)
            let c = Int.random(in: 3...9)
            return MathChallenge(prompt: "\(a) x \(b) - \(c)", answer: (a * b) - c)
        case "easy":
            let a = Int.random(in: 3...18)
            let b = Int.random(in: 2...15)
            return MathChallenge(prompt: "\(a) + \(b)", answer: a + b)
        default:
            let a = Int.random(in: 8...25)
            let b = Int.random(in: 3...12)
            let c = Int.random(in: 2...10)
            return MathChallenge(prompt: "\(a) + \(b) x \(c)", answer: a + (b * c))
        }
    }
}

final class AlarmRuntime: ObservableObject {
    static let shared = AlarmRuntime()

    @Published var activeAlarm: AlarmItem?
    @Published var challenge = MathChallenge.generate(difficulty: "medium")
    private var soundTimer: Timer?
    private var vibrationTimer: Timer?
    private var volumeRampTimer: Timer?
    private var volumeGuardTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var volumeView: MPVolumeView?
    private weak var volumeSlider: UISlider?
    private var outputVolumeObservation: NSKeyValueObservation?
    private var notificationObservers: [NSObjectProtocol] = []
    private var alarmAudioSessionConfigured = false
    private var previousOutputVolume: Float?
    private let alarmOutputVolume: Float = 1
    private let volumeGuardInterval: TimeInterval = 0.25

    private init() {}

    func activate(_ alarm: AlarmItem) {
        activeAlarm = alarm
        challenge = MathChallenge.generate(difficulty: alarm.difficulty)
        startSound(for: alarm)
    }

    func dismissActiveAlarm() {
        stopSound()
        activeAlarm = nil
    }

    private func startSound(for alarm: AlarmItem) {
        stopSound()
        configureAlarmAudioSession()
        startVolumeGuard()
        forceAlarmVolumeRepeatedly()
        if playBundledSound(alarm.soundOption, softAwakening: alarm.usesSoftAwakening) == false {
            playSystemAlert()
            soundTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
                Self.playSystemAlert()
            }
        }

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func stopSound() {
        soundTimer?.invalidate()
        soundTimer = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        volumeRampTimer?.invalidate()
        volumeRampTimer = nil
        stopVolumeGuard()
        audioPlayer?.stop()
        audioPlayer = nil
        removeAlarmRecoveryObservers()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        alarmAudioSessionConfigured = false
    }

    private func playBundledSound(_ sound: AlarmSoundOption, softAwakening: Bool) -> Bool {
        guard let url = sound.bundleURL else { return false }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = softAwakening ? 0.12 : 1
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            if softAwakening {
                startVolumeRamp(for: player)
            }
            return true
        } catch {
            print("Alarm sound playback failed: \(error)")
            return false
        }
    }

    private func configureAlarmAudioSession() {
        guard !alarmAudioSessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            alarmAudioSessionConfigured = true
        } catch {
            print("Alarm audio session failed: \(error)")
        }
    }

    private func startVolumeGuard() {
        let session = AVAudioSession.sharedInstance()
        if previousOutputVolume == nil {
            previousOutputVolume = session.outputVolume
        }

        installAlarmRecoveryObserversIfNeeded()
        installVolumeViewIfNeeded()
        forceSystemVolume(alarmOutputVolume)

        outputVolumeObservation?.invalidate()
        outputVolumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, self.activeAlarm != nil else { return }
            let newVolume = change.newValue ?? 0
            if newVolume < self.alarmOutputVolume {
                DispatchQueue.main.async {
                    self.forceSystemVolume(self.alarmOutputVolume)
                    self.recoverPlaybackIfNeeded()
                }
            }
        }

        volumeGuardTimer?.invalidate()
        volumeGuardTimer = Timer.scheduledTimer(withTimeInterval: volumeGuardInterval, repeats: true) { [weak self] _ in
            guard let self, self.activeAlarm != nil else { return }
            self.forceSystemVolume(self.alarmOutputVolume)
            self.recoverPlaybackIfNeeded()
        }
    }

    private func stopVolumeGuard() {
        outputVolumeObservation?.invalidate()
        outputVolumeObservation = nil
        volumeGuardTimer?.invalidate()
        volumeGuardTimer = nil

        if let previousOutputVolume {
            forceSystemVolume(previousOutputVolume)
        }
        previousOutputVolume = nil

        volumeView?.removeFromSuperview()
        volumeView = nil
        volumeSlider = nil
    }

    private func forceAlarmVolumeRepeatedly() {
        for delay in stride(from: 0.0, through: 2.0, by: 0.2) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.activeAlarm != nil else { return }
                self.forceSystemVolume(self.alarmOutputVolume)
                self.recoverPlaybackIfNeeded()
            }
        }
    }

    private func installVolumeViewIfNeeded() {
        guard volumeView == nil else { return }
        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 120, height: 40))
        view.alpha = 0.01

        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) {
            window.addSubview(view)
        }

        volumeView = view
        volumeSlider = view.subviews.compactMap { $0 as? UISlider }.first
    }

    private func forceSystemVolume(_ volume: Float) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.installVolumeViewIfNeeded()
            if self.volumeSlider == nil {
                self.volumeSlider = self.volumeView?.subviews.compactMap { $0 as? UISlider }.first
            }
            let clamped = min(1, max(0, volume))
            self.volumeSlider?.setValue(clamped, animated: false)
            self.volumeSlider?.sendActions(for: .valueChanged)
            self.volumeSlider?.sendActions(for: .touchUpInside)
        }
    }

    private func recoverPlaybackIfNeeded() {
        if let audioPlayer {
            if !audioPlayer.isPlaying {
                audioPlayer.currentTime = 0
                audioPlayer.play()
            }
        } else if activeAlarm != nil {
            playSystemAlert()
        }
    }

    private func recoverAfterAudioSessionChange() {
        alarmAudioSessionConfigured = false
        configureAlarmAudioSession()
        forceAlarmVolumeRepeatedly()
    }

    private func installAlarmRecoveryObserversIfNeeded() {
        guard notificationObservers.isEmpty else { return }
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            AVAudioSession.interruptionNotification,
            AVAudioSession.routeChangeNotification,
            AVAudioSession.mediaServicesWereResetNotification,
            UIApplication.didBecomeActiveNotification,
            UIApplication.willEnterForegroundNotification
        ]

        notificationObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self, self.activeAlarm != nil else { return }
                self.recoverAfterAudioSessionChange()
            }
        }
    }

    private func removeAlarmRecoveryObservers() {
        let center = NotificationCenter.default
        notificationObservers.forEach { center.removeObserver($0) }
        notificationObservers.removeAll()
    }

    private func startVolumeRamp(for player: AVAudioPlayer) {
        let duration: TimeInterval = 90
        let startedAt = Date()
        volumeRampTimer?.invalidate()
        volumeRampTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self, weak player] timer in
            guard let self, let player else {
                timer.invalidate()
                return
            }
            let progress = min(1, Date().timeIntervalSince(startedAt) / duration)
            player.volume = Float(0.12 + (0.88 * progress))
            if progress >= 1 {
                timer.invalidate()
                self.volumeRampTimer = nil
            }
        }
    }

    private func playSystemAlert() {
        Self.playSystemAlert()
    }

    private static func playSystemAlert() {
        AudioServicesPlaySystemSound(1005)
    }
}

enum AlarmScheduler {
    private static let backupAlertOffsets: [TimeInterval] = [1, 10, 20, 30, 45, 60, 90, 120, 180, 300]
    private static let systemBackupAlarmOffsets: [TimeInterval] = [10, 30, 60, 120, 300]

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Alarm notification permission error: \(error)")
            }
        }
    }

    static func schedule(_ alarm: AlarmItem) {
        guard alarm.isEnabled else {
            cancel(alarm)
            return
        }

        cancelLocalNotifications(for: alarm)
        scheduleNotification(alarm)

        Task {
            cancelSystemAlarmsIfPresent(alarm)

            do {
                try await scheduleSystemAlarm(alarm)
            } catch {
                print("AlarmKit scheduling failed; notification backup is still scheduled: \(error)")
            }
        }
    }

    static func cancel(_ alarm: AlarmItem) {
        Task {
            cancelSystemAlarmsIfPresent(alarm)
        }

        cancelLocalNotifications(for: alarm)
    }

    static func markCompleted(_ alarm: AlarmItem) {
        cancelLocalNotifications(for: alarm)
        cancelBackupSystemAlarmsIfPresent(alarm)
        guard alarm.isEnabled, !alarm.repeatDays.isEmpty else { return }
        scheduleNotification(alarm, after: Date().addingTimeInterval(backupAlertOffsets.last ?? 300))
        Task {
            await scheduleBackupSystemAlarmsIfPossible(
                alarm,
                after: Date().addingTimeInterval(systemBackupAlarmOffsets.last ?? 300)
            )
        }
    }

    private static func cancelSystemAlarmsIfPresent(_ alarm: AlarmItem) {
        cancelSystemAlarmIfPresent(id: alarm.id)
        cancelBackupSystemAlarmsIfPresent(alarm)
    }

    private static func cancelBackupSystemAlarmsIfPresent(_ alarm: AlarmItem) {
        systemBackupAlarmOffsets.indices.forEach { index in
            cancelSystemAlarmIfPresent(id: backupSystemAlarmID(for: alarm, index: index))
        }
    }

    private static func cancelSystemAlarmIfPresent(id: UUID) {
        do {
            try AlarmManager.shared.cancel(id: id)
        } catch {
            // AlarmKit throws when the alarm is already gone; local notification cleanup still runs.
        }
    }

    private static func cancelLocalNotifications(for alarm: AlarmItem) {
        let currentBackupIDs = backupAlertOffsets.indices.map { notificationID(for: alarm, index: $0) }
        let legacyIDs = Array(0...7).map { "powai-alarm-\(alarm.id.uuidString)-\($0)" }
        let wakeCheckID = "powai-alarm-\(alarm.id.uuidString)-wake-check"
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: currentBackupIDs + legacyIDs + [wakeCheckID]
        )
    }

    static func scheduleWakeCheck(for alarm: AlarmItem) {
        guard let minutes = alarm.wakeCheckMinutes, minutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Still awake?"
        content.body = "Complete your alarm missions again to confirm."
        content.sound = alarm.soundOption.notificationSound(softAwakening: alarm.usesSoftAwakening)
        content.userInfo = ["alarmID": alarm.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "powai-alarm-\(alarm.id.uuidString)-wake-check",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule wake check: \(error)")
            }
        }
    }

    private static func scheduleNotification(_ alarm: AlarmItem, after date: Date = Date()) {
        requestPermission()

        let alarmDate = nextScheduledDate(for: alarm, after: date)
        for (index, offset) in backupAlertOffsets.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = alarm.title
            content.body = "Solve the challenge to turn this alarm off."
            content.sound = alarm.soundOption.notificationSound(softAwakening: alarm.usesSoftAwakening)
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["alarmID": alarm.id.uuidString]

            let interval = max(alarmDate.addingTimeInterval(offset).timeIntervalSinceNow, 1)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: notificationID(for: alarm, index: index),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Failed to schedule alarm: \(error)")
                }
            }
        }
    }

    private static func notificationID(for alarm: AlarmItem, index: Int) -> String {
        "powai-alarm-\(alarm.id.uuidString)-backup-\(index)"
    }

    private static func nextOneTimeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        if today > now {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: today) ?? now
    }

    private static func nextScheduledDate(for alarm: AlarmItem, after date: Date = Date()) -> Date {
        guard !alarm.repeatDays.isEmpty else {
            return nextOneTimeDate(hour: alarm.hour, minute: alarm.minute)
        }

        let calendar = Calendar.current
        let start = date.addingTimeInterval(-1)
        return alarm.repeatDays
            .compactMap { weekday -> Date? in
                var components = DateComponents()
                components.weekday = weekday
                components.hour = alarm.hour
                components.minute = alarm.minute
                components.second = 0
                return calendar.nextDate(
                    after: start,
                    matching: components,
                    matchingPolicy: .nextTime,
                    repeatedTimePolicy: .first,
                    direction: .forward
                )
            }
            .min() ?? nextOneTimeDate(hour: alarm.hour, minute: alarm.minute)
    }

    private static func scheduleSystemAlarm(_ alarm: AlarmItem) async throws {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { throw URLError(.userAuthenticationRequired) }
        case .authorized:
            break
        case .denied:
            throw URLError(.userAuthenticationRequired)
        @unknown default:
            throw URLError(.unknown)
        }

        try await schedulePrimarySystemAlarm(alarm, manager: manager)
        await scheduleBackupSystemAlarmsIfPossible(alarm)
    }

    private static func schedulePrimarySystemAlarm(_ alarm: AlarmItem, manager: AlarmManager) async throws {
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.title),
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.fill"
                ),
                secondaryButton: AlarmButton(
                    text: "Open",
                    textColor: .white,
                    systemImageName: "arrow.up.forward.app.fill"
                ),
                secondaryButtonBehavior: .custom
            )
        )
        let attributes = AlarmAttributes<PowAIAlarmMetadata>(
            presentation: presentation,
            metadata: PowAIAlarmMetadata(alarmID: alarm.id.uuidString, title: alarm.title),
            tintColor: .orange
        )

        let schedule: Alarm.Schedule
        if alarm.repeatDays.isEmpty {
            schedule = .fixed(nextOneTimeDate(hour: alarm.hour, minute: alarm.minute))
        } else {
            let weekdays = alarm.repeatDays.compactMap(localeWeekday)
            let recurrence: Alarm.Schedule.Relative.Recurrence = weekdays.isEmpty ? .never : .weekly(weekdays)
            schedule = .relative(
                Alarm.Schedule.Relative(
                    time: Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute),
                    repeats: recurrence
                )
            )
        }

        let alarmKitSound = alarm.soundOption.alarmKitSound(softAwakening: alarm.usesSoftAwakening)
        let openIntent = PowAIAlarmOpenIntent(alarmID: alarm.id.uuidString)
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: openIntent,
            sound: alarmKitSound
        )
        _ = try await manager.schedule(id: alarm.id, configuration: configuration)
    }

    private static func scheduleBackupSystemAlarmsIfPossible(_ alarm: AlarmItem, after date: Date = Date()) async {
        for (index, offset) in systemBackupAlarmOffsets.enumerated() {
            do {
                try await scheduleBackupSystemAlarm(alarm, index: index, offset: offset, after: date)
            } catch {
                print("AlarmKit backup scheduling failed for \(alarm.id) #\(index): \(error)")
            }
        }
    }

    private static func scheduleBackupSystemAlarm(_ alarm: AlarmItem, index: Int, offset: TimeInterval, after date: Date) async throws {
        let fireDate = nextScheduledDate(for: alarm, after: date).addingTimeInterval(offset)
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.title),
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.fill"
                ),
                secondaryButton: AlarmButton(
                    text: "Open",
                    textColor: .white,
                    systemImageName: "arrow.up.forward.app.fill"
                ),
                secondaryButtonBehavior: .custom
            )
        )
        let attributes = AlarmAttributes<PowAIAlarmMetadata>(
            presentation: presentation,
            metadata: PowAIAlarmMetadata(alarmID: alarm.id.uuidString, title: alarm.title),
            tintColor: .orange
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(fireDate),
            attributes: attributes,
            secondaryIntent: PowAIAlarmOpenIntent(alarmID: alarm.id.uuidString),
            sound: alarm.soundOption.alarmKitSound(softAwakening: alarm.usesSoftAwakening)
        )
        _ = try await AlarmManager.shared.schedule(
            id: backupSystemAlarmID(for: alarm, index: index),
            configuration: configuration
        )
    }

    private static func backupSystemAlarmID(for alarm: AlarmItem, index: Int) -> UUID {
        let source = alarm.id.uuid
        return UUID(uuid: (
            source.0 ^ 0xA1,
            source.1,
            source.2,
            source.3,
            source.4,
            source.5,
            source.6,
            source.7,
            source.8,
            source.9,
            source.10,
            source.11,
            source.12,
            source.13,
            source.14,
            source.15 ^ UInt8(index + 1)
        ))
    }

    private static func localeWeekday(_ day: Int) -> Locale.Weekday? {
        switch day {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}

struct PowAIAlarmMetadata: AlarmMetadata {
    let alarmID: String
    let title: String
}

struct ProductivityBootstrapResponse: Codable {
    let alarms: [AlarmItem]
    let daySchedule: [DayPlanBlock]
}

enum ProductivityBootstrapAPI {
    static func load(for date: Date) async throws -> ProductivityBootstrapResponse {
        let dateString = DayPlanDateFormatter.string(from: date)
        var components = URLComponents(string: Constants.baseURL + "app/bootstrap")
        components?.queryItems = [URLQueryItem(name: "date", value: dateString)]
        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.applyBearerToken()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ProductivityBootstrapResponse.self, from: data)
    }
}

struct FriendSummaryDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String

    var displayName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? email : name
    }
}

struct FriendshipDTO: Codable, Identifiable, Equatable {
    let id: UUID?
    let status: String
    let direction: String
    let friend: FriendSummaryDTO
    let createdAt: String?

    var stableID: UUID { id ?? friend.id }
}

struct SharedFriendItemDTO: Codable, Identifiable, Equatable {
    let id: UUID?
    let type: String
    let title: String
    let status: String
    let sender: FriendSummaryDTO
    let recipient: FriendSummaryDTO
    let createdAt: String?
    let acceptedAt: String?

    var stableID: UUID { id ?? UUID() }
    var localizedType: String {
        switch type {
        case "meal": return powAILocalized("Meal")
        case "routine_day": return powAILocalized("Routine Day")
        case "workout_day": return powAILocalized("Workout Day")
        case "day_plan_event": return powAILocalized("Day Plan Event")
        default: return type
        }
    }
}

struct FriendWorkoutActivityDTO: Codable, Identifiable, Equatable {
    let id: UUID?
    let user: FriendSummaryDTO
    let workoutType: String
    let title: String
    let muscleGroup: String?
    let durationSeconds: Int?
    let calories: Int
    let completedDate: String
    let completedAt: String?
    let challengeID: UUID?
    let challengeDay: Int?

    var stableID: UUID { id ?? UUID() }
    var localizedWorkoutType: String {
        switch workoutType {
        case "training": return powAILocalized("Training")
        case "routine": return powAILocalized("Routine")
        case "custom": return powAILocalized("Custom")
        case "hiit": return powAILocalized("HIIT")
        default: return powAILocalized("Workout")
        }
    }
}

struct FriendStreakDTO: Codable, Identifiable, Equatable {
    let user: FriendSummaryDTO
    let currentStreak: Int
    let completedToday: Bool
    let lastCompletedDate: String?
    let recentCompletions: [String]

    var id: UUID { user.id }
}

struct FriendCompetitionDTO: Codable, Equatable {
    let streaks: [FriendStreakDTO]
    let feed: [FriendWorkoutActivityDTO]
}

private struct FriendRequestPayload: Encodable {
    let email: String
}

private struct AcceptSharePayload: Encodable {
    let targetDay: Int?
}

struct WorkoutCompletionPayload: Encodable {
    let workoutType: String
    let title: String
    let muscleGroup: String?
    let durationSeconds: Int?
    let calories: Int
    let completedDate: String
    let challengeID: UUID?
    let challengeDay: Int?
}

struct ChallengeRoutineTrainingDTO: Codable {
    var workout_plan: [ChallengeWorkoutDayDTO]
}

struct ChallengeWorkoutDayDTO: Codable, Identifiable {
    var id: Int { day }
    var day: Int
    var muscle_group: String
    var exercises: [ChallengeExerciseDTO]

    var workoutPlan: workout_plans {
        workout_plans(
            day: day,
            muscle_group: muscle_group,
            exercises: exercises.map { exercise in
                Excersise(
                    name: exercise.name,
                    reps: exercise.reps,
                    sets: exercise.sets,
                    calories_burned: exercise.calories_burned,
                    descriptionEng: exercise.descriptionEng,
                    descriptionEsp: exercise.descriptionEsp,
                    loggedSets: exercise.loggedSets ?? []
                )
            }
        )
    }
}

struct ChallengeExerciseDTO: Codable, Identifiable {
    var id: String { "\(name)-\(sets)-\(reps)" }
    var name: String
    var reps: String
    var sets: Int
    var calories_burned: Int
    var descriptionEng: String?
    var descriptionEsp: String?
    var weight: Double
    var unit: String
    var loggedSets: [SetEntry]?
}

struct ChallengeSetLogDTO: Codable, Identifiable {
    let id: UUID?
    let user: FriendSummaryDTO
    let day: Int
    let exerciseIndex: Int?
    let exerciseName: String
    let setEntry: SetEntry
    let unit: String?
    let createdAt: String?

    var stableID: UUID { id ?? UUID() }
}

struct ChallengeParticipantDTO: Codable, Identifiable {
    let user: FriendSummaryDTO
    let status: String
    let isOwner: Bool
    let isViewer: Bool
    let respondedAt: String?

    var id: UUID { user.id }
}

struct WorkoutChallengeDTO: Codable, Identifiable {
    let id: UUID?
    let status: String
    let viewerStatus: String?
    let direction: String
    let requester: FriendSummaryDTO
    let recipient: FriendSummaryDTO
    let friend: FriendSummaryDTO
    let participants: [ChallengeParticipantDTO]?
    let participantCount: Int?
    let challengeType: String?
    let name: String?
    let daysPerWeek: Int
    let hoursPerWorkout: Double
    let routineTraining: ChallengeRoutineTrainingDTO?
    let logs: [ChallengeSetLogDTO]
    let createdAt: String?
    let acceptedAt: String?

    var stableID: UUID { id ?? UUID() }
    var kind: FriendChallengeKind { FriendChallengeKind(rawValue: challengeType ?? "") ?? .groupExercise }
    var displayName: String { name?.isEmpty == false ? name! : kind.defaultName }
    var effectiveStatus: String {
        if viewerStatus == "declined" { return "declined" }
        if status == "pending" { return "pending" }
        if status == "accepted", viewerStatus == "pending" { return "pending" }
        return viewerStatus ?? status
    }
    var participantTotal: Int { max(participantCount ?? progressParticipants.count, progressParticipants.count) }
    var progressParticipants: [ChallengeParticipantDTO] {
        if let participants, !participants.isEmpty {
            return participants
        }

        let requesterParticipant = ChallengeParticipantDTO(
            user: requester,
            status: "accepted",
            isOwner: true,
            isViewer: direction == "outgoing",
            respondedAt: createdAt
        )
        let recipientParticipant = ChallengeParticipantDTO(
            user: recipient,
            status: status == "accepted" ? "accepted" : status,
            isOwner: false,
            isViewer: direction == "incoming",
            respondedAt: acceptedAt
        )
        return [requesterParticipant, recipientParticipant]
    }
    var viewer: ChallengeParticipantDTO? {
        progressParticipants.first { $0.isViewer }
    }
}

private struct ChallengeInvitePayload: Encodable {
    let friendID: UUID?
    let friendIDs: [UUID]
    let daysPerWeek: Int
    let hoursPerWorkout: Double
    let challengeType: String
    let name: String
}

enum FriendChallengeKind: String, CaseIterable, Identifiable {
    case consistency
    case strengthPR = "strength_pr"
    case groupExercise = "group_exercise"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .consistency: return powAILocalized("Consistency")
        case .strengthPR: return powAILocalized("Strength PR")
        case .groupExercise: return powAILocalized("Group Exercise")
        }
    }

    var defaultName: String {
        switch self {
        case .consistency: return powAILocalized("Consistency Challenge")
        case .strengthPR: return powAILocalized("Strength PR Challenge")
        case .groupExercise: return powAILocalized("Group Workout Challenge")
        }
    }

    var subtitle: String {
        switch self {
        case .consistency: return powAILocalized("Win by showing up the most days.")
        case .strengthPR: return powAILocalized("Compete on heavier lifts and PRs.")
        case .groupExercise: return powAILocalized("Complete shared workouts together.")
        }
    }

    var icon: String {
        switch self {
        case .consistency: return "flame.fill"
        case .strengthPR: return "dumbbell.fill"
        case .groupExercise: return "figure.strengthtraining.traditional"
        }
    }

    var color: Color {
        switch self {
        case .consistency: return PowAI.orange
        case .strengthPR: return PowAI.green
        case .groupExercise: return PowAI.cyan
        }
    }
}

enum FriendShareTarget {
    case meal(UUID)
    case routineDay(Int)
    case workoutDay(Int)
    case dayPlan(UUID)

    func path(friendID: UUID) -> String {
        switch self {
        case .meal(let id):
            return "friends/\(friendID.uuidString)/share/meal/\(id.uuidString)"
        case .routineDay(let day):
            return "friends/\(friendID.uuidString)/share/routine-day/\(day)"
        case .workoutDay(let day):
            return "friends/\(friendID.uuidString)/share/workout-day/\(day)"
        case .dayPlan(let id):
            return "friends/\(friendID.uuidString)/share/day-plan/\(id.uuidString)"
        }
    }
}

enum FriendshipAPI {
    static func fetchFriends() async throws -> [FriendshipDTO] {
        let data = try await request(path: "friends", method: "GET")
        return try JSONDecoder().decode([FriendshipDTO].self, from: data)
    }

    static func fetchCompetition(date: Date = Date()) async throws -> FriendCompetitionDTO {
        let dateString = localDayFormatter.string(from: date)
        let data = try await request(path: "friends/competition?date=\(dateString)", method: "GET")
        return try JSONDecoder().decode(FriendCompetitionDTO.self, from: data)
    }

    static func sendRequest(email: String) async throws -> FriendshipDTO {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let body = try JSONEncoder().encode(FriendRequestPayload(email: normalizedEmail))
        let data = try await request(path: "friends/request", method: "POST", body: body)
        return try JSONDecoder().decode(FriendshipDTO.self, from: data)
    }

    static func acceptFriendship(id: UUID) async throws -> FriendshipDTO {
        let data = try await request(path: "friends/\(id.uuidString)/accept", method: "POST")
        return try JSONDecoder().decode(FriendshipDTO.self, from: data)
    }

    static func declineFriendship(id: UUID) async throws -> FriendshipDTO {
        let data = try await request(path: "friends/\(id.uuidString)/decline", method: "POST")
        return try JSONDecoder().decode(FriendshipDTO.self, from: data)
    }

    static func removeFriendship(id: UUID) async throws {
        _ = try await request(path: "friends/\(id.uuidString)", method: "DELETE")
    }

    static func fetchShares() async throws -> [SharedFriendItemDTO] {
        let data = try await request(path: "friends/shares", method: "GET")
        return try JSONDecoder().decode([SharedFriendItemDTO].self, from: data)
    }

    static func share(target: FriendShareTarget, with friend: FriendSummaryDTO) async throws -> SharedFriendItemDTO {
        let data = try await request(path: target.path(friendID: friend.id), method: "POST")
        return try JSONDecoder().decode(SharedFriendItemDTO.self, from: data)
    }

    static func postWorkoutCompletion(_ payload: WorkoutCompletionPayload) async throws -> FriendWorkoutActivityDTO {
        let body = try JSONEncoder().encode(payload)
        let data = try await request(path: "friends/workout-completions", method: "POST", body: body)
        return try JSONDecoder().decode(FriendWorkoutActivityDTO.self, from: data)
    }

    static func clearWorkoutCompletionHistory() async throws {
        _ = try await request(path: "friends/workout-completions", method: "DELETE")
    }

    static func fetchChallenges() async throws -> [WorkoutChallengeDTO] {
        let data = try await request(path: "friends/challenges", method: "GET")
        return try JSONDecoder().decode([WorkoutChallengeDTO].self, from: data)
    }

    static func inviteChallenge(friendIDs: [UUID], daysPerWeek: Int, hoursPerWorkout: Double, challengeType: FriendChallengeKind, name: String) async throws -> WorkoutChallengeDTO {
        let payload = ChallengeInvitePayload(
            friendID: friendIDs.first,
            friendIDs: friendIDs,
            daysPerWeek: daysPerWeek,
            hoursPerWorkout: hoursPerWorkout,
            challengeType: challengeType.rawValue,
            name: name
        )
        let body = try JSONEncoder().encode(payload)
        let data = try await request(path: "friends/challenges", method: "POST", body: body)
        return try JSONDecoder().decode(WorkoutChallengeDTO.self, from: data)
    }

    static func acceptChallenge(id: UUID) async throws -> WorkoutChallengeDTO {
        let data = try await request(path: "friends/challenges/\(id.uuidString)/accept", method: "POST")
        return try JSONDecoder().decode(WorkoutChallengeDTO.self, from: data)
    }

    static func declineChallenge(id: UUID) async throws -> WorkoutChallengeDTO {
        let data = try await request(path: "friends/challenges/\(id.uuidString)/decline", method: "POST")
        return try JSONDecoder().decode(WorkoutChallengeDTO.self, from: data)
    }

    static func deleteChallenge(id: UUID) async throws {
        _ = try await request(path: "friends/challenges/\(id.uuidString)", method: "DELETE")
    }

    static func acceptShare(id: UUID, targetDay: Int? = nil) async throws -> SharedFriendItemDTO {
        let body = targetDay.map { AcceptSharePayload(targetDay: $0) }
            .flatMap { try? JSONEncoder().encode($0) }
        let data = try await request(path: "friends/shares/\(id.uuidString)/accept", method: "POST", body: body)
        return try JSONDecoder().decode(SharedFriendItemDTO.self, from: data)
    }

    static func declineShare(id: UUID) async throws -> SharedFriendItemDTO {
        let data = try await request(path: "friends/shares/\(id.uuidString)/decline", method: "POST")
        return try JSONDecoder().decode(SharedFriendItemDTO.self, from: data)
    }

    @discardableResult
    private static func request(path: String, method: String, body: Data? = nil) async throws -> Data {
        guard let url = URL(string: Constants.baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.applyBearerToken()
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    static var localDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

@MainActor
final class AlarmViewModel: ObservableObject {
    @Published var alarms: [AlarmItem] = []
    @Published var isLoading = false
    @Published var message: String?

    private static var cachedAlarms: [AlarmItem]?
    private static var cachedAt: Date?
    private static var loadTask: Task<[AlarmItem], Error>?

    func applyServerAlarms(_ serverAlarms: [AlarmItem]) {
        let sorted = serverAlarms.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        alarms = sorted
        sorted.forEach { AlarmScheduler.schedule($0) }
        message = sorted.isEmpty ? powAILocalized("No alarms yet.") : nil
        Self.cachedAlarms = sorted
        Self.cachedAt = Date()
    }

    func load(force: Bool = false) async {
        if !force, let cached = Self.cachedAlarms, Self.isFresh(Self.cachedAt) {
            applyServerAlarms(cached)
            return
        }

        isLoading = alarms.isEmpty
        defer { isLoading = false }

        do {
            let serverAlarms: [AlarmItem]
            if let loadTask = Self.loadTask {
                serverAlarms = try await loadTask.value
            } else {
                let task = Task { try await Self.fetchAlarms() }
                Self.loadTask = task
                defer { Self.loadTask = nil }
                serverAlarms = try await task.value
            }
            applyServerAlarms(serverAlarms)
        } catch {
            message = powAILocalized("Could not load alarms.")
            print("Load alarms failed: \(error)")
        }
    }

    func save(existing: AlarmItem?, request payload: AlarmSaveRequest) async {
        do {
            var request = try makeRequest(path: existing.map { "alarms/\($0.id.uuidString)" } ?? "alarms")
            request.httpMethod = existing == nil ? "POST" : "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let saved = try JSONDecoder().decode(AlarmItem.self, from: data)
            if let index = alarms.firstIndex(where: { $0.id == saved.id }) {
                alarms[index] = saved
            } else {
                alarms.append(saved)
            }
            alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
            Self.cachedAlarms = alarms
            Self.cachedAt = Date()
            AlarmScheduler.schedule(saved)
            message = nil
        } catch {
            message = powAILocalized("Could not save alarm.")
            print("Save alarm failed: \(error)")
        }
    }

    func delete(_ alarm: AlarmItem) async {
        do {
            var request = try makeRequest(path: "alarms/\(alarm.id.uuidString)")
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            alarms.removeAll { $0.id == alarm.id }
            Self.cachedAlarms = alarms
            Self.cachedAt = Date()
            AlarmScheduler.cancel(alarm)
        } catch {
            message = powAILocalized("Could not delete alarm.")
            print("Delete alarm failed: \(error)")
        }
    }

    func setEnabled(_ alarm: AlarmItem, isEnabled: Bool) async {
        let payload = AlarmSaveRequest(
            title: alarm.title,
            hour: alarm.hour,
            minute: alarm.minute,
            repeatDays: alarm.repeatDays,
            challengeType: alarm.challengeType,
            challengeTypes: alarm.missions,
            difficulty: alarm.difficulty,
            barcodeValue: alarm.barcodeValue,
            typingPhrase: alarm.typingPhrase,
            wakeCheckMinutes: alarm.wakeCheckMinutes,
            alarmSound: alarm.soundOption.id,
            softAwakeningEnabled: alarm.usesSoftAwakening,
            hideSnoozeButton: alarm.hidesSnoozeButton,
            isEnabled: isEnabled
        )
        await save(existing: alarm, request: payload)
    }

    func activateAlarm(id: String) {
        guard let uuid = UUID(uuidString: id),
              let alarm = alarms.first(where: { $0.id == uuid }) else { return }
        AlarmRuntime.shared.activate(alarm)
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.applyBearerToken()
        return request
    }

    private static func fetchAlarms() async throws -> [AlarmItem] {
        guard let url = URL(string: Constants.baseURL + "alarms") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.applyBearerToken()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([AlarmItem].self, from: data)
    }

    private static func isFresh(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) < 20
    }
}

struct AlarmListView: View {
    @Binding var pendingAlarmID: String?
    @ObservedObject var viewModel: AlarmViewModel
    @ObservedObject private var runtime = AlarmRuntime.shared
    @State private var editingAlarm: AlarmItem?
    @State private var showingEditor = false
    let loadOnAppear: Bool

    init(
        pendingAlarmID: Binding<String?> = .constant(nil),
        viewModel: AlarmViewModel,
        loadOnAppear: Bool = true
    ) {
        _pendingAlarmID = pendingAlarmID
        self.viewModel = viewModel
        self.loadOnAppear = loadOnAppear
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(PowAI.orange)
                        .scaleEffect(1.3)
                    Spacer()
                } else {
                    alarmList
                }
            }
        }
        .task {
            if loadOnAppear {
                await viewModel.load()
            }
            activatePendingAlarmIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .powAIAlarmNotificationTapped)) { notification in
            guard let alarmID = notification.object as? String else { return }
            viewModel.activateAlarm(id: alarmID)
        }
        .sheet(isPresented: $showingEditor) {
            AlarmEditorView(alarm: editingAlarm) { payload in
                await viewModel.save(existing: editingAlarm, request: payload)
                showingEditor = false
            }
        }
        .fullScreenCover(item: $runtime.activeAlarm) { alarm in
            ActiveAlarmView(alarm: alarm)
        }
    }

    private func activatePendingAlarmIfNeeded() {
        guard let pendingAlarmID else { return }
        viewModel.activateAlarm(id: pendingAlarmID)
        self.pendingAlarmID = nil
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(powAILocalized("Alarms"))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(powAILocalized("Stack missions · Force a real wake-up"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                Text(powAILocalized("Set loud alarms that only stop after math, memory, typing, or movement missions."))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PowAI.slate.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                editingAlarm = nil
                showingEditor = true
            } label: {
                ZStack {
                    Circle()
                        .fill(PowAI.orangeGlow)
                        .frame(width: 44, height: 44)
                        .shadow(color: PowAI.orange.opacity(0.45), radius: 10, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var alarmList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if let message = viewModel.message {
                    VStack(spacing: 16) {
                        Image(systemName: "alarm")
                            .font(.system(size: 42, weight: .thin))
                            .foregroundStyle(PowAI.slate)
                        Text(message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PowAI.slate)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }

                ForEach(viewModel.alarms) { alarm in
                    AlarmRowView(
                        alarm: alarm,
                        onToggle: { isEnabled in
                            Task { await viewModel.setEnabled(alarm, isEnabled: isEnabled) }
                        },
                        onEdit: {
                            editingAlarm = alarm
                            showingEditor = true
                        },
                        onDelete: {
                            Task { await viewModel.delete(alarm) }
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
    }
}

struct ProductivityView: View {
    @Binding var pendingAlarmID: String?
    @State private var selectedSection: ProductivitySection = .alarms
    @StateObject private var alarmViewModel = AlarmViewModel()
    @StateObject private var dayPlanViewModel = DayPlanViewModel()
    @State private var didBootstrap = false
    @State private var isBootstrapping = false

    var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                customSegmentedControl
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                ZStack {
                    AlarmListView(
                        pendingAlarmID: $pendingAlarmID,
                        viewModel: alarmViewModel,
                        loadOnAppear: false
                    )
                    .opacity(selectedSection == .alarms ? 1 : 0)
                    .offset(x: selectedSection == .alarms ? 0 : -18)
                    .allowsHitTesting(selectedSection == .alarms)

                    DayPlanView(
                        viewModel: dayPlanViewModel,
                        loadOnAppear: false
                    )
                    .opacity(selectedSection == .dayPlan ? 1 : 0)
                    .offset(x: selectedSection == .dayPlan ? 0 : 18)
                    .allowsHitTesting(selectedSection == .dayPlan)
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selectedSection)
            }

            if isBootstrapping {
                bootstrapOverlay
            }
        }
        .task {
            await bootstrapProductivity()
        }
    }

    private func bootstrapProductivity() async {
        guard !didBootstrap else { return }
        isBootstrapping = true
        do {
            let response = try await ProductivityBootstrapAPI.load(for: Date())
            alarmViewModel.applyServerAlarms(response.alarms)
            dayPlanViewModel.applyServerBlocks(response.daySchedule, for: Date())
            didBootstrap = true
        } catch {
            print("Productivity bootstrap failed: \(error)")
            await alarmViewModel.load()
            await dayPlanViewModel.load(for: Date())
            didBootstrap = true
        }
        withAnimation(.easeOut(duration: 0.22)) {
            isBootstrapping = false
        }
    }

    private var bootstrapOverlay: some View {
        ZStack {
            PowAI.base.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(selectedSection.accentColor)
                    .scaleEffect(1.35)
                Text(powAILocalized("Loading your schedule..."))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PowAI.slateLight)
            }
        }
    }

    private var customSegmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(ProductivitySection.allCases, id: \.self) { section in
                segmentButton(for: section)
            }
        }
        .padding(4)
        .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(PowAI.slate.opacity(0.12), lineWidth: 1)
        }
        .sensoryFeedback(.selection, trigger: selectedSection)
    }

    private func segmentButton(for section: ProductivitySection) -> some View {
        let isSelected = selectedSection == section
        let accent = section.accentColor
        let badge = badgeCount(for: section)

        return Button {
            guard selectedSection != section else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? section.iconFilled : section.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(section.localizedTitle)
                    .font(.system(size: 14, weight: .bold))

                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(isSelected ? accent : PowAI.slateLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? accent.opacity(0.18) : PowAI.slate.opacity(0.12),
                            in: Capsule()
                        )
                }
            }
            .foregroundStyle(isSelected ? accent : PowAI.slate)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(accent.opacity(0.32), lineWidth: 1)
                        }
                        .shadow(color: accent.opacity(0.25), radius: 6, y: 3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func badgeCount(for section: ProductivitySection) -> Int? {
        switch section {
        case .alarms:
            let count = alarmViewModel.alarms.filter(\.isEnabled).count
            return count > 0 ? count : nil
        case .dayPlan:
            let count = dayPlanViewModel.blocks.filter { !$0.isDone }.count
            return count > 0 ? count : nil
        }
    }
}

private enum ProductivitySection: String, CaseIterable {
    case alarms
    case dayPlan

    var title: String {
        switch self {
        case .alarms: return "Alarms"
        case .dayPlan: return "Day Plan"
        }
    }

    var localizedTitle: String {
        powAILocalized(title)
    }

    var icon: String {
        switch self {
        case .alarms: return "alarm"
        case .dayPlan: return "calendar.badge.clock"
        }
    }

    var iconFilled: String {
        switch self {
        case .alarms: return "alarm.fill"
        case .dayPlan: return "calendar.badge.clock"
        }
    }

    var accentColor: Color {
        switch self {
        case .alarms: return PowAI.orange
        case .dayPlan: return PowAI.cyan
        }
    }
}

struct FriendshipCenterView: View {
    @State private var friendships: [FriendshipDTO] = []
    @State private var shares: [SharedFriendItemDTO] = []
    @State private var competition: FriendCompetitionDTO?
    @State private var challenges: [WorkoutChallengeDTO] = []
    @State private var email = ""
    @State private var isLoading = false
    @State private var message: String?
    @State private var showingAddFriend = false
    @State private var showingChallengeCreator = false
    @State private var activeChallengeWorkout: ActiveChallengeWorkout?
    @State private var selectedChallenge: WorkoutChallengeDTO?

    private var incomingRequests: [FriendshipDTO] {
        friendships.filter { $0.status == "pending" && $0.direction == "incoming" }
    }

    private var outgoingRequests: [FriendshipDTO] {
        friendships.filter { $0.status == "pending" && $0.direction == "outgoing" }
    }

    private var acceptedFriends: [FriendshipDTO] {
        friendships.filter { $0.status == "accepted" }
    }

    private var activeChallenges: [WorkoutChallengeDTO] {
        challenges.filter { $0.effectiveStatus != "declined" }
    }

    private var incomingShares: [SharedFriendItemDTO] {
        shares.filter { $0.status == "pending" }
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    addFriendCard
                    activeChallengesSection
                    if let competition { weeklyLeaderboardSection(competition) }
                    if let competition { activitySection(competition) }
                    friendsSection
                    if !incomingRequests.isEmpty { requestsSection }
                    if !incomingShares.isEmpty { sharesSection }
                    if !outgoingRequests.isEmpty { outgoingSection }
                    if let message {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(PowAI.slate)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showingChallengeCreator) {
            ChallengeCreatorView(friends: acceptedFriends.map(\.friend)) { friends, kind, name, days, hours in
                await inviteChallenge(friends: friends, kind: kind, name: name, days: days, hours: hours)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedChallenge) { challenge in
            ChallengeDetailView(
                challenge: challenge,
                competition: competition,
                onAccept: {
                    Task { await acceptChallenge(challenge) }
                },
                onDecline: {
                    Task { await declineChallenge(challenge) }
                },
                onDelete: {
                    Task { await deleteChallenge(challenge) }
                },
                onStartDay: { day in
                    selectedChallenge = nil
                    activeChallengeWorkout = ActiveChallengeWorkout(challenge: challenge, day: day)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $activeChallengeWorkout) { active in
            ChallengeWorkoutRunner(active: active) {
                activeChallengeWorkout = nil
                Task { await load() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(powAILocalized("Friends"))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(powAILocalized("Compete, climb streaks, and keep each other moving."))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PowAI.slate)
        }
    }

    private var addFriendCard: some View {
        PowAICard(accentColor: PowAI.cyan) {
            if showingAddFriend {
                HStack(spacing: 10) {
                    PowAIInputField(placeholder: powAILocalized("Friend email"), text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    Button {
                        Task { await sendRequest() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 42, height: 42)
                            .background(PowAI.cyan, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showingAddFriend = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 38, height: 38)
                            .background(PowAI.cyan, in: Circle())

                        Text(powAILocalized("Add Friend"))
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.black))
                            .foregroundStyle(PowAI.slate)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PowAISectionLabel(text: powAILocalized("Active Challenges"))
                Spacer()
                Button {
                    showingChallengeCreator = true
                } label: {
                    Label(powAILocalized("New"), systemImage: "plus")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(PowAI.orange, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(acceptedFriends.isEmpty || isLoading)
            }

            if activeChallenges.isEmpty {
                Text(powAILocalized("Challenge friends to build streaks, chase PRs, or finish group workouts."))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(activeChallenges.prefix(6), id: \.stableID) { challenge in
                    challengeCard(challenge)
                }
            }
        }
    }

    private var requestsSection: some View {
        section(title: powAILocalized("Friend Requests")) {
            ForEach(incomingRequests, id: \.stableID) { friendship in
                friendshipRow(friendship) {
                    Task { await accept(friendship) }
                } secondary: {
                    Task { await decline(friendship) }
                }
            }
        }
    }

    private func weeklyLeaderboardSection(_ competition: FriendCompetitionDTO) -> some View {
        section(title: powAILocalized("Weekly Leaderboard")) {
            VStack(spacing: 8) {
                ForEach(Array(competition.streaks.sorted(by: leaderboardSort).prefix(6).enumerated()), id: \.element.id) { index, streak in
                    let score = weeklyScore(streak)
                    let progress = min(1, Double(score) / 7.0)
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(index == 0 ? PowAI.orange : PowAI.slateLight)
                            .frame(width: 34)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Text(streak.user.displayName)
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                if streak.completedToday {
                                    Image(systemName: "flame.fill")
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(PowAI.orange)
                                }
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(PowAI.slate.opacity(0.16))
                                    Capsule()
                                        .fill(index == 0 ? PowAI.orange : PowAI.cyan)
                                        .frame(width: proxy.size.width * progress)
                                }
                            }
                            .frame(height: 6)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(powAILocalizedFormat("%d days", score))
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                            Text(powAILocalizedFormat("%d streak", streak.currentStreak))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(PowAI.slate)
                        }
                    }
                    .padding(11)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke((index == 0 ? PowAI.orange : PowAI.cyan).opacity(index == 0 ? 0.32 : 0.12), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func streaksSection(_ competition: FriendCompetitionDTO) -> some View {
        section(title: powAILocalized("Streaks")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(competition.streaks) { streak in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: streak.completedToday ? "flame.fill" : "flame")
                                    .foregroundStyle(streak.completedToday ? PowAI.orange : PowAI.slate)
                                Text(streak.user.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }

                            Text(powAILocalizedFormat("%d day streak", streak.currentStreak))
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(streak.currentStreak > 0 ? PowAI.orange : PowAI.slate)

                            Text(streak.completedToday ? powAILocalized("Done today") : powAILocalized("Not done today"))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(PowAI.slate)
                        }
                        .frame(width: 150, alignment: .leading)
                        .padding(13)
                        .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke((streak.completedToday ? PowAI.orange : PowAI.cyan).opacity(0.28), lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func activitySection(_ competition: FriendCompetitionDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PowAISectionLabel(text: powAILocalized("Friend Activity Feed"))
                Spacer()
                if !competition.feed.isEmpty {
                    Button {
                        Task { await clearActivityHistory() }
                    } label: {
                        Label(powAILocalized("Clear My History"), systemImage: "trash")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.red.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if competition.feed.isEmpty {
                Text(powAILocalized("Only friend challenge workouts appear here."))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(14)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(competition.feed.prefix(8), id: \.stableID) { activity in
                    HStack(spacing: 10) {
                        Image(systemName: activity.challengeID == nil ? "bolt.heart.fill" : "trophy.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(activity.challengeID == nil ? PowAI.green : PowAI.orange)
                            .frame(width: 32, height: 32)
                            .background((activity.challengeID == nil ? PowAI.green : PowAI.orange).opacity(0.13), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(powAILocalizedFormat("%@ finished %@", activity.user.displayName, activity.title))
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(activitySummary(activity))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(PowAI.cyan)
                        }

                        Spacer()
                    }
                    .padding(11)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var sharesSection: some View {
        section(title: powAILocalized("Shared With You")) {
            ForEach(incomingShares, id: \.stableID) { share in
                PowAICard(accentColor: PowAI.green) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(share.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("\(share.localizedType) • \(share.sender.displayName)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PowAI.slate)
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            Button(powAILocalized("Add")) {
                                Task { await acceptShare(share) }
                            }
                            .buttonStyle(PowAIPrimaryButtonStyle(color: PowAI.green))

                            Button(powAILocalized("Skip")) {
                                Task { await declineShare(share) }
                            }
                            .buttonStyle(PowAISecondaryButtonStyle())
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private var challengesSection: some View {
        section(title: powAILocalized("Challenges")) {
            ForEach(challenges, id: \.stableID) { challenge in
                challengeCard(challenge)
            }
        }
    }

    private var friendsSection: some View {
        section(title: powAILocalized("Your Friends")) {
            if acceptedFriends.isEmpty {
                Text(powAILocalized("Add friends to start sharing."))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(18)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(acceptedFriends, id: \.stableID) { friendship in
                    acceptedFriendRow(friendship)
                }
            }
        }
    }

    private var outgoingSection: some View {
        section(title: powAILocalized("Sent Requests")) {
            ForEach(outgoingRequests, id: \.stableID) { friendship in
                friendLabel(friendship.friend, subtitle: powAILocalized("Waiting for approval"))
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PowAISectionLabel(text: title)
            content()
        }
    }

    private func friendLabel(_ friend: FriendSummaryDTO, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PowAI.cyan)
                .frame(width: 36, height: 36)
                .background(PowAI.cyan.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PowAI.slate)
            }
            Spacer()
        }
        .padding(13)
        .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func acceptedFriendRow(_ friendship: FriendshipDTO) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PowAI.cyan)
                .frame(width: 36, height: 36)
                .background(PowAI.cyan.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(friendship.friend.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(friendship.friend.email)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Task { await removeFriend(friendship) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.red)
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(powAILocalized("Remove Friend"))
        }
        .padding(13)
        .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func friendshipRow(_ friendship: FriendshipDTO, primary: @escaping () -> Void, secondary: @escaping () -> Void) -> some View {
        PowAICard(accentColor: PowAI.cyan) {
            VStack(alignment: .leading, spacing: 10) {
                friendLabel(friendship.friend, subtitle: friendship.friend.email)
                HStack(spacing: 10) {
                    Button(powAILocalized("Accept"), action: primary)
                        .buttonStyle(PowAIPrimaryButtonStyle(color: PowAI.cyan))
                    Button(powAILocalized("Decline"), action: secondary)
                        .buttonStyle(PowAISecondaryButtonStyle())
                }
            }
            .padding(12)
        }
    }

    private func challengeCard(_ challenge: WorkoutChallengeDTO) -> some View {
        let metrics = challengeMetrics(challenge)
        let status = challenge.effectiveStatus
        let accent = status == "accepted" ? challenge.kind.color : PowAI.orange

        return PowAICard(accentColor: accent) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: challenge.kind.icon)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(accent, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(challenge.displayName)
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(challenge.kind.title) • \(powAILocalizedFormat("%d participants", challenge.participantTotal))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(PowAI.slate)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(rankText(for: metrics))
                            .font(.caption.weight(.black))
                            .foregroundStyle(accent)
                        Text(daysRemainingText(for: challenge))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(PowAI.slate)
                    }

                    Button {
                        Task { await deleteChallenge(challenge) }
                    } label: {
                        Image(systemName: status == "pending" ? "xmark" : "trash")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.red)
                            .frame(width: 30, height: 30)
                            .background(Color.red.opacity(0.14), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(status == "pending" ? powAILocalized("Cancel Challenge") : powAILocalized("Remove Challenge"))
                }

                ForEach(metrics.rows.prefix(4)) { row in
                    challengeProgressRow(
                        label: row.isViewer ? powAILocalized("You") : row.user.displayName,
                        value: row.completed,
                        target: metrics.target,
                        color: row.isViewer ? accent : PowAI.cyan
                    )
                }

                if status == "pending" {
                    pendingChallengeFooter(challenge)
                } else {
                    Text(powAILocalized("Tap for details"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PowAI.slate)
                }
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedChallenge = challenge
            }
        }
    }

    private func challengeProgressRow(label: String, value: Int, target: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(PowAI.slateLight)
                .lineLimit(1)
                .frame(width: 64, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PowAI.slate.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * min(1, Double(value) / Double(max(1, target))))
                }
            }
            .frame(height: 7)

            Text("\(value)/\(target)")
                .font(.caption2.weight(.black))
                .foregroundStyle(color)
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func pendingChallengeFooter(_ challenge: WorkoutChallengeDTO) -> some View {
        Group {
            if challenge.direction == "incoming" && challenge.effectiveStatus == "pending" {
                HStack(spacing: 8) {
                    Button(powAILocalized("Accept")) {
                        Task { await acceptChallenge(challenge) }
                    }
                    .buttonStyle(PowAIPrimaryButtonStyle(color: challenge.kind.color))

                    Button(powAILocalized("Decline")) {
                        Task { await declineChallenge(challenge) }
                    }
                    .buttonStyle(PowAISecondaryButtonStyle())
                }
            } else {
                Text(challenge.participantTotal > 2 ? powAILocalized("Waiting for friends to accept.") : powAILocalized("Waiting for your friend to accept."))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PowAI.slate)
            }
        }
    }

    private func challengeMetrics(_ challenge: WorkoutChallengeDTO) -> ChallengeProgressMetrics {
        let routineDays = challenge.routineTraining?.workout_plan.count ?? 0
        let target = max(1, min(7, max(challenge.daysPerWeek, routineDays)))
        let rows = challenge.progressParticipants.map { participant in
            ChallengeParticipantProgress(
                user: participant.user,
                isViewer: participant.isViewer,
                status: participant.status,
                completed: min(completedChallengeDays(for: participant.user.id, in: challenge).count, target)
            )
        }.sorted { first, second in
            if first.isViewer != second.isViewer { return first.isViewer }
            if first.completed != second.completed { return first.completed > second.completed }
            return first.user.displayName.localizedCaseInsensitiveCompare(second.user.displayName) == .orderedAscending
        }
        return ChallengeProgressMetrics(rows: rows, target: target)
    }

    private func completedChallengeDays(for userID: UUID, in challenge: WorkoutChallengeDTO) -> Set<Int> {
        var days = Set<Int>()

        if let challengeID = challenge.id {
            competition?.feed.forEach { activity in
                if activity.user.id == userID,
                   activity.challengeID == challengeID,
                   let day = activity.challengeDay,
                   day > 0 {
                    days.insert(day)
                }
            }
        }

        challenge.logs.forEach { log in
            if log.user.id == userID {
                days.insert(log.day)
            }
        }

        return days
    }

    private func rankText(for metrics: ChallengeProgressMetrics) -> String {
        guard let viewer = metrics.rows.first(where: { $0.isViewer }) else {
            return "#1"
        }
        let betterCount = metrics.rows.filter { $0.completed > viewer.completed }.count
        let tiedCount = metrics.rows.filter { $0.completed == viewer.completed }.count
        if betterCount == 0 && tiedCount > 1 {
            return powAILocalized("Tied #1")
        }
        return "#\(betterCount + 1)"
    }

    private func daysRemainingText(for challenge: WorkoutChallengeDTO) -> String {
        guard challenge.effectiveStatus == "accepted" else {
            return powAILocalized(challenge.effectiveStatus.capitalized)
        }

        let start = parseServerDate(challenge.acceptedAt) ?? parseServerDate(challenge.createdAt) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
        return powAILocalizedFormat("%d days left", days)
    }

    private func leaderboardSort(_ first: FriendStreakDTO, _ second: FriendStreakDTO) -> Bool {
        let firstScore = weeklyScore(first)
        let secondScore = weeklyScore(second)
        if firstScore != secondScore { return firstScore > secondScore }
        if first.currentStreak != second.currentStreak { return first.currentStreak > second.currentStreak }
        return first.user.displayName.localizedCaseInsensitiveCompare(second.user.displayName) == .orderedAscending
    }

    private func weeklyScore(_ streak: FriendStreakDTO) -> Int {
        min(7, streak.recentCompletions.count)
    }

    private func parseServerDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string)
    }

    private func challengeSubtitle(_ challenge: WorkoutChallengeDTO) -> String {
        powAILocalizedFormat("%d days/week • %.1f hours", challenge.daysPerWeek, challenge.hoursPerWorkout)
    }

    private func challengeLogSummary(_ log: ChallengeSetLogDTO) -> String {
        let weight = Int(log.setEntry.weight.rounded())
        return powAILocalizedFormat("Day %d • %@ • %d x %d lb", log.day, log.exerciseName, log.setEntry.reps, weight)
    }

    private func isChallengeDayDone(_ challenge: WorkoutChallengeDTO, day: Int) -> Bool {
        guard let challengeID = challenge.id else {
            return challenge.logs.contains { $0.day == day }
        }

        if competition?.feed.contains(where: { activity in
            activity.challengeID == challengeID && activity.challengeDay == day
        }) == true {
            return true
        }

        return challenge.logs.contains { $0.day == day }
    }

    private func activitySummary(_ activity: FriendWorkoutActivityDTO) -> String {
        var parts = [activity.localizedWorkoutType]
        if let duration = activity.durationSeconds, duration > 0 {
            parts.append(formatDuration(duration))
        }
        if activity.calories > 0 {
            parts.append(powAILocalizedFormat("%d cal", activity.calories))
        }
        parts.append(activity.completedDate)
        return parts.joined(separator: " • ")
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = max(1, seconds / 60)
        if minutes < 60 {
            return powAILocalizedFormat("%dm", minutes)
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? powAILocalizedFormat("%dh", hours) : powAILocalizedFormat("%dh %dm", hours, remaining)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchedFriends = FriendshipAPI.fetchFriends()
            async let fetchedShares = FriendshipAPI.fetchShares()
            async let fetchedCompetition = FriendshipAPI.fetchCompetition()
            async let fetchedChallenges = FriendshipAPI.fetchChallenges()
            friendships = try await fetchedFriends
            shares = try await fetchedShares
            competition = try await fetchedCompetition
            challenges = try await fetchedChallenges
            message = nil
        } catch {
            message = powAILocalized("Could not load friends.")
        }
    }

    @MainActor
    private func sendRequest() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return }
        do {
            let friendship = try await FriendshipAPI.sendRequest(email: trimmedEmail)
            upsert(friendship)
            email = ""
            showingAddFriend = false
            message = powAILocalized("Friend request sent.")
        } catch {
            message = powAILocalized("Could not send friend request.")
        }
    }

    @MainActor
    private func accept(_ friendship: FriendshipDTO) async {
        guard let id = friendship.id else { return }
        do {
            upsert(try await FriendshipAPI.acceptFriendship(id: id))
        } catch {
            message = powAILocalized("Could not accept friend request.")
        }
    }

    @MainActor
    private func decline(_ friendship: FriendshipDTO) async {
        guard let id = friendship.id else { return }
        do {
            upsert(try await FriendshipAPI.declineFriendship(id: id))
        } catch {
            message = powAILocalized("Could not decline friend request.")
        }
    }

    @MainActor
    private func removeFriend(_ friendship: FriendshipDTO) async {
        guard let id = friendship.id else { return }
        do {
            try await FriendshipAPI.removeFriendship(id: id)
            friendships.removeAll { $0.stableID == friendship.stableID }
            message = powAILocalized("Friend removed.")
        } catch {
            message = powAILocalized("Could not remove friend.")
        }
    }

    @MainActor
    private func acceptShare(_ share: SharedFriendItemDTO) async {
        guard let id = share.id else { return }
        do {
            upsert(try await FriendshipAPI.acceptShare(id: id))
            message = powAILocalized("Shared item added.")
        } catch {
            message = powAILocalized("Could not add shared item.")
        }
    }

    @MainActor
    private func declineShare(_ share: SharedFriendItemDTO) async {
        guard let id = share.id else { return }
        do {
            upsert(try await FriendshipAPI.declineShare(id: id))
        } catch {
            message = powAILocalized("Could not skip shared item.")
        }
    }

    @MainActor
    private func clearActivityHistory() async {
        do {
            try await FriendshipAPI.clearWorkoutCompletionHistory()
            competition = try await FriendshipAPI.fetchCompetition()
            message = powAILocalized("Your shared activity history was cleared.")
        } catch {
            message = powAILocalized("Could not clear activity history.")
        }
    }

    @MainActor
    private func inviteChallenge(friends: [FriendSummaryDTO], kind: FriendChallengeKind, name: String, days: Int, hours: Double) async {
        do {
            let challenge = try await FriendshipAPI.inviteChallenge(
                friendIDs: friends.map(\.id),
                daysPerWeek: days,
                hoursPerWorkout: hours,
                challengeType: kind,
                name: name
            )
            upsert(challenge)
            message = powAILocalized("Challenge sent.")
        } catch {
            message = powAILocalized("Could not send challenge.")
        }
    }

    @MainActor
    private func acceptChallenge(_ challenge: WorkoutChallengeDTO) async {
        guard let id = challenge.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            upsert(try await FriendshipAPI.acceptChallenge(id: id))
            message = powAILocalized("Challenge accepted.")
        } catch {
            message = powAILocalized("Could not accept challenge.")
        }
    }

    @MainActor
    private func declineChallenge(_ challenge: WorkoutChallengeDTO) async {
        guard let id = challenge.id else { return }
        do {
            upsert(try await FriendshipAPI.declineChallenge(id: id))
        } catch {
            message = powAILocalized("Could not decline challenge.")
        }
    }

    @MainActor
    private func deleteChallenge(_ challenge: WorkoutChallengeDTO) async {
        guard let id = challenge.id else { return }
        do {
            try await FriendshipAPI.deleteChallenge(id: id)
            challenges.removeAll { $0.stableID == challenge.stableID }
            if selectedChallenge?.stableID == challenge.stableID {
                selectedChallenge = nil
            }
            message = powAILocalized("Challenge removed.")
        } catch {
            message = powAILocalized("Could not remove challenge.")
        }
    }

    private func upsert(_ friendship: FriendshipDTO) {
        if let index = friendships.firstIndex(where: { $0.stableID == friendship.stableID }) {
            friendships[index] = friendship
        } else {
            friendships.insert(friendship, at: 0)
        }
    }

    private func upsert(_ share: SharedFriendItemDTO) {
        if let index = shares.firstIndex(where: { $0.stableID == share.stableID }) {
            shares[index] = share
        } else {
            shares.insert(share, at: 0)
        }
    }

    private func upsert(_ challenge: WorkoutChallengeDTO) {
        if let index = challenges.firstIndex(where: { $0.stableID == challenge.stableID }) {
            challenges[index] = challenge
        } else {
            challenges.insert(challenge, at: 0)
        }
    }
}

private struct ActiveChallengeWorkout: Identifiable {
    let challenge: WorkoutChallengeDTO
    let day: ChallengeWorkoutDayDTO

    var id: String { "\(challenge.stableID.uuidString)-\(day.day)" }
}

private struct ChallengeParticipantProgress: Identifiable {
    let user: FriendSummaryDTO
    let isViewer: Bool
    let status: String
    let completed: Int

    var id: UUID { user.id }
}

private struct ChallengeProgressMetrics {
    let rows: [ChallengeParticipantProgress]
    let target: Int
}

private struct ChallengeDetailView: View {
    let challenge: WorkoutChallengeDTO
    let competition: FriendCompetitionDTO?
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onDelete: () -> Void
    let onStartDay: (ChallengeWorkoutDayDTO) -> Void

    @Environment(\.dismiss) private var dismiss

    private var metrics: ChallengeProgressMetrics {
        let routineDays = challenge.routineTraining?.workout_plan.count ?? 0
        let target = max(1, min(7, max(challenge.daysPerWeek, routineDays)))
        let rows = challenge.progressParticipants.map { participant in
            ChallengeParticipantProgress(
                user: participant.user,
                isViewer: participant.isViewer,
                status: participant.status,
                completed: min(completedDays(for: participant.user.id).count, target)
            )
        }.sorted { first, second in
            if first.isViewer != second.isViewer { return first.isViewer }
            if first.completed != second.completed { return first.completed > second.completed }
            return first.user.displayName.localizedCaseInsensitiveCompare(second.user.displayName) == .orderedAscending
        }
        return ChallengeProgressMetrics(rows: rows, target: target)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        headerCard
                        progressCard

                        if challenge.effectiveStatus == "pending" {
                            pendingCard
                        }

                        if challenge.effectiveStatus == "accepted",
                           challenge.kind == .groupExercise,
                           let routine = challenge.routineTraining {
                            workoutDaysSection(routine)
                        }

                        if !challenge.logs.isEmpty {
                            sharedLiftsSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(powAILocalized("Challenge"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(powAILocalized("Close")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: challenge.effectiveStatus == "pending" ? "xmark" : "trash")
                    }
                    .accessibilityLabel(challenge.effectiveStatus == "pending" ? powAILocalized("Cancel Challenge") : powAILocalized("Remove Challenge"))
                }
            }
        }
    }

    private var headerCard: some View {
        PowAICard(accentColor: challenge.kind.color) {
            HStack(spacing: 12) {
                Image(systemName: challenge.kind.icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(challenge.kind.color, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.displayName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                    Text("\(challenge.kind.title) • \(powAILocalizedFormat("%d participants", challenge.participantTotal))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PowAI.slate)
                }

                Spacer()

                Text(powAILocalized(challenge.effectiveStatus.capitalized))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(challenge.kind.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(challenge.kind.color.opacity(0.14), in: Capsule())
            }
            .padding(14)
        }
    }

    private var progressCard: some View {
        PowAICard(accentColor: challenge.kind.color) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(powAILocalized("Current Ranking"))
                            .font(.caption.weight(.black))
                            .foregroundStyle(PowAI.slate)
                        Text(rankText)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(challenge.kind.color)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(powAILocalized("Time Left"))
                            .font(.caption.weight(.black))
                            .foregroundStyle(PowAI.slate)
                        Text(daysRemainingText)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                    }
                }

                ForEach(metrics.rows) { row in
                    progressRow(
                        label: row.isViewer ? powAILocalized("You") : row.user.displayName,
                        value: row.completed,
                        color: row.isViewer ? challenge.kind.color : PowAI.cyan
                    )
                }
            }
            .padding(14)
        }
    }

    private var pendingCard: some View {
        PowAICard(accentColor: PowAI.orange) {
            VStack(alignment: .leading, spacing: 10) {
                Text(challenge.direction == "incoming" ? powAILocalized("Ready to compete?") : (challenge.participantTotal > 2 ? powAILocalized("Waiting for friends to accept.") : powAILocalized("Waiting for your friend to accept.")))
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)

                if challenge.direction == "incoming" {
                    HStack(spacing: 10) {
                        Button(powAILocalized("Accept Challenge"), action: onAccept)
                            .buttonStyle(PowAIPrimaryButtonStyle(color: challenge.kind.color))
                        Button(powAILocalized("Decline"), action: onDecline)
                            .buttonStyle(PowAISecondaryButtonStyle())
                    }
                }
            }
            .padding(14)
        }
    }

    private func workoutDaysSection(_ routine: ChallengeRoutineTrainingDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PowAISectionLabel(text: powAILocalized("Group Workouts"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(routine.workout_plan.sorted { $0.day < $1.day }) { day in
                    let isDone = completedDays(for: currentUser.id).contains(day.day)
                    Button {
                        onStartDay(day)
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "play.circle.fill")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(isDone ? PowAI.green : challenge.kind.color)
                            Text(powAILocalizedFormat("Day %d", day.day))
                                .font(.caption2.weight(.black))
                                .foregroundStyle(isDone ? PowAI.green : challenge.kind.color)
                            Text(day.muscle_group)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .padding(8)
                        .background((isDone ? PowAI.green : PowAI.surface).opacity(isDone ? 0.18 : 1), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((isDone ? PowAI.green : challenge.kind.color).opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sharedLiftsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PowAISectionLabel(text: powAILocalized("Shared Lifts"))
            VStack(spacing: 8) {
                ForEach(challenge.logs.prefix(8), id: \.stableID) { log in
                    HStack {
                        Text(log.user.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(logSummary(log))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(PowAI.cyan)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var currentUser: FriendSummaryDTO {
        challenge.viewer?.user ?? (challenge.direction == "outgoing" ? challenge.requester : challenge.recipient)
    }

    private var rankText: String {
        guard let viewer = metrics.rows.first(where: { $0.isViewer }) else {
            return "#1"
        }
        let betterCount = metrics.rows.filter { $0.completed > viewer.completed }.count
        let tiedCount = metrics.rows.filter { $0.completed == viewer.completed }.count
        if betterCount == 0 && tiedCount > 1 {
            return powAILocalized("Tied #1")
        }
        return "#\(betterCount + 1)"
    }

    private var daysRemainingText: String {
        guard challenge.effectiveStatus == "accepted" else {
            return powAILocalized(challenge.effectiveStatus.capitalized)
        }
        let start = parseServerDate(challenge.acceptedAt) ?? parseServerDate(challenge.createdAt) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
        return powAILocalizedFormat("%d days left", days)
    }

    private func progressRow(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(PowAI.slateLight)
                .lineLimit(1)
                .frame(width: 86, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PowAI.slate.opacity(0.16))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * min(1, Double(value) / Double(max(1, metrics.target))))
                }
            }
            .frame(height: 8)

            Text("\(value)/\(metrics.target)")
                .font(.caption.weight(.black))
                .foregroundStyle(color)
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func completedDays(for userID: UUID) -> Set<Int> {
        var days = Set<Int>()
        if let challengeID = challenge.id {
            competition?.feed.forEach { activity in
                if activity.user.id == userID,
                   activity.challengeID == challengeID,
                   let day = activity.challengeDay,
                   day > 0 {
                    days.insert(day)
                }
            }
        }
        challenge.logs.forEach { log in
            if log.user.id == userID {
                days.insert(log.day)
            }
        }
        return days
    }

    private func logSummary(_ log: ChallengeSetLogDTO) -> String {
        let weight = Int(log.setEntry.weight.rounded())
        return powAILocalizedFormat("Day %d • %@ • %d x %d lb", log.day, log.exerciseName, log.setEntry.reps, weight)
    }

    private func parseServerDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string)
    }
}

private struct ChallengeWorkoutRunner: View {
    let active: ActiveChallengeWorkout
    let onClose: () -> Void

    @State private var exToday: String

    init(active: ActiveChallengeWorkout, onClose: @escaping () -> Void) {
        self.active = active
        self.onClose = onClose
        _exToday = State(initialValue: active.day.muscle_group)
    }

    var body: some View {
        StaringWorkWindow(
            todaysWork: active.day.workoutPlan,
            exToday: $exToday,
            cals: active.day.exercises.reduce(0) { $0 + $1.calories_burned },
            onWorkoutFinished: onClose,
            routineDay: active.day.day,
            challengeID: active.challenge.id,
            routineExerciseWeights: active.day.exercises.map { $0.weight },
            routineExerciseUnits: active.day.exercises.map { $0.unit },
            onRoutineHome: onClose
        )
        .onChange(of: exToday) {
            if exToday.isEmpty {
                onClose()
            }
        }
    }
}

private struct ChallengeCreatorView: View {
    let friends: [FriendSummaryDTO]
    let onInvite: ([FriendSummaryDTO], FriendChallengeKind, String, Int, Double) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriendIDs = Set<UUID>()
    @State private var selectedKind: FriendChallengeKind = .consistency
    @State private var challengeName = FriendChallengeKind.consistency.defaultName
    @State private var days = 4
    @State private var hours = 1.0
    @State private var isSending = false

    private var selectedFriends: [FriendSummaryDTO] {
        friends.filter { selectedFriendIDs.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        if friends.isEmpty {
                            Text(powAILocalized("Add accepted friends before starting a challenge."))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(PowAI.slate)
                        } else {
                            ForEach(friends) { friend in
                                Button {
                                    toggleFriend(friend)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(friend.displayName)
                                                .font(.subheadline.weight(.bold))
                                            Text(friend.email)
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(PowAI.slate)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedFriendIDs.contains(friend.id) ? PowAI.cyan : PowAI.slate)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text(powAILocalized("Friends"))
                    } footer: {
                        Text(powAILocalizedFormat("%d selected", selectedFriendIDs.count))
                    }

                    Section(powAILocalized("Challenge")) {
                        TextField(powAILocalized("Challenge name"), text: $challengeName)

                        Picker(powAILocalized("Type"), selection: $selectedKind) {
                            ForEach(FriendChallengeKind.allCases) { kind in
                                Label(kind.title, systemImage: kind.icon).tag(kind)
                            }
                        }

                        Text(selectedKind.subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PowAI.slate)

                        Stepper(powAILocalizedFormat("%d workout days", days), value: $days, in: 1...7)
                        Stepper(powAILocalizedFormat("%.1f hours each", hours), value: $hours, in: 0.5...4, step: 0.5)
                    }

                    Button {
                        Task { await send() }
                    } label: {
                        HStack {
                            if isSending { ProgressView() }
                            Text(powAILocalized("Send Challenge"))
                        }
                    }
                    .disabled(selectedFriends.isEmpty || isSending)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(powAILocalized("7-Day Challenge"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(powAILocalized("Close")) { dismiss() }
                }
            }
            .onAppear {
                if challengeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    challengeName = selectedKind.defaultName
                }
            }
            .onChange(of: selectedKind) { _, newKind in
                if FriendChallengeKind.allCases.map(\.defaultName).contains(challengeName) {
                    challengeName = newKind.defaultName
                }
            }
        }
    }

    private func toggleFriend(_ friend: FriendSummaryDTO) {
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    @MainActor
    private func send() async {
        let selectedFriends = selectedFriends
        guard !selectedFriends.isEmpty else { return }
        let trimmedName = challengeName.trimmingCharacters(in: .whitespacesAndNewlines)
        isSending = true
        await onInvite(selectedFriends, selectedKind, trimmedName.isEmpty ? selectedKind.defaultName : trimmedName, days, hours)
        isSending = false
        dismiss()
    }
}

struct FriendSharePickerView: View {
    let title: String
    let target: FriendShareTarget

    @Environment(\.dismiss) private var dismiss
    @State private var friendships: [FriendshipDTO] = []
    @State private var isLoading = false
    @State private var message: String?

    private var friends: [FriendSummaryDTO] {
        friendships
            .filter { $0.status == "accepted" }
            .map(\.friend)
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                List {
                    if friends.isEmpty && !isLoading {
                        Text(powAILocalized("Add friends before sharing."))
                            .foregroundStyle(PowAI.slate)
                    }

                    ForEach(friends) { friend in
                        Button {
                            Task { await share(with: friend) }
                        } label: {
                            HStack {
                                Label(friend.displayName, systemImage: "person.fill")
                                Spacer()
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(PowAI.cyan)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(powAILocalized("Close")) { dismiss() }
                }
            }
            .task { await loadFriends() }
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(PowAI.cyan)
                }
            }
            .alert(powAILocalized("Share"), isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button(powAILocalized("OK"), role: .cancel) {
                    if message == powAILocalized("Shared.") {
                        dismiss()
                    }
                }
            } message: {
                Text(message ?? "")
            }
        }
    }

    @MainActor
    private func loadFriends() async {
        isLoading = true
        defer { isLoading = false }
        do {
            friendships = try await FriendshipAPI.fetchFriends()
        } catch {
            message = powAILocalized("Could not load friends.")
        }
    }

    @MainActor
    private func share(with friend: FriendSummaryDTO) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await FriendshipAPI.share(target: target, with: friend)
            message = powAILocalized("Shared.")
        } catch {
            message = powAILocalized("Could not share.")
        }
    }
}

struct PowAIPrimaryButtonStyle: ButtonStyle {
    var color: Color = PowAI.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.black))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct PowAISecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.black))
            .foregroundStyle(PowAI.slateLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(PowAI.surface.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DayPlanCategory: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let color: Color

    static let options: [DayPlanCategory] = [
        DayPlanCategory(id: "focus", title: "Focus", icon: "target", color: .cyan),
        DayPlanCategory(id: "workout", title: "Workout", icon: "figure.strengthtraining.traditional", color: .orange),
        DayPlanCategory(id: "meal", title: "Meal", icon: "fork.knife", color: .green),
        DayPlanCategory(id: "break", title: "Break", icon: "cup.and.saucer.fill", color: .mint),
        DayPlanCategory(id: "errand", title: "Errand", icon: "bag.fill", color: .purple),
        DayPlanCategory(id: "personal", title: "Personal", icon: "person.fill", color: .pink)
    ]

    static func option(for id: String) -> DayPlanCategory {
        options.first { $0.id == id.lowercased() } ?? options[0]
    }

    var localizedTitle: String {
        powAILocalized(title)
    }
}

enum DayPlanRecurrence: String, CaseIterable, Identifiable, Codable {
    case none
    case daily
    case weekdays
    case weekends
    case weekly
    case custom

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .none: return powAILocalized("Does not repeat")
        case .daily: return powAILocalized("Every day")
        case .weekdays: return powAILocalized("Weekdays")
        case .weekends: return powAILocalized("Weekends")
        case .weekly: return powAILocalized("Every week")
        case .custom: return powAILocalized("Custom days")
        }
    }
}

struct DayPlanBlock: Codable, Equatable, Identifiable {
    static let appleCalendarCopyPrefix = "Copied from Apple Calendar:"

    var id: UUID
    var scheduledDate: String
    var title: String
    var notes: String?
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var category: String
    var reminderMinutesBefore: Int?
    var leaveReminderMinutesBefore: Int?
    var startAlarmEnabled: Bool
    var recurrence: String
    var repeatDays: [Int]
    var recurrenceEndDate: String?
    var isDone: Bool

    var categoryOption: DayPlanCategory {
        DayPlanCategory.option(for: category)
    }

    var startMinutes: Int {
        startHour * 60 + startMinute
    }

    var endMinutes: Int {
        endHour * 60 + endMinute
    }

    var timeText: String {
        "\(Self.timeString(hour: startHour, minute: startMinute)) - \(Self.timeString(hour: endHour, minute: endMinute))"
    }

    var durationText: String {
        let duration = max(0, endMinutes - startMinutes)
        if duration < 60 { return "\(duration)m" }
        let hours = duration / 60
        let minutes = duration % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var reminderText: String {
        guard let reminderMinutesBefore else { return powAILocalized("No reminder") }
        return reminderMinutesBefore == 0 ? powAILocalized("At start") : powAILocalizedFormat("%dm before", reminderMinutesBefore)
    }

    var recurrenceOption: DayPlanRecurrence {
        DayPlanRecurrence(rawValue: recurrence) ?? .none
    }

    var recurrenceText: String {
        switch recurrenceOption {
        case .none:
            return powAILocalized("Does not repeat")
        case .daily:
            return powAILocalized("Every day")
        case .weekdays:
            return powAILocalized("Weekdays")
        case .weekends:
            return powAILocalized("Weekends")
        case .weekly:
            return powAILocalizedFormat("Weekly on %@", repeatDaysText)
        case .custom:
            return repeatDays.isEmpty ? powAILocalized("Custom days") : repeatDaysText
        }
    }

    var leaveReminderText: String {
        guard let leaveReminderMinutesBefore else { return powAILocalized("No leave reminder") }
        return powAILocalizedFormat("Leave %dm before", leaveReminderMinutesBefore)
    }

    var repeatDaysText: String {
        let names = repeatDays.sorted().compactMap { Self.shortWeekdayName($0) }
        return names.isEmpty ? powAILocalized("No days") : names.joined(separator: ", ")
    }

    var isAllDayCalendarCopy: Bool {
        notes?.hasPrefix(Self.appleCalendarCopyPrefix) == true &&
        startHour == 0 &&
        startMinute == 0 &&
        endHour == 23 &&
        endMinute == 59
    }

    var displayNotes: String? {
        guard let notes, !notes.isEmpty else { return nil }
        guard notes.hasPrefix(Self.appleCalendarCopyPrefix) else { return notes }
        let calendarTitle = notes
            .dropFirst(Self.appleCalendarCopyPrefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return powAILocalizedFormat("Copied from Apple Calendar: %@", calendarTitle)
    }

    private static func timeString(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    static func shortWeekdayName(_ weekday: Int) -> String? {
        guard (1...7).contains(weekday) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return symbols[weekday - 1]
    }
}

struct DayPlanCalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let calendarTitle: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color

    var timeText: String {
        if isAllDay { return powAILocalized("All day") }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var durationText: String {
        if isAllDay { return powAILocalized("Calendar") }
        let minutes = max(1, Int(endDate.timeIntervalSince(startDate) / 60))
        if minutes >= 60 {
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
        }
        return "\(minutes)m"
    }
}

struct DayPlanSaveRequest: Encodable {
    var scheduledDate: String
    var title: String?
    var notes: String?
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var category: String?
    var reminderMinutesBefore: Int?
    var leaveReminderMinutesBefore: Int?
    var startAlarmEnabled: Bool?
    var recurrence: String?
    var repeatDays: [Int]?
    var recurrenceEndDate: String?
    var isDone: Bool?
}

struct DayPlanCompletionRequest: Encodable {
    var scheduledDate: String
    var isDone: Bool
}

enum DayPlanDeleteScope: String {
    case all
    case single
    case future
}

enum DayPlanScheduler {
    static func schedule(_ block: DayPlanBlock) {
        cancel(block)
        requestNotificationPermission()
        scheduleReminder(block)
        scheduleLeaveReminder(block)
        scheduleStartAlarm(block)
    }

    private static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Day plan notification permission error: \(error)")
            }
        }
    }

    private static func scheduleReminder(_ block: DayPlanBlock) {
        guard let reminder = block.reminderMinutesBefore else { return }
        let content = UNMutableNotificationContent()
        content.title = block.title
        content.body = "\(block.timeText) • \(block.categoryOption.title)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        scheduleNotifications(
            for: block,
            content: content,
            prefix: reminderNotificationPrefix(for: block),
            minutesBeforeStart: reminder
        )
    }

    private static func scheduleLeaveReminder(_ block: DayPlanBlock) {
        guard let leaveReminder = block.leaveReminderMinutesBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = powAILocalized("Leave now to be on time")
        content.body = "\(block.title) • \(block.timeText)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        scheduleNotifications(
            for: block,
            content: content,
            prefix: leaveReminderNotificationPrefix(for: block),
            minutesBeforeStart: leaveReminder
        )
    }

    private static func scheduleStartAlarm(_ block: DayPlanBlock) {
        guard block.startAlarmEnabled,
              let startDate = occurrenceStartDates(for: block, limit: 1).first else { return }

        let content = UNMutableNotificationContent()
        content.title = powAILocalizedFormat("Start: %@", block.title)
        content.body = powAILocalizedFormat("%@ • Keep moving with your plan.", block.timeText)
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        scheduleNotifications(
            for: block,
            content: content,
            prefix: startAlarmNotificationPrefix(for: block),
            minutesBeforeStart: 0
        )

        Task {
            do {
                try await scheduleStartSystemAlarm(block, startDate: startDate)
            } catch {
                print("Day plan AlarmKit scheduling failed; notification backup is still scheduled: \(error)")
            }
        }
    }

    static func cancel(_ block: DayPlanBlock) {
        let prefixes = [
            reminderNotificationPrefix(for: block),
            leaveReminderNotificationPrefix(for: block),
            startAlarmNotificationPrefix(for: block)
        ]
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { identifier in
                    prefixes.contains { identifier.hasPrefix($0) }
                }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }

        Task {
            cancelStartSystemAlarmIfPresent(block)
        }
    }

    private static func cancelStartSystemAlarmIfPresent(_ block: DayPlanBlock) {
        do {
            try AlarmManager.shared.cancel(id: block.id)
        } catch {
            // AlarmKit throws when the start alarm is already gone; notification cleanup above still runs.
        }
    }

    static func cancelOccurrence(_ block: DayPlanBlock) {
        var identifiers: [String] = []

        if let reminder = block.reminderMinutesBefore,
           let fireDate = occurrenceFireDate(for: block, minutesBeforeStart: reminder) {
            identifiers.append("\(reminderNotificationPrefix(for: block))-\(Int(fireDate.timeIntervalSince1970))")
        }

        if let leaveReminder = block.leaveReminderMinutesBefore,
           let fireDate = occurrenceFireDate(for: block, minutesBeforeStart: leaveReminder) {
            identifiers.append("\(leaveReminderNotificationPrefix(for: block))-\(Int(fireDate.timeIntervalSince1970))")
        }

        if block.startAlarmEnabled,
           let fireDate = occurrenceFireDate(for: block, minutesBeforeStart: 0) {
            identifiers.append("\(startAlarmNotificationPrefix(for: block))-\(Int(fireDate.timeIntervalSince1970))")
            cancelStartSystemAlarmIfPresent(block)
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func startDate(for block: DayPlanBlock, on date: Date) -> Date? {
        Calendar.current.date(
            bySettingHour: block.startHour,
            minute: block.startMinute,
            second: 0,
            of: date
        )
    }

    private static func startDate(for block: DayPlanBlock) -> Date? {
        guard let blockDate = DayPlanDateFormatter.date(from: block.scheduledDate) else { return nil }
        return startDate(for: block, on: blockDate)
    }

    private static func occurrenceFireDate(for block: DayPlanBlock, minutesBeforeStart: Int) -> Date? {
        guard let startDate = startDate(for: block) else { return nil }
        return Calendar.current.date(byAdding: .minute, value: -minutesBeforeStart, to: startDate)
    }

    private static func scheduleNotifications(
        for block: DayPlanBlock,
        content: UNMutableNotificationContent,
        prefix: String,
        minutesBeforeStart: Int
    ) {
        let fireDates = occurrenceStartDates(for: block, limit: 24).compactMap { startDate in
            Calendar.current.date(byAdding: .minute, value: -minutesBeforeStart, to: startDate)
        }
        let now = Date()

        for fireDate in fireDates where fireDate > now {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(prefix)-\(Int(fireDate.timeIntervalSince1970))",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Day plan notification scheduling failed: \(error)")
                }
            }
        }
    }

    private static func occurrenceStartDates(for block: DayPlanBlock, limit: Int) -> [Date] {
        guard let firstDate = DayPlanDateFormatter.date(from: block.scheduledDate) else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let recurrence = DayPlanRecurrence(rawValue: block.recurrence) ?? .none
        let endDate = block.recurrenceEndDate.flatMap(DayPlanDateFormatter.date(from:))
        let finalDay = endDate.map { calendar.startOfDay(for: $0) }
        var dates: [Date] = []

        func appendIfValid(_ date: Date) {
            guard let start = startDate(for: block, on: date), start > now else { return }
            if let finalDay, calendar.startOfDay(for: date) > finalDay { return }
            dates.append(start)
        }

        switch recurrence {
        case .none:
            appendIfValid(firstDate)
        case .daily, .weekdays, .weekends, .weekly, .custom:
            var cursor = calendar.startOfDay(for: firstDate)
            let weekdays = Set(block.repeatDays)
            var inspectedDays = 0
            while dates.count < limit, inspectedDays < 370 {
                defer {
                    cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
                    inspectedDays += 1
                }

                if let finalDay, cursor > finalDay { break }

                let weekday = calendar.component(.weekday, from: cursor)
                if recurrence == .daily || weekdays.contains(weekday) {
                    appendIfValid(cursor)
                }
            }
        }

        return dates
    }

    private static func scheduleStartSystemAlarm(_ block: DayPlanBlock, startDate: Date) async throws {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { throw URLError(.userAuthenticationRequired) }
        case .authorized:
            break
        case .denied:
            throw URLError(.userAuthenticationRequired)
        @unknown default:
            throw URLError(.unknown)
        }

        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "Start: \(block.title)"),
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.fill"
                )
            )
        )
        let attributes = AlarmAttributes<PowAIAlarmMetadata>(
            presentation: presentation,
            metadata: PowAIAlarmMetadata(alarmID: block.id.uuidString, title: block.title),
            tintColor: .cyan
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(startDate),
            attributes: attributes,
            sound: .default
        )
        _ = try await manager.schedule(id: block.id, configuration: configuration)
    }

    private static func reminderNotificationPrefix(for block: DayPlanBlock) -> String {
        "day-plan-reminder-\(block.id.uuidString)"
    }

    private static func leaveReminderNotificationPrefix(for block: DayPlanBlock) -> String {
        "day-plan-leave-\(block.id.uuidString)"
    }

    private static func startAlarmNotificationPrefix(for block: DayPlanBlock) -> String {
        "day-plan-start-alarm-\(block.id.uuidString)"
    }
}

enum DayPlanDateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}

@MainActor
final class DayPlanViewModel: ObservableObject {
    @Published var blocks: [DayPlanBlock] = []
    @Published var calendarEvents: [DayPlanCalendarEvent] = []
    @Published var isLoading = false
    @Published var isCalendarLoading = false
    @Published var message: String?
    @Published var calendarMessage: String?

    private let eventStore = EKEventStore()
    private static var cachedBlocksByDate: [String: [DayPlanBlock]] = [:]
    private static var cachedAtByDate: [String: Date] = [:]
    private static var loadTasksByDate: [String: Task<[DayPlanBlock], Error>] = [:]

    func applyServerBlocks(_ serverBlocks: [DayPlanBlock], for date: Date) {
        let dateString = DayPlanDateFormatter.string(from: date)
        let sorted = serverBlocks.sorted { ($0.startHour, $0.startMinute) < ($1.startHour, $1.startMinute) }
        blocks = sorted
        sorted.forEach { DayPlanScheduler.schedule($0) }
        message = sorted.isEmpty ? powAILocalized("No time blocks yet.") : nil
        Self.cachedBlocksByDate[dateString] = sorted
        Self.cachedAtByDate[dateString] = Date()
    }

    func load(for date: Date, force: Bool = false) async {
        let dateString = DayPlanDateFormatter.string(from: date)
        if !force,
           let cached = Self.cachedBlocksByDate[dateString],
           Self.isFresh(Self.cachedAtByDate[dateString]) {
            applyServerBlocks(cached, for: date)
            return
        }

        isLoading = blocks.isEmpty
        defer { isLoading = false }

        do {
            let serverBlocks: [DayPlanBlock]
            if let loadTask = Self.loadTasksByDate[dateString] {
                serverBlocks = try await loadTask.value
            } else {
                let task = Task { try await Self.fetchBlocks(for: dateString) }
                Self.loadTasksByDate[dateString] = task
                defer { Self.loadTasksByDate[dateString] = nil }
                serverBlocks = try await task.value
            }
            applyServerBlocks(serverBlocks, for: date)
        } catch {
            message = powAILocalized("Could not load day plan.")
            print("Load day plan failed: \(error)")
        }
    }

    func loadCalendarEvents(for date: Date) async {
        isCalendarLoading = true
        defer { isCalendarLoading = false }

        do {
            guard try await ensureCalendarAccess() else {
                calendarEvents = []
                calendarMessage = powAILocalized("Calendar access is needed to show Apple Calendar events.")
                return
            }

            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: date)
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? date
            let predicate = eventStore.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: nil
            )

            calendarEvents = eventStore.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
                .map { event in
                    DayPlanCalendarEvent(
                        id: event.eventIdentifier ?? "\(event.title ?? "event")-\(event.startDate.timeIntervalSince1970)",
                        title: event.title?.isEmpty == false ? event.title : powAILocalized("Untitled event"),
                        calendarTitle: event.calendar.title,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        isAllDay: event.isAllDay,
                        color: Color(cgColor: event.calendar.cgColor)
                    )
                }
            calendarMessage = calendarEvents.isEmpty ? powAILocalized("No Apple Calendar events on this date.") : nil
        } catch {
            calendarEvents = []
            calendarMessage = powAILocalized("Could not load Apple Calendar events.")
            print("Load Apple Calendar events failed: \(error)")
        }
    }

    func clearCalendarEvents() {
        calendarEvents = []
        calendarMessage = nil
    }

    func save(existing: DayPlanBlock?, request payload: DayPlanSaveRequest) async {
        do {
            var request = try makeRequest(path: existing.map { "day-schedule/\($0.id.uuidString)" } ?? "day-schedule")
            request.httpMethod = existing == nil ? "POST" : "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let saved = try JSONDecoder().decode(DayPlanBlock.self, from: data)
            if let existing {
                DayPlanScheduler.cancel(existing)
            }
            if let index = blocks.firstIndex(where: { $0.id == saved.id }) {
                blocks[index] = saved
            } else {
                blocks.append(saved)
            }
            blocks.sort { ($0.startHour, $0.startMinute) < ($1.startHour, $1.startMinute) }
            Self.cachedBlocksByDate[saved.scheduledDate] = blocks
            Self.cachedAtByDate[saved.scheduledDate] = Date()
            DayPlanScheduler.schedule(saved)
            message = nil
        } catch {
            message = powAILocalized("Could not save time block.")
            print("Save day plan failed: \(error)")
        }
    }

    func delete(_ block: DayPlanBlock, scope: DayPlanDeleteScope = .all) async {
        do {
            var path = "day-schedule/\(block.id.uuidString)"
            if block.recurrenceOption != .none, scope != .all {
                path += "?scope=\(scope.rawValue)&date=\(block.scheduledDate)"
            }

            var request = try makeRequest(path: path)
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            switch scope {
            case .single:
                blocks.removeAll { $0.id == block.id && $0.scheduledDate == block.scheduledDate }
                Self.cachedBlocksByDate[block.scheduledDate] = blocks
                DayPlanScheduler.cancelOccurrence(block)
            case .future:
                blocks.removeAll { $0.id == block.id }
                Self.removeCachedBlocks(matching: block, onOrAfter: block.scheduledDate)
                DayPlanScheduler.cancel(block)
            case .all:
                blocks.removeAll { $0.id == block.id }
                Self.removeCachedBlocks(matching: block, onOrAfter: nil)
                DayPlanScheduler.cancel(block)
            }

            Self.cachedAtByDate[block.scheduledDate] = Date()
            message = blocks.isEmpty ? powAILocalized("No time blocks yet.") : nil
        } catch {
            message = powAILocalized("Could not delete time block.")
            print("Delete day plan failed: \(error)")
        }
    }

    func setDone(_ block: DayPlanBlock, isDone: Bool) async {
        do {
            var request = try makeRequest(path: "day-schedule/\(block.id.uuidString)/completion")
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(
                DayPlanCompletionRequest(scheduledDate: block.scheduledDate, isDone: isDone)
            )

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let saved = try JSONDecoder().decode(DayPlanBlock.self, from: data)
            if let index = blocks.firstIndex(where: { $0.id == saved.id && $0.scheduledDate == saved.scheduledDate }) {
                blocks[index] = saved
            } else if let index = blocks.firstIndex(where: { $0.id == saved.id }) {
                blocks[index] = saved
            }
            Self.cachedBlocksByDate[saved.scheduledDate] = blocks
            Self.cachedAtByDate[saved.scheduledDate] = Date()
            message = nil
        } catch {
            message = powAILocalized("Could not save time block.")
            print("Save day plan completion failed: \(error)")
        }
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.applyBearerToken()
        return request
    }

    private static func fetchBlocks(for dateString: String) async throws -> [DayPlanBlock] {
        var components = URLComponents(string: Constants.baseURL + "day-schedule")
        components?.queryItems = [URLQueryItem(name: "date", value: dateString)]
        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.applyBearerToken()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([DayPlanBlock].self, from: data)
    }

    private static func isFresh(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) < 20
    }

    private static func removeCachedBlocks(matching block: DayPlanBlock, onOrAfter date: String?) {
        for key in cachedBlocksByDate.keys {
            if let date, key < date { continue }
            cachedBlocksByDate[key]?.removeAll { $0.id == block.id }
            cachedAtByDate[key] = Date()
        }
    }

    private func ensureCalendarAccess() async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            return true
        case .notDetermined, .writeOnly:
            return try await requestCalendarFullAccess()
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func requestCalendarFullAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

struct DayPlanView: View {
    @ObservedObject var viewModel: DayPlanViewModel
    @State private var selectedDate = Date()
    @State private var editingBlock: DayPlanBlock?
    @State private var sharingBlock: DayPlanBlock?
    @State private var pendingDeleteBlock: DayPlanBlock?
    @State private var showingEditor = false
    @State private var showingCalendarEvents = false
    @State private var showingDeleteOptions = false
    let loadOnAppear: Bool
    private let liveActivityTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(viewModel: DayPlanViewModel, loadOnAppear: Bool = true) {
        self.viewModel = viewModel
        self.loadOnAppear = loadOnAppear
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                dateControls
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)

                calendarPullButton
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(PowAI.cyan)
                        .scaleEffect(1.3)
                    Spacer()
                } else {
                    planList
                }
            }
        }
        .task {
            if loadOnAppear {
                await viewModel.load(for: selectedDate)
            }
            updateDayPlanLiveActivity()
        }
        .onChange(of: selectedDate) { _, newDate in
            Task {
                await viewModel.load(for: newDate)
                if showingCalendarEvents {
                    await viewModel.loadCalendarEvents(for: newDate)
                }
                updateDayPlanLiveActivity()
            }
        }
        .onChange(of: viewModel.blocks) { _, _ in
            updateDayPlanLiveActivity()
        }
        .onReceive(liveActivityTimer) { _ in
            updateDayPlanLiveActivity()
        }
        .sheet(isPresented: $showingEditor) {
            DayPlanEditorView(date: selectedDate, block: editingBlock) { payload in
                await viewModel.save(existing: editingBlock, request: payload)
                showingEditor = false
            }
        }
        .sheet(item: $sharingBlock) { block in
            FriendSharePickerView(
                title: powAILocalized("Share Event"),
                target: .dayPlan(block.id)
            )
        }
        .confirmationDialog(
            powAILocalized("Delete Repeating Event?"),
            isPresented: $showingDeleteOptions,
            titleVisibility: .visible,
            presenting: pendingDeleteBlock
        ) { block in
            Button(powAILocalized("Only This Day"), role: .destructive) {
                Task { await viewModel.delete(block, scope: .single) }
                pendingDeleteBlock = nil
            }
            Button(powAILocalized("This and Future Days"), role: .destructive) {
                Task { await viewModel.delete(block, scope: .future) }
                pendingDeleteBlock = nil
            }
            Button(powAILocalized("Cancel"), role: .cancel) {
                pendingDeleteBlock = nil
            }
        } message: { _ in
            Text(powAILocalized("Choose how much of this repeating event to remove."))
        }
    }

    private func updateDayPlanLiveActivity() {
        LiveActivityManager.shared.updateDayPlan(
            blocks: viewModel.blocks,
            date: selectedDate
        )
    }

    private func importCalendarEvent(_ event: DayPlanCalendarEvent) async {
        let payload = calendarEventPayload(for: event)
        await viewModel.save(existing: nil, request: payload)
    }

    private func calendarEventPayload(for event: DayPlanCalendarEvent) -> DayPlanSaveRequest {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let dayLastMinute = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: dayStart) ?? dayEnd
        let startDate = event.isAllDay ? dayStart : max(event.startDate, dayStart)
        let rawEndDate = event.isAllDay ? dayLastMinute : min(event.endDate, dayEnd)
        let endDate = rawEndDate >= dayEnd ? dayLastMinute : rawEndDate
        let fallbackEndDate = calendar.date(byAdding: .minute, value: 30, to: startDate) ?? startDate
        let safeEndDate = endDate > startDate ? endDate : min(fallbackEndDate, dayLastMinute)
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: safeEndDate)

        return DayPlanSaveRequest(
            scheduledDate: DayPlanDateFormatter.string(from: selectedDate),
            title: event.title,
            notes: "\(DayPlanBlock.appleCalendarCopyPrefix) \(event.calendarTitle)",
            startHour: startComponents.hour ?? 0,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 23,
            endMinute: endComponents.minute ?? 59,
            category: "personal",
            reminderMinutesBefore: nil,
            leaveReminderMinutesBefore: nil,
            startAlarmEnabled: false,
            recurrence: "none",
            repeatDays: [],
            recurrenceEndDate: nil,
            isDone: false
        )
    }

    private func isCalendarEventImported(_ event: DayPlanCalendarEvent) -> Bool {
        let payload = calendarEventPayload(for: event)
        return viewModel.blocks.contains { block in
            block.title == payload.title &&
            block.notes == payload.notes &&
            block.startHour == payload.startHour &&
            block.startMinute == payload.startMinute &&
            block.endHour == payload.endHour &&
            block.endMinute == payload.endMinute
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(powAILocalized("Day Plan"))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(powAILocalized("Block time · Stay visible"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                Text(powAILocalized("Plan your day by time blocks, with optional start alarms and Live Activity updates."))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PowAI.slate.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                editingBlock = nil
                showingEditor = true
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [PowAI.cyan, PowAI.cyan.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .shadow(color: PowAI.cyan.opacity(0.4), radius: 10, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var dateControls: some View {
        HStack(spacing: 10) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PowAI.slateLight)
                    .frame(width: 40, height: 40)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
            }

            Button {
                selectedDate = Date()
            } label: {
                let isToday = Calendar.current.isDateInToday(selectedDate)
                VStack(spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text(isToday ? powAILocalized("Today") : selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isToday ? PowAI.cyan : PowAI.slate)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isToday ? PowAI.cyan.opacity(0.3) : .clear, lineWidth: 1)
                )
            }

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PowAI.slateLight)
                    .frame(width: 40, height: 40)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var calendarPullButton: some View {
        Button {
            Task {
                if showingCalendarEvents {
                    showingCalendarEvents = false
                    viewModel.clearCalendarEvents()
                } else {
                    showingCalendarEvents = true
                    await viewModel.loadCalendarEvents(for: selectedDate)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showingCalendarEvents ? "calendar.badge.minus" : "calendar.badge.plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PowAI.cyan)

                Text(powAILocalized(showingCalendarEvents ? "Hide Apple Calendar" : "Show Apple Calendar"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if viewModel.isCalendarLoading {
                    ProgressView()
                        .tint(PowAI.cyan)
                        .scaleEffect(0.75)
                } else if showingCalendarEvents, !viewModel.calendarEvents.isEmpty {
                    Text("\(viewModel.calendarEvents.count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PowAI.cyan, in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(showingCalendarEvents ? PowAI.cyan.opacity(0.3) : PowAI.slate.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var planList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if showingCalendarEvents {
                    calendarEventsSection
                }

                if let message = viewModel.message {
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40, weight: .thin))
                            .foregroundStyle(PowAI.slate)
                        Text(message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PowAI.slate)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }

                ForEach(viewModel.blocks) { block in
                    DayPlanRowView(
                        block: block,
                        onToggle: { isDone in
                            Task { await viewModel.setDone(block, isDone: isDone) }
                        },
                        onEdit: {
                            editingBlock = block
                            showingEditor = true
                        },
                        onDelete: {
                            if block.recurrenceOption == .none {
                                Task { await viewModel.delete(block) }
                            } else {
                                pendingDeleteBlock = block
                                showingDeleteOptions = true
                            }
                        },
                        onShare: {
                            sharingBlock = block
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
    }

    private var calendarEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PowAISectionLabel(text: powAILocalized("Apple Calendar"))
                Spacer()
                if !viewModel.calendarEvents.isEmpty {
                    Button {
                        Task { await viewModel.loadCalendarEvents(for: selectedDate) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(PowAI.cyan)
                            .frame(width: 28, height: 28)
                            .background(PowAI.cyan.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)

            if viewModel.isCalendarLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(PowAI.cyan)
                    Text(powAILocalized("Loading Apple Calendar events..."))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PowAI.slate)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
            } else if let calendarMessage = viewModel.calendarMessage {
                Text(calendarMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(viewModel.calendarEvents) { event in
                    DayPlanCalendarEventRowView(
                        event: event,
                        isImported: isCalendarEventImported(event),
                        canImport: !event.isAllDay,
                        onImport: {
                            Task { await importCalendarEvent(event) }
                        }
                    )
                }
            }
        }
    }
}

struct DayPlanCalendarEventRowView: View {
    let event: DayPlanCalendarEvent
    let isImported: Bool
    let canImport: Bool
    let onImport: () -> Void

    var body: some View {
        PowAICard(accentColor: event.color) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.color.opacity(0.85))
                    .frame(width: 3)
                    .padding(.vertical, 16)

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: event.isAllDay ? "calendar" : "calendar.badge.clock")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(event.color)
                        .frame(width: 30, height: 30)
                        .background(event.color.opacity(0.12), in: Circle())
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(event.timeText)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(PowAI.slate)

                            Text(event.durationText)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(event.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(event.color.opacity(0.12), in: Capsule())
                        }

                        Text(event.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        PowAIChip(label: event.calendarTitle, icon: "calendar", color: event.color)
                    }

                    Spacer()

                    Button {
                        if canImport {
                            onImport()
                        }
                    } label: {
                        Image(systemName: event.isAllDay ? "calendar" : (isImported ? "checkmark" : "plus"))
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(isImported || event.isAllDay ? .black : .white)
                            .frame(width: 34, height: 34)
                            .background(event.isAllDay ? PowAI.slateLight : (isImported ? PowAI.green : PowAI.cyan), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isImported || !canImport)
                    .accessibilityLabel(powAILocalized(event.isAllDay ? "All-day calendar event" : (isImported ? "Added to Day Plan" : "Add to Day Plan")))
                }
                .padding(16)
            }
        }
    }
}

struct DayPlanRowView: View {
    let block: DayPlanBlock
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        let category = block.categoryOption

        PowAICard(accentColor: category.color) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [category.color, category.color.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 3)
                    .padding(.vertical, 12)

                HStack(alignment: .top, spacing: 12) {
                    Button { onToggle(!block.isDone) } label: {
                        ZStack {
                            Circle()
                                .stroke(block.isDone ? category.color : PowAI.slate.opacity(0.4), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            if block.isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(category.color)
                            }
                        }
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(block.timeText)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(PowAI.slate)

                            Text(block.durationText)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(category.color)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(category.color.opacity(0.12), in: Capsule())
                        }

                        Text(block.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(block.isDone ? PowAI.slate : .white)
                            .strikethrough(block.isDone, color: PowAI.slate)
                            .lineLimit(2)

                        if let notes = block.displayNotes {
                            Text(notes)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(PowAI.slate)
                                .lineLimit(1)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                PowAIChip(label: category.localizedTitle, icon: category.icon, color: category.color)
                                PowAIChip(label: block.reminderText, icon: "bell.fill", color: PowAI.slate)
                                if block.recurrenceOption != .none {
                                    PowAIChip(label: block.recurrenceText, icon: "repeat", color: PowAI.cyan)
                                }
                                if block.leaveReminderMinutesBefore != nil {
                                    PowAIChip(label: block.leaveReminderText, icon: "figure.walk", color: PowAI.green)
                                }
                                if block.startAlarmEnabled {
                                    PowAIChip(label: powAILocalized("Alarm"), icon: "alarm.fill", color: PowAI.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button(powAILocalized("Share"), systemImage: "square.and.arrow.up", action: onShare)
                        Button(powAILocalized("Edit"), systemImage: "pencil", action: onEdit)
                        Button(powAILocalized("Delete"), systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PowAI.slate)
                            .frame(width: 30, height: 30)
                            .background(PowAI.surface, in: Circle())
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
            }
        }
    }
}

struct DayPlanEditorView: View {
    let date: Date
    let block: DayPlanBlock?
    let onSave: (DayPlanSaveRequest) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var notes: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var category: String
    @State private var reminderMinutesBefore: Int?
    @State private var leaveReminderMinutesBefore: Int?
    @State private var startAlarmEnabled: Bool
    @State private var recurrence: DayPlanRecurrence
    @State private var selectedRepeatDays: Set<Int>
    @State private var hasRecurrenceEndDate: Bool
    @State private var recurrenceEndDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(date: Date, block: DayPlanBlock?, onSave: @escaping (DayPlanSaveRequest) async -> Void) {
        self.date = date
        self.block = block
        self.onSave = onSave

        let calendar = Calendar.current
        let defaultStart = calendar.date(
            bySettingHour: calendar.component(.hour, from: Date()),
            minute: 0,
            second: 0,
            of: date
        ) ?? date
        let defaultEnd = calendar.date(byAdding: .minute, value: 30, to: defaultStart) ?? defaultStart

        _title = State(initialValue: block?.title ?? "")
        _notes = State(initialValue: block?.notes ?? "")
        _startTime = State(initialValue: block.flatMap {
            calendar.date(bySettingHour: $0.startHour, minute: $0.startMinute, second: 0, of: date)
        } ?? defaultStart)
        _endTime = State(initialValue: block.flatMap {
            calendar.date(bySettingHour: $0.endHour, minute: $0.endMinute, second: 0, of: date)
        } ?? defaultEnd)
        _category = State(initialValue: block?.category ?? "focus")
        _reminderMinutesBefore = State(initialValue: block?.reminderMinutesBefore)
        _leaveReminderMinutesBefore = State(initialValue: block?.leaveReminderMinutesBefore)
        _startAlarmEnabled = State(initialValue: block?.startAlarmEnabled ?? false)
        let initialRecurrence = DayPlanRecurrence(rawValue: block?.recurrence ?? "none") ?? .none
        _recurrence = State(initialValue: initialRecurrence)
        let weekday = calendar.component(.weekday, from: date)
        _selectedRepeatDays = State(initialValue: Set(block?.repeatDays.isEmpty == false ? block?.repeatDays ?? [weekday] : [weekday]))
        let initialEndDate = block?.recurrenceEndDate.flatMap(DayPlanDateFormatter.date(from:)) ?? date
        _hasRecurrenceEndDate = State(initialValue: block?.recurrenceEndDate != nil)
        _recurrenceEndDate = State(initialValue: initialEndDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(powAILocalized("What")) {
                    TextField(powAILocalized("Task, class, errand, workout..."), text: $title)
                    TextField(powAILocalized("Notes"), text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section(powAILocalized("When")) {
                    DatePicker(powAILocalized("Start"), selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker(powAILocalized("End"), selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section(powAILocalized("Type")) {
                    Picker(powAILocalized("Category"), selection: $category) {
                        ForEach(DayPlanCategory.options) { option in
                            Label(option.localizedTitle, systemImage: option.icon).tag(option.id)
                        }
                    }
                }

                Section(powAILocalized("Reminder")) {
                    Picker(powAILocalized("Reminder"), selection: $reminderMinutesBefore) {
                        Text(powAILocalized("None")).tag(nil as Int?)
                        Text(powAILocalized("At start")).tag(0 as Int?)
                        Text(powAILocalized("5 min before")).tag(5 as Int?)
                        Text(powAILocalized("10 min before")).tag(10 as Int?)
                        Text(powAILocalized("15 min before")).tag(15 as Int?)
                        Text(powAILocalized("30 min before")).tag(30 as Int?)
                        Text(powAILocalized("1 hour before")).tag(60 as Int?)
                    }

                    Toggle(isOn: $startAlarmEnabled) {
                        Label(powAILocalized("Alarm at start"), systemImage: "alarm.fill")
                    }
                }

                Section(powAILocalized("Repeat")) {
                    Picker(powAILocalized("Repeat"), selection: $recurrence) {
                        ForEach(DayPlanRecurrence.allCases) { option in
                            Text(option.localizedTitle).tag(option)
                        }
                    }

                    if recurrence == .custom {
                        weekdayPicker
                    }

                    if recurrence != .none {
                        Toggle(isOn: $hasRecurrenceEndDate) {
                            Text(powAILocalized("Ends on date"))
                        }

                        if hasRecurrenceEndDate {
                            DatePicker(
                                powAILocalized("End repeat"),
                                selection: $recurrenceEndDate,
                                displayedComponents: .date
                            )
                        }
                    }
                }

                Section(powAILocalized("Travel time")) {
                    Picker(powAILocalized("Leave reminder"), selection: $leaveReminderMinutesBefore) {
                        Text(powAILocalized("None")).tag(nil as Int?)
                        Text(powAILocalized("5 min before")).tag(5 as Int?)
                        Text(powAILocalized("10 min before")).tag(10 as Int?)
                        Text(powAILocalized("15 min before")).tag(15 as Int?)
                        Text(powAILocalized("20 min before")).tag(20 as Int?)
                        Text(powAILocalized("30 min before")).tag(30 as Int?)
                        Text(powAILocalized("45 min before")).tag(45 as Int?)
                        Text(powAILocalized("1 hour before")).tag(60 as Int?)
                        Text(powAILocalized("90 min before")).tag(90 as Int?)
                        Text(powAILocalized("2 hours before")).tag(120 as Int?)
                    }
                    Text(powAILocalized("PowAI will remind you when you need to leave so you can arrive on time."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(powAILocalized(block == nil ? "New Time Block" : "Edit Time Block"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(powAILocalized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(powAILocalized(isSaving ? "Saving..." : "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var weekdayPicker: some View {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let weekdaySymbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { weekday in
                Button {
                    if selectedRepeatDays.contains(weekday) {
                        selectedRepeatDays.remove(weekday)
                    } else {
                        selectedRepeatDays.insert(weekday)
                    }
                } label: {
                    Text(weekdaySymbols[weekday - 1])
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedRepeatDays.contains(weekday) ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedRepeatDays.contains(weekday) ? Color.accentColor : Color.secondary.opacity(0.14),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = powAILocalized("Title is required.")
            return
        }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let startHour = startComponents.hour ?? 0
        let startMinute = startComponents.minute ?? 0
        let endHour = endComponents.hour ?? 0
        let endMinute = endComponents.minute ?? 0

        guard (endHour * 60 + endMinute) > (startHour * 60 + startMinute) else {
            errorMessage = powAILocalized("End time must be after start time.")
            return
        }

        let repeatDays = repeatDaysForPayload(calendar: calendar)
        if recurrence == .custom, repeatDays.isEmpty {
            errorMessage = powAILocalized("Choose at least one repeat day.")
            return
        }

        isSaving = true
        defer { isSaving = false }

        let payload = DayPlanSaveRequest(
            scheduledDate: DayPlanDateFormatter.string(from: date),
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            category: category,
            reminderMinutesBefore: reminderMinutesBefore,
            leaveReminderMinutesBefore: leaveReminderMinutesBefore,
            startAlarmEnabled: startAlarmEnabled,
            recurrence: recurrence.rawValue,
            repeatDays: repeatDays,
            recurrenceEndDate: recurrence != .none && hasRecurrenceEndDate ? DayPlanDateFormatter.string(from: recurrenceEndDate) : nil,
            isDone: block?.isDone ?? false
        )

        await onSave(payload)
    }

    private func repeatDaysForPayload(calendar: Calendar) -> [Int] {
        switch recurrence {
        case .none:
            return []
        case .daily:
            return Array(1...7)
        case .weekdays:
            return Array(2...6)
        case .weekends:
            return [1, 7]
        case .weekly:
            return [calendar.component(.weekday, from: startTime)]
        case .custom:
            return selectedRepeatDays.sorted()
        }
    }
}

struct AlarmRowView: View {
    let alarm: AlarmItem
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        PowAICard {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(alarm.isEnabled
                        ? PowAI.orangeGlow
                        : LinearGradient(colors: [PowAI.slate.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(alarmHour)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                            Text(":")
                                .font(.system(size: 31, weight: .black, design: .rounded))
                                .offset(y: -3)
                            Text(alarmMinute)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                            Text(alarmPeriod)
                                .font(.system(size: 14, weight: .bold))
                                .offset(y: -6)
                        }
                        .foregroundStyle(alarm.isEnabled ? .white : PowAI.slate)

                        Spacer()

                        Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: onToggle))
                            .labelsHidden()
                            .tint(PowAI.orange)
                            .scaleEffect(0.82)
                    }

                    Text(alarm.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(alarm.isEnabled ? PowAI.slateLight : PowAI.slate)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            PowAIChip(label: alarm.missionText, icon: "bolt.fill", color: PowAI.orange)
                            PowAIChip(label: alarm.repeatText, icon: "repeat", color: PowAI.slate)
                            PowAIChip(label: alarm.soundText, icon: alarm.soundOption.systemImage, color: PowAI.slate)
                            if alarm.hidesSnoozeButton {
                                PowAIChip(label: powAILocalized("No snooze"), icon: "bell.slash.fill", color: PowAI.orange)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Spacer()
                        Button(action: onEdit) {
                            Label(powAILocalized("Edit"), systemImage: "pencil")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(PowAI.slateLight)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(PowAI.surface, in: Capsule())
                        }
                        Button(action: onDelete) {
                            Label(powAILocalized("Delete"), systemImage: "trash")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.85))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 16)
                .padding(.vertical, 13)
            }
        }
    }

    private var alarmHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        return formatter.string(from: Calendar.current.date(from: components) ?? Date())
    }

    private var alarmMinute: String {
        String(format: "%02d", alarm.minute)
    }

    private var alarmPeriod: String {
        alarm.hour < 12 ? "AM" : "PM"
    }
}

struct AlarmEditorView: View {
    let alarm: AlarmItem?
    let onSave: (AlarmSaveRequest) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var selectedTime: Date
    @State private var selectedDays: Set<Int>
    @State private var selectedMissions: Set<String>
    @State private var difficulty: String
    @State private var barcodeValue: String
    @State private var typingPhrase: String
    @State private var wakeCheckEnabled: Bool
    @State private var wakeCheckMinutes: Int
    @State private var alarmSound: String
    @State private var softAwakeningEnabled: Bool
    @State private var hideSnoozeButton: Bool
    @State private var isSaving = false
    @State private var showBarcodeScanner = false
    @State private var editorError: String?

    private let weekdays = Array(1...7)
    private let difficulties = ["easy", "medium", "hard"]
    private let missions: [(id: String, title: String, icon: String)] = [
        ("math", "Math", "function"),
        ("typing", "Typing", "keyboard"),
        ("memory", "Memory", "brain.head.profile"),
        ("barcode", "QR/Barcode", "barcode.viewfinder")
    ]

    init(alarm: AlarmItem?, onSave: @escaping (AlarmSaveRequest) async -> Void) {
        self.alarm = alarm
        self.onSave = onSave
        _title = State(initialValue: alarm?.title ?? powAILocalized("Wake up"))
        _selectedDays = State(initialValue: Set(alarm?.repeatDays ?? Array(1...7)))
        _selectedMissions = State(initialValue: Set(alarm?.missions ?? ["math"]))
        _difficulty = State(initialValue: alarm?.difficulty ?? "medium")
        _barcodeValue = State(initialValue: alarm?.barcodeValue ?? "")
        _typingPhrase = State(initialValue: alarm?.typingPhrase ?? powAILocalized("I am awake and ready"))
        _wakeCheckEnabled = State(initialValue: (alarm?.wakeCheckMinutes ?? 0) > 0)
        _wakeCheckMinutes = State(initialValue: alarm?.wakeCheckMinutes ?? 5)
        _alarmSound = State(initialValue: alarm?.soundOption.id ?? "default")
        _softAwakeningEnabled = State(initialValue: alarm?.usesSoftAwakening ?? false)
        _hideSnoozeButton = State(initialValue: alarm?.hidesSnoozeButton ?? false)

        var components = DateComponents()
        components.hour = alarm?.hour ?? 7
        components.minute = alarm?.minute ?? 0
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        DatePicker(powAILocalized("Time"), selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(powAILocalized("Name"))
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                            TextField(powAILocalized("Wake up"), text: $title)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(powAILocalized("Sound"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)

                                Spacer()

                                Button {
                                    AlarmSoundPreviewer.play(AlarmSoundOption.option(for: alarmSound))
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 38, height: 38)
                                        .background(Color.white.opacity(0.12), in: Circle())
                                }
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(AlarmSoundOption.options) { sound in
                                    soundButton(sound)
                                }
                            }

                            Toggle(powAILocalized("Soft awakening"), isOn: $softAwakeningEnabled)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .tint(.orange)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(powAILocalized("Repeat"))
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            HStack(spacing: 8) {
                                ForEach(weekdays, id: \.self) { day in
                                    dayButton(day)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(powAILocalized("Missions"))
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(missions, id: \.id) { mission in
                                    missionButton(mission)
                                }
                            }
                        }

                        if selectedMissions.contains("barcode") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(powAILocalized("Registered QR or barcode"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)

                                HStack(spacing: 10) {
                                    TextField(powAILocalized("Scan or paste code"), text: $barcodeValue)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(.white)
                                        .padding(14)
                                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                                    Button {
                                        showBarcodeScanner = true
                                    } label: {
                                        Image(systemName: "barcode.viewfinder")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .frame(width: 48, height: 48)
                                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }

                        if selectedMissions.contains("typing") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(powAILocalized("Typing phrase"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)

                                TextField(powAILocalized("I am awake and ready"), text: $typingPhrase)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(powAILocalized("Difficulty"))
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            Picker(powAILocalized("Difficulty"), selection: $difficulty) {
                                ForEach(difficulties, id: \.self) { option in
                                    Text(powAILocalized(option.capitalized)).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(powAILocalized("Hide snooze button"), isOn: $hideSnoozeButton)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .tint(.orange)

                            Toggle(powAILocalized("Wake-up check"), isOn: $wakeCheckEnabled)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .tint(.orange)

                            if wakeCheckEnabled {
                                Stepper(powAILocalizedFormat("%d minutes after dismiss", wakeCheckMinutes), value: $wakeCheckMinutes, in: 1...30)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }

                        if let editorError {
                            Text(editorError)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.95))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(powAILocalized(alarm == nil ? "New Alarm" : "Edit Alarm"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(powAILocalized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(powAILocalized(isSaving ? "Saving" : "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { code in
                    barcodeValue = code
                    showBarcodeScanner = false
                }
            }
        }
    }

    private func dayButton(_ day: Int) -> some View {
        let symbol = Calendar.current.veryShortWeekdaySymbols[day - 1]
        let isSelected = selectedDays.contains(day)
        return Button {
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(symbol)
                .font(.headline.bold())
                .foregroundStyle(isSelected ? .black : .white)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.orange : Color.white.opacity(0.12), in: Circle())
        }
    }

    private func missionButton(_ mission: (id: String, title: String, icon: String)) -> some View {
        let isSelected = selectedMissions.contains(mission.id)
        return Button {
            if isSelected, selectedMissions.count > 1 {
                selectedMissions.remove(mission.id)
            } else {
                selectedMissions.insert(mission.id)
            }
        } label: {
            Label(powAILocalized(mission.title), systemImage: mission.icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isSelected ? Color.orange : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func save() async {
        editorError = nil
        let orderedMissions = missions.map(\.id).filter { selectedMissions.contains($0) }
        if orderedMissions.contains("barcode"), barcodeValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editorError = powAILocalized("Scan or paste a QR/barcode before saving.")
            return
        }

        isSaving = true
        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        let payload = AlarmSaveRequest(
            title: title,
            hour: components.hour ?? 7,
            minute: components.minute ?? 0,
            repeatDays: selectedDays.sorted(),
            challengeType: orderedMissions.first ?? "math",
            challengeTypes: orderedMissions,
            difficulty: difficulty,
            barcodeValue: barcodeValue.trimmingCharacters(in: .whitespacesAndNewlines),
            typingPhrase: typingPhrase.trimmingCharacters(in: .whitespacesAndNewlines),
            wakeCheckMinutes: wakeCheckEnabled ? wakeCheckMinutes : nil,
            alarmSound: alarmSound,
            softAwakeningEnabled: softAwakeningEnabled,
            hideSnoozeButton: hideSnoozeButton,
            isEnabled: alarm?.isEnabled ?? true
        )
        await onSave(payload)
        isSaving = false
    }

    private func soundButton(_ sound: AlarmSoundOption) -> some View {
        let isSelected = alarmSound == sound.id
        return Button {
            alarmSound = sound.id
        } label: {
            Label(sound.localizedTitle, systemImage: sound.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isSelected ? Color.orange : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ActiveAlarmView: View {
    let alarm: AlarmItem
    @ObservedObject private var runtime = AlarmRuntime.shared
    @State private var missionIndex = 0
    @State private var answer = ""
    @State private var memorySequence = ""
    @State private var showMemorySequence = true
    @State private var showBarcodeScanner = false
    @State private var errorText: String?

    private var currentMission: String {
        let missions = alarm.missions
        guard missions.indices.contains(missionIndex) else { return "math" }
        return missions[missionIndex]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.red.opacity(0.85), Color.orange.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text(alarm.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(alarm.timeText)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 14) {
                    Text(powAILocalizedFormat("Mission %d of %d", missionIndex + 1, alarm.missions.count))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))

                    missionContent

                    if let errorText {
                        Text(errorText)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(20)

                Button {
                    submit()
                } label: {
                    Text(powAILocalized(missionIndex == alarm.missions.count - 1 ? "Turn Off Alarm" : "Next Mission"))
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(26)
        }
        .onAppear {
            runtime.activate(alarm)
            startCurrentMission()
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView { code in
                answer = code
                showBarcodeScanner = false
                submit()
            }
        }
    }

    @ViewBuilder
    private var missionContent: some View {
        switch currentMission {
        case "typing":
            Text(alarm.typingPhrase?.isEmpty == false ? alarm.typingPhrase! : powAILocalized("I am awake and ready"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            TextField(powAILocalized("Type the phrase exactly"), text: $answer)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))

        case "memory":
            Text(showMemorySequence ? memorySequence : powAILocalized("Enter the sequence"))
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            TextField(powAILocalized("Sequence"), text: $answer)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))

        case "barcode":
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(.white)

            Text(powAILocalized("Scan the registered QR code or barcode."))
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Button {
                showBarcodeScanner = true
            } label: {
                Label(powAILocalized("Scan Code"), systemImage: "camera.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            }

        default:
            Text(runtime.challenge.prompt)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            TextField(powAILocalized("Answer"), text: $answer)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func startCurrentMission() {
        answer = ""
        errorText = nil

        switch currentMission {
        case "math":
            runtime.challenge = MathChallenge.generate(difficulty: alarm.difficulty)
        case "memory":
            memorySequence = Self.generateMemorySequence(difficulty: alarm.difficulty)
            showMemorySequence = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                showMemorySequence = false
            }
        default:
            break
        }
    }

    private func submit() {
        let normalizedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect: Bool

        switch currentMission {
        case "typing":
            let phrase = alarm.typingPhrase?.trimmingCharacters(in: .whitespacesAndNewlines)
            isCorrect = normalizedAnswer == (phrase?.isEmpty == false ? phrase! : powAILocalized("I am awake and ready"))
        case "memory":
            isCorrect = normalizedAnswer == memorySequence
        case "barcode":
            isCorrect = normalizedAnswer == alarm.barcodeValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            isCorrect = Int(normalizedAnswer) == runtime.challenge.answer
        }

        guard isCorrect else {
            errorText = powAILocalized("Not yet. Try again.")
            startCurrentMission()
            return
        }

        if missionIndex < alarm.missions.count - 1 {
            missionIndex += 1
            startCurrentMission()
        } else {
            AlarmScheduler.scheduleWakeCheck(for: alarm)
            AlarmScheduler.markCompleted(alarm)
            runtime.dismissActiveAlarm()
        }
    }

    private static func generateMemorySequence(difficulty: String) -> String {
        let count: Int
        switch difficulty.lowercased() {
        case "hard": count = 8
        case "easy": count = 4
        default: count = 6
        }
        return (0..<count).map { _ in String(Int.random(in: 0...9)) }.joined()
    }
}
