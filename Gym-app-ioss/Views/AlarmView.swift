import SwiftUI
import UserNotifications
import AudioToolbox
import AlarmKit
import AVFoundation
import EventKit

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
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
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

struct AlarmSoundOption: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let fileName: String?

    static let options: [AlarmSoundOption] = [
        AlarmSoundOption(id: "default", title: "Default", systemImage: "bell.fill", fileName: nil),
        AlarmSoundOption(id: "beacon", title: "Beacon", systemImage: "dot.radiowaves.left.and.right", fileName: "powai_alarm_beacon.wav"),
        AlarmSoundOption(id: "radar", title: "Radar", systemImage: "antenna.radiowaves.left.and.right", fileName: "powai_alarm_radar.wav"),
        AlarmSoundOption(id: "siren", title: "Siren", systemImage: "waveform.path", fileName: "powai_alarm_siren.wav"),
        AlarmSoundOption(id: "pulse", title: "Pulse", systemImage: "waveform", fileName: "powai_alarm_pulse.wav"),
        AlarmSoundOption(id: "rekordbox_siren", title: "RB Siren", systemImage: "megaphone.fill", fileName: "powai_rekordbox_siren.wav"),
        AlarmSoundOption(id: "rekordbox_horn", title: "RB Horn", systemImage: "speaker.wave.3.fill", fileName: "powai_rekordbox_horn.wav"),
        AlarmSoundOption(id: "rekordbox_noise", title: "RB Noise", systemImage: "waveform.badge.magnifyingglass", fileName: "powai_rekordbox_noise.wav"),
        AlarmSoundOption(id: "rekordbox_sinewave", title: "RB Sine", systemImage: "alternatingcurrent", fileName: "powai_rekordbox_sinewave.wav")
    ]

    static func option(for id: String?) -> AlarmSoundOption {
        let normalized = id?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "default"
        return options.first { $0.id == normalized } ?? options[0]
    }

    var notificationSound: UNNotificationSound {
        guard let fileName else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }

    var bundleURL: URL? {
        guard let fileName else { return nil }
        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return Bundle.main.url(forResource: parts[0], withExtension: parts[1])
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
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
    var isEnabled: Bool

    var soundOption: AlarmSoundOption {
        AlarmSoundOption.option(for: alarmSound)
    }

    var soundText: String {
        soundOption.title
    }

    var missions: [String] {
        let configured = challengeTypes?.filter { !($0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) } ?? []
        return configured.isEmpty ? [challengeType] : configured
    }

    var missionText: String {
        missions.map { mission in
            switch mission {
            case "typing": return "Typing"
            case "memory": return "Memory"
            case "barcode": return "QR/Barcode"
            default: return "Math"
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
        guard !repeatDays.isEmpty else { return "Once" }
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
    private var audioPlayer: AVAudioPlayer?

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
        if playBundledSound(alarm.soundOption) == false {
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
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func playBundledSound(_ sound: AlarmSoundOption) -> Bool {
        guard let url = sound.bundleURL else { return false }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            return true
        } catch {
            print("Alarm sound playback failed: \(error)")
            return false
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
            do {
                try cancelSystemAlarm(alarm)
            } catch {
                print("AlarmKit pre-schedule cancel skipped: \(error)")
            }

            do {
                try await scheduleSystemAlarm(alarm)
            } catch {
                print("AlarmKit scheduling failed; notification backup is still scheduled: \(error)")
            }
        }
    }

    static func cancel(_ alarm: AlarmItem) {
        Task {
            do {
                try cancelSystemAlarm(alarm)
            } catch {
                print("AlarmKit cancel failed: \(error)")
            }
        }

        cancelLocalNotifications(for: alarm)
    }

    private static func cancelSystemAlarm(_ alarm: AlarmItem) throws {
        try AlarmManager.shared.cancel(id: alarm.id)
    }

    private static func cancelLocalNotifications(for alarm: AlarmItem) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let prefix = "powai-alarm-\(alarm.id.uuidString)"
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    static func scheduleWakeCheck(for alarm: AlarmItem) {
        guard let minutes = alarm.wakeCheckMinutes, minutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Still awake?"
        content.body = "Complete your alarm missions again to confirm."
        content.sound = alarm.soundOption.notificationSound
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

    private static func scheduleNotification(_ alarm: AlarmItem) {
        requestPermission()

        let backupDelay: TimeInterval = 1
        let days = alarm.repeatDays.isEmpty ? [0] : alarm.repeatDays
        for day in days {
            let content = UNMutableNotificationContent()
            content.title = alarm.title
            content.body = "Solve the challenge to turn this alarm off."
            content.sound = alarm.soundOption.notificationSound
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["alarmID": alarm.id.uuidString]

            var components = DateComponents()
            components.hour = alarm.hour
            components.minute = alarm.minute

            let repeats = day != 0
            if repeats {
                components.weekday = day
            }

            let trigger: UNNotificationTrigger
            if repeats {
                components.second = Int(backupDelay)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            } else {
                let nextDate = nextOneTimeDate(hour: alarm.hour, minute: alarm.minute)
                let interval = max(nextDate.addingTimeInterval(backupDelay).timeIntervalSinceNow, 1)
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: interval,
                    repeats: false
                )
            }

            let request = UNNotificationRequest(
                identifier: notificationID(for: alarm, day: day),
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

    private static func notificationID(for alarm: AlarmItem, day: Int) -> String {
        "powai-alarm-\(alarm.id.uuidString)-\(day)"
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

        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.title),
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.fill"
                )
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

        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            sound: .default
        )
        _ = try await manager.schedule(id: alarm.id, configuration: configuration)
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

@MainActor
final class AlarmViewModel: ObservableObject {
    @Published var alarms: [AlarmItem] = []
    @Published var isLoading = false
    @Published var message: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var request = try makeRequest(path: "alarms")
            request.httpMethod = "GET"
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            alarms = try JSONDecoder().decode([AlarmItem].self, from: data)
            alarms.forEach { AlarmScheduler.schedule($0) }
            message = alarms.isEmpty ? "No alarms yet." : nil
        } catch {
            message = "Could not load alarms."
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
            AlarmScheduler.schedule(saved)
            message = nil
        } catch {
            message = "Could not save alarm."
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
            AlarmScheduler.cancel(alarm)
        } catch {
            message = "Could not delete alarm."
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
}

struct AlarmListView: View {
    @Binding var pendingAlarmID: String?
    @StateObject private var viewModel = AlarmViewModel()
    @ObservedObject private var runtime = AlarmRuntime.shared
    @State private var editingAlarm: AlarmItem?
    @State private var showingEditor = false

    init(pendingAlarmID: Binding<String?> = .constant(nil)) {
        _pendingAlarmID = pendingAlarmID
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
            await viewModel.load()
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
                Text("Alarms")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Stack missions · Force a real wake-up")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                Text("Set loud alarms that only stop after math, memory, typing, or movement missions.")
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
            LazyVStack(spacing: 12) {
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
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }
}

struct ProductivityView: View {
    @Binding var pendingAlarmID: String?
    @State private var selectedSection: ProductivitySection = .alarms

    var body: some View {
        VStack(spacing: 0) {
            customSegmentedControl
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 6)

            Group {
                switch selectedSection {
                case .alarms:
                    AlarmListView(pendingAlarmID: $pendingAlarmID)
                case .dayPlan:
                    DayPlanView()
                }
            }
        }
        .background(AppBackgroundView())
    }

    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ProductivitySection.allCases, id: \.self) { section in
                let isSelected = selectedSection == section
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.system(size: 13, weight: .bold))
                        Text(section.title)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(isSelected ? .black : PowAI.slate)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(PowAI.orangeGlow)
                                .shadow(color: PowAI.orange.opacity(0.4), radius: 6, y: 3)
                        }
                    }
                }
            }
        }
        .padding(4)
        .background(PowAI.surface, in: RoundedRectangle(cornerRadius: 14))
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

    var icon: String {
        switch self {
        case .alarms: return "alarm"
        case .dayPlan: return "calendar.badge.clock"
        }
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
}

struct DayPlanBlock: Codable, Equatable, Identifiable {
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
    var startAlarmEnabled: Bool
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
        guard let reminderMinutesBefore else { return "No reminder" }
        return reminderMinutesBefore == 0 ? "At start" : "\(reminderMinutesBefore)m before"
    }

    var isAllDayCalendarCopy: Bool {
        notes?.hasPrefix("Copied from Apple Calendar:") == true &&
        startHour == 0 &&
        startMinute == 0 &&
        endHour == 23 &&
        endMinute == 59
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
        if isAllDay { return "All day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var durationText: String {
        if isAllDay { return "Calendar" }
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
    var startAlarmEnabled: Bool?
    var isDone: Bool?
}

enum DayPlanScheduler {
    static func schedule(_ block: DayPlanBlock) {
        cancel(block)
        requestNotificationPermission()
        scheduleReminder(block)
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
        guard let reminder = block.reminderMinutesBefore,
              let blockDate = DayPlanDateFormatter.date(from: block.scheduledDate),
              let startDate = Calendar.current.date(
                bySettingHour: block.startHour,
                minute: block.startMinute,
                second: 0,
                of: blockDate
              ) else { return }

        let fireDate = Calendar.current.date(byAdding: .minute, value: -reminder, to: startDate) ?? startDate
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = block.title
        content.body = "\(block.timeText) • \(block.categoryOption.title)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminderNotificationID(for: block),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Day plan reminder scheduling failed: \(error)")
            }
        }
    }

    private static func scheduleStartAlarm(_ block: DayPlanBlock) {
        guard block.startAlarmEnabled,
              let startDate = startDate(for: block),
              startDate > Date() else { return }

        scheduleStartAlarmNotification(block, startDate: startDate)

        Task {
            do {
                try await scheduleStartSystemAlarm(block, startDate: startDate)
            } catch {
                print("Day plan AlarmKit scheduling failed; notification backup is still scheduled: \(error)")
            }
        }
    }

    static func cancel(_ block: DayPlanBlock) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderNotificationID(for: block), startAlarmNotificationID(for: block)]
        )

        Task {
            do {
                try AlarmManager.shared.cancel(id: block.id)
            } catch {
                print("Day plan AlarmKit cancel skipped: \(error)")
            }
        }
    }

    private static func startDate(for block: DayPlanBlock) -> Date? {
        guard let blockDate = DayPlanDateFormatter.date(from: block.scheduledDate) else { return nil }
        return Calendar.current.date(
            bySettingHour: block.startHour,
            minute: block.startMinute,
            second: 0,
            of: blockDate
        )
    }

    private static func scheduleStartAlarmNotification(_ block: DayPlanBlock, startDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Start: \(block.title)"
        content.body = "\(block.timeText) • Keep moving with your plan."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: startAlarmNotificationID(for: block),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Day plan start alarm notification failed: \(error)")
            }
        }
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

    private static func reminderNotificationID(for block: DayPlanBlock) -> String {
        "day-plan-reminder-\(block.id.uuidString)"
    }

    private static func startAlarmNotificationID(for block: DayPlanBlock) -> String {
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

    func load(for date: Date) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dateString = DayPlanDateFormatter.string(from: date)
            var components = URLComponents(string: Constants.baseURL + "day-schedule")
            components?.queryItems = [URLQueryItem(name: "date", value: dateString)]
            guard let url = components?.url else { throw URLError(.badURL) }

            var request = URLRequest(url: url)
            request.applyBearerToken()
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            blocks = try JSONDecoder().decode([DayPlanBlock].self, from: data)
                .sorted { ($0.startHour, $0.startMinute) < ($1.startHour, $1.startMinute) }
            blocks.forEach { DayPlanScheduler.schedule($0) }
            message = blocks.isEmpty ? "No time blocks yet." : nil
        } catch {
            message = "Could not load day plan."
            print("Load day plan failed: \(error)")
        }
    }

    func loadCalendarEvents(for date: Date) async {
        isCalendarLoading = true
        defer { isCalendarLoading = false }

        do {
            guard try await ensureCalendarAccess() else {
                calendarEvents = []
                calendarMessage = "Calendar access is needed to show Apple Calendar events."
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
                        title: event.title?.isEmpty == false ? event.title : "Untitled event",
                        calendarTitle: event.calendar.title,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        isAllDay: event.isAllDay,
                        color: Color(cgColor: event.calendar.cgColor)
                    )
                }
            calendarMessage = calendarEvents.isEmpty ? "No Apple Calendar events on this date." : nil
        } catch {
            calendarEvents = []
            calendarMessage = "Could not load Apple Calendar events."
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
            if let index = blocks.firstIndex(where: { $0.id == saved.id }) {
                blocks[index] = saved
            } else {
                blocks.append(saved)
            }
            blocks.sort { ($0.startHour, $0.startMinute) < ($1.startHour, $1.startMinute) }
            DayPlanScheduler.schedule(saved)
            message = nil
        } catch {
            message = "Could not save time block."
            print("Save day plan failed: \(error)")
        }
    }

    func delete(_ block: DayPlanBlock) async {
        do {
            var request = try makeRequest(path: "day-schedule/\(block.id.uuidString)")
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            blocks.removeAll { $0.id == block.id }
            DayPlanScheduler.cancel(block)
            message = blocks.isEmpty ? "No time blocks yet." : nil
        } catch {
            message = "Could not delete time block."
            print("Delete day plan failed: \(error)")
        }
    }

    func setDone(_ block: DayPlanBlock, isDone: Bool) async {
        let payload = DayPlanSaveRequest(
            scheduledDate: block.scheduledDate,
            title: block.title,
            notes: block.notes,
            startHour: block.startHour,
            startMinute: block.startMinute,
            endHour: block.endHour,
            endMinute: block.endMinute,
            category: block.category,
            reminderMinutesBefore: block.reminderMinutesBefore,
            startAlarmEnabled: block.startAlarmEnabled,
            isDone: isDone
        )
        await save(existing: block, request: payload)
    }

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.applyBearerToken()
        return request
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
    @StateObject private var viewModel = DayPlanViewModel()
    @State private var selectedDate = Date()
    @State private var editingBlock: DayPlanBlock?
    @State private var showingEditor = false
    @State private var showingCalendarEvents = false
    private let liveActivityTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

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
            await viewModel.load(for: selectedDate)
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
            notes: "Copied from Apple Calendar: \(event.calendarTitle)",
            startHour: startComponents.hour ?? 0,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 23,
            endMinute: endComponents.minute ?? 59,
            category: "personal",
            reminderMinutesBefore: nil,
            startAlarmEnabled: false,
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
                Text("Day Plan")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Block time · Stay visible")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PowAI.slate)
                Text("Plan your day by time blocks, with optional start alarms and Live Activity updates.")
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
                    Text(isToday ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide)))
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

                Text(showingCalendarEvents ? "Hide Apple Calendar" : "Show Apple Calendar")
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
                            Task { await viewModel.delete(block) }
                        }
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }

    private var calendarEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PowAISectionLabel(text: "Apple Calendar")
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
                    Text("Loading Apple Calendar events...")
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
                    .accessibilityLabel(event.isAllDay ? "All-day calendar event" : (isImported ? "Added to Day Plan" : "Add to Day Plan"))
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
                    .padding(.vertical, 16)

                HStack(alignment: .top, spacing: 14) {
                    Button { onToggle(!block.isDone) } label: {
                        ZStack {
                            Circle()
                                .stroke(block.isDone ? category.color : PowAI.slate.opacity(0.4), lineWidth: 2)
                                .frame(width: 26, height: 26)
                            if block.isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(category.color)
                            }
                        }
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(block.timeText)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(PowAI.slate)

                            Text(block.durationText)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(category.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(category.color.opacity(0.12), in: Capsule())
                        }

                        Text(block.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(block.isDone ? PowAI.slate : .white)
                            .strikethrough(block.isDone, color: PowAI.slate)
                            .lineLimit(2)

                        if let notes = block.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(PowAI.slate)
                                .lineLimit(2)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                PowAIChip(label: category.title, icon: category.icon, color: category.color)
                                PowAIChip(label: block.reminderText, icon: "bell.fill", color: PowAI.slate)
                                if block.startAlarmEnabled {
                                    PowAIChip(label: "Alarm", icon: "alarm.fill", color: PowAI.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PowAI.slate)
                            .frame(width: 32, height: 32)
                            .background(PowAI.surface, in: Circle())
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 14)
                .padding(.vertical, 16)
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
    @State private var startAlarmEnabled: Bool
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
        _startAlarmEnabled = State(initialValue: block?.startAlarmEnabled ?? false)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("What") {
                    TextField("Task, class, errand, workout...", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("When") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Type") {
                    Picker("Category", selection: $category) {
                        ForEach(DayPlanCategory.options) { option in
                            Label(option.title, systemImage: option.icon).tag(option.id)
                        }
                    }
                }

                Section("Reminder") {
                    Picker("Reminder", selection: $reminderMinutesBefore) {
                        Text("None").tag(nil as Int?)
                        Text("At start").tag(0 as Int?)
                        Text("5 min before").tag(5 as Int?)
                        Text("10 min before").tag(10 as Int?)
                        Text("15 min before").tag(15 as Int?)
                        Text("30 min before").tag(30 as Int?)
                        Text("1 hour before").tag(60 as Int?)
                    }

                    Toggle(isOn: $startAlarmEnabled) {
                        Label("Alarm at start", systemImage: "alarm.fill")
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(block == nil ? "New Time Block" : "Edit Time Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title is required."
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
            errorMessage = "End time must be after start time."
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
            startAlarmEnabled: startAlarmEnabled,
            isDone: block?.isDone ?? false
        )

        await onSave(payload)
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
                    .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center) {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(alarmHour)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                            Text(":")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .offset(y: -3)
                            Text(alarmMinute)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                            Text(alarmPeriod)
                                .font(.system(size: 16, weight: .bold))
                                .offset(y: -6)
                        }
                        .foregroundStyle(alarm.isEnabled ? .white : PowAI.slate)

                        Spacer()

                        Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: onToggle))
                            .labelsHidden()
                            .tint(PowAI.orange)
                            .scaleEffect(0.9)
                    }

                    Text(alarm.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(alarm.isEnabled ? PowAI.slateLight : PowAI.slate)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            PowAIChip(label: alarm.missionText, icon: "bolt.fill", color: PowAI.orange)
                            PowAIChip(label: alarm.repeatText, icon: "repeat", color: PowAI.slate)
                            PowAIChip(label: alarm.soundText, icon: alarm.soundOption.systemImage, color: PowAI.slate)
                        }
                    }

                    HStack(spacing: 8) {
                        Spacer()
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PowAI.slateLight)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(PowAI.surface, in: Capsule())
                        }
                        Button(action: onDelete) {
                            Label("Delete", systemImage: "trash")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.85))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.red.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 18)
                .padding(.vertical, 18)
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
        _title = State(initialValue: alarm?.title ?? "Wake up")
        _selectedDays = State(initialValue: Set(alarm?.repeatDays ?? Array(1...7)))
        _selectedMissions = State(initialValue: Set(alarm?.missions ?? ["math"]))
        _difficulty = State(initialValue: alarm?.difficulty ?? "medium")
        _barcodeValue = State(initialValue: alarm?.barcodeValue ?? "")
        _typingPhrase = State(initialValue: alarm?.typingPhrase ?? "I am awake and ready")
        _wakeCheckEnabled = State(initialValue: (alarm?.wakeCheckMinutes ?? 0) > 0)
        _wakeCheckMinutes = State(initialValue: alarm?.wakeCheckMinutes ?? 5)
        _alarmSound = State(initialValue: alarm?.soundOption.id ?? "default")

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
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                            TextField("Wake up", text: $title)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Sound")
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
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Repeat")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            HStack(spacing: 8) {
                                ForEach(weekdays, id: \.self) { day in
                                    dayButton(day)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Missions")
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
                                Text("Registered QR or barcode")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)

                                HStack(spacing: 10) {
                                    TextField("Scan or paste code", text: $barcodeValue)
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
                                Text("Typing phrase")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)

                                TextField("I am awake and ready", text: $typingPhrase)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            Picker("Difficulty", selection: $difficulty) {
                                ForEach(difficulties, id: \.self) { option in
                                    Text(option.capitalized).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Wake-up check", isOn: $wakeCheckEnabled)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .tint(.orange)

                            if wakeCheckEnabled {
                                Stepper("\(wakeCheckMinutes) minutes after dismiss", value: $wakeCheckMinutes, in: 1...30)
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
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving" : "Save") {
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
            Label(mission.title, systemImage: mission.icon)
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
            editorError = "Scan or paste a QR/barcode before saving."
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
            Label(sound.title, systemImage: sound.systemImage)
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
                    Text("Mission \(missionIndex + 1) of \(alarm.missions.count)")
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
                    Text(missionIndex == alarm.missions.count - 1 ? "Turn Off Alarm" : "Next Mission")
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
            Text(alarm.typingPhrase?.isEmpty == false ? alarm.typingPhrase! : "I am awake and ready")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            TextField("Type the phrase exactly", text: $answer)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding()
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))

        case "memory":
            Text(showMemorySequence ? memorySequence : "Enter the sequence")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            TextField("Sequence", text: $answer)
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

            Text("Scan the registered QR code or barcode.")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Button {
                showBarcodeScanner = true
            } label: {
                Label("Scan Code", systemImage: "camera.fill")
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

            TextField("Answer", text: $answer)
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
            isCorrect = normalizedAnswer == (phrase?.isEmpty == false ? phrase! : "I am awake and ready")
        case "memory":
            isCorrect = normalizedAnswer == memorySequence
        case "barcode":
            isCorrect = normalizedAnswer == alarm.barcodeValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            isCorrect = Int(normalizedAnswer) == runtime.challenge.answer
        }

        guard isCorrect else {
            errorText = "Not yet. Try again."
            startCurrentMission()
            return
        }

        if missionIndex < alarm.missions.count - 1 {
            missionIndex += 1
            startCurrentMission()
        } else {
            AlarmScheduler.scheduleWakeCheck(for: alarm)
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
