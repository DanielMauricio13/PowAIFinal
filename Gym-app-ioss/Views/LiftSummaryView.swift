//
//  LiftSummaryView.swift
//  Gym-app-ioss
//

import SwiftUI
import Charts

struct LiftSetPoint: Identifiable {
    var id: String {
        if let storedID {
            return storedID
        }
        return "\(day)-\(exerciseName)-\(setNumber)-\(Int(date.timeIntervalSince1970))"
    }

    let storedID: String?
    let day: Int
    let exerciseName: String
    let setNumber: Int
    let reps: Int
    let weight: Double
    let completed: Bool
    let date: Date

    var chartDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar.startOfDay(for: date)
    }

    var volume: Double {
        weight
    }
}

struct ExerciseSetWeightDTO: Decodable {
    let id: String?
    let exerciseName: String
    let setNumber: Int
    let weight: Double
    let date: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseName
        case exerciseNameSnake = "exercise_name"
        case setNumber
        case setNumberSnake = "set_number"
        case weight
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(UUID.self, forKey: .id)?.uuidString
        exerciseName = try container.decodeIfPresent(String.self, forKey: .exerciseName)
            ?? container.decode(String.self, forKey: .exerciseNameSnake)
        setNumber = try container.decodeIfPresent(Int.self, forKey: .setNumber)
            ?? container.decode(Int.self, forKey: .setNumberSnake)
        weight = try container.decode(Double.self, forKey: .weight)

        if let decodedDate = try? container.decode(Date.self, forKey: .date) {
            date = decodedDate
        } else if let dateString = try? container.decode(String.self, forKey: .date),
                  let parsedDate = Self.parseDate(dateString) {
            date = parsedDate
        } else if let timestamp = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: timestamp)
        } else {
            date = Date()
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"
        return dayFormatter.date(from: value)
    }
}

struct LiftExerciseSummary: Identifiable {
    var id: String { exerciseName }
    let exerciseName: String
    let points: [LiftSetPoint]

    var latestWeight: Double? {
        points.sorted { $0.date < $1.date }.last?.weight
    }

    var topWeight: Double? {
        points.map(\.weight).max()
    }

    var totalVolume: Double {
        points.map(\.volume).reduce(0, +)
    }
}

private final class LiftSummaryService {
    static let shared = LiftSummaryService()

    private init() {}

    func fetchSetWeights() async throws -> [ExerciseSetWeightDTO] {
        guard let url = URL(string: "\(Constants.baseURL)exercise-set-weights") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.applyBearerToken()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([ExerciseSetWeightDTO].self, from: data)
    }

    func deleteSetWeight(_ point: LiftSetPoint) async throws {
        let url: URL
        if let storedID = point.storedID {
            guard let idURL = URL(string: "\(Constants.baseURL)exercise-set-weights/\(storedID)") else {
                throw URLError(.badURL)
            }
            url = idURL
        } else {
            guard let entryURL = URL(string: "\(Constants.baseURL)exercise-set-weights/by-entry") else {
                throw URLError(.badURL)
            }
            url = entryURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.applyBearerToken()

        if point.storedID == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "exerciseName": point.exerciseName,
                "setNumber": point.setNumber,
                "date": Self.isoString(from: point.date)
            ])
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "LiftSummaryService", code: status, userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }

    func addSetWeight(exerciseName: String, setNumber: Int, weight: Double, date: Date) async throws -> ExerciseSetWeightDTO {
        guard let url = URL(string: "\(Constants.baseURL)exercise-set-weights") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.applyBearerToken()
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "exerciseName": exerciseName,
            "setNumber": setNumber,
            "weight": weight,
            "date": Self.isoString(from: date)
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "LiftSummaryService", code: status, userInfo: [NSLocalizedDescriptionKey: reason])
        }

        return try JSONDecoder().decode(ExerciseSetWeightDTO.self, from: data)
    }

    private static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

@MainActor
final class LiftSummaryViewModel: ObservableObject {
    @Published var setWeights: [ExerciseSetWeightDTO] = []
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var selectedExerciseName: String?
    @Published var selectedPoint: LiftSetPoint?

    private let service = LiftSummaryService.shared

    init(workout: fullTraining?) {
        selectedExerciseName = Self.summaries(from: setWeights).first?.exerciseName
    }

    var points: [LiftSetPoint] {
        Self.points(from: setWeights)
    }

    var summaries: [LiftExerciseSummary] {
        Self.summaries(from: setWeights)
    }

    var selectedSummary: LiftExerciseSummary? {
        let selected = selectedExerciseName ?? summaries.first?.exerciseName
        return summaries.first { $0.exerciseName == selected }
    }

    var selectedPoints: [LiftSetPoint] {
        selectedSummary?.points.sorted {
            if Calendar.current.isDate($0.chartDate, inSameDayAs: $1.chartDate), $0.setNumber != $1.setNumber {
                return $0.setNumber < $1.setNumber
            }
            return $0.chartDate < $1.chartDate
        } ?? []
    }

    var totalVolume: Double {
        points.map(\.volume).reduce(0, +)
    }

    var topWeight: Double? {
        points.map(\.weight).max()
    }

    var loggedSetsCount: Int {
        points.count
    }

    var activeExerciseCount: Int {
        summaries.count
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            setWeights = try await service.fetchSetWeights()
            let names = summaries.map(\.exerciseName)
            if selectedExerciseName == nil || !names.contains(selectedExerciseName ?? "") {
                selectedExerciseName = names.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectNearestPoint(to date: Date, weight: Double? = nil) {
        guard let nearest = selectedPoints.min(by: {
            selectionDistance(from: $0, to: date, weight: weight) < selectionDistance(from: $1, to: date, weight: weight)
        }) else { return }

        selectedPoint = selectedPoint?.id == nearest.id ? nil : nearest
    }

    private func selectionDistance(from point: LiftSetPoint, to date: Date, weight: Double?) -> Double {
        let timeDistance = abs(point.chartDate.timeIntervalSince(date)) / 86_400
        guard let weight else { return timeDistance }

        let weightRange = Swift.max((selectedPoints.map(\.weight).max() ?? weight) - (selectedPoints.map(\.weight).min() ?? weight), 1)
        return timeDistance + abs(point.weight - weight) / weightRange
    }

    func delete(_ point: LiftSetPoint) async {
        isDeleting = true
        errorMessage = nil

        do {
            try await service.deleteSetWeight(point)
            setWeights.removeAll { entry in
                if let storedID = point.storedID {
                    return entry.id == storedID
                }

                return entry.exerciseName.caseInsensitiveCompare(point.exerciseName) == .orderedSame &&
                    entry.setNumber == point.setNumber &&
                    Calendar.current.isDate(entry.date, inSameDayAs: point.date)
            }
            selectedPoint = nil
            let names = summaries.map(\.exerciseName)
            if selectedExerciseName == nil || !names.contains(selectedExerciseName ?? "") {
                selectedExerciseName = names.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isDeleting = false
    }

    func yDomain(for points: [LiftSetPoint]) -> ClosedRange<Double> {
        let values = points.map(\.weight)
        guard let min = values.min(), let max = values.max() else { return 0...100 }
        let pad = Swift.max((max - min) * 0.25, 10)
        return Swift.max(0, min - pad)...(max + pad)
    }

    private static func points(from setWeights: [ExerciseSetWeightDTO]) -> [LiftSetPoint] {
        setWeights.map { entry in
            LiftSetPoint(
                storedID: entry.id,
                day: 0,
                exerciseName: entry.exerciseName,
                setNumber: entry.setNumber,
                reps: 1,
                weight: entry.weight,
                completed: true,
                date: entry.date
            )
        }
    }

    private static func summaries(from setWeights: [ExerciseSetWeightDTO]) -> [LiftExerciseSummary] {
        let grouped = Dictionary(grouping: points(from: setWeights)) { point in
            normalizedExerciseName(point.exerciseName)
        }
        return grouped
            .map { _, points in
                let displayName = points.sorted { $0.date < $1.date }.last?.exerciseName ?? ""
                return LiftExerciseSummary(exerciseName: displayName, points: points)
            }
            .sorted { $0.totalVolume > $1.totalVolume }
    }

    private static func normalizedExerciseName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct LiftSummaryView: View {
    @StateObject private var vm: LiftSummaryViewModel
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var pointToDelete: LiftSetPoint?

    init(userFullWork: fullTraining?) {
        _vm = StateObject(wrappedValue: LiftSummaryViewModel(workout: userFullWork))
    }

    var body: some View {
        ZStack {
            gymBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    heroCard
                    statsRow
                    exerciseSelector
                    progressChartCard
                    setHistoryCard
                    Color.clear.frame(height: 84)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
        }
        .task { await vm.load() }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .confirmationDialog(LocalizedStringKey("Remove this set weight?"),
                            isPresented: .constant(pointToDelete != nil),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let point = pointToDelete {
                    Task { await vm.delete(point) }
                }
                pointToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pointToDelete = nil
            }
        } message: {
            if let point = pointToDelete {
                Text(String(
                    format: localized("Set %d, %@ lb on %@"),
                    locale: languageManager.locale,
                    point.setNumber,
                    formatWeight(point.weight),
                    shortDate(point.date)
                ))
            }
        }
    }

    private var gymBackground: some View {
        AppBackgroundView()
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 260)
                    .blur(radius: 18)
                    .offset(x: 140, y: -260)
            )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your lifting")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Strength")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("See how your sets move over time.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            if vm.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 6)
            } else {
                Button { Task { await vm.load() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(10)
                        .background(
                            .ultraThinMaterial.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.top, 4)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total weight")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(formatNumber(vm.totalVolume))
                            .font(.system(size: 50, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                        Text("lb")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.bottom, 4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top lift")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(vm.topWeight.map { "\(formatWeight($0)) lb" } ?? "-")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.95))
                    Text(String(
                        format: localized("%d exercises"),
                        locale: languageManager.locale,
                        vm.activeExerciseCount
                    ))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            if let summary = vm.selectedSummary {
                miniVolumeBar(summary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func miniVolumeBar(_ summary: LiftExerciseSummary) -> some View {
        let pct = vm.totalVolume > 0 ? min(summary.totalVolume / vm.totalVolume, 1.0) : 0

        return VStack(spacing: 6) {
            HStack {
                Text(summary.exerciseName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                Spacer()
                Text("\(formatNumber(summary.totalVolume)) lb")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * pct, height: 7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pct)
                }
            }
            .frame(height: 7)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBadge(icon: "number", label: "Logged sets", value: "\(vm.loggedSetsCount)")
            statBadge(icon: "scalemass.fill", label: "Top weight", value: vm.topWeight.map { "\(formatWeight($0))" } ?? "-")
            statBadge(icon: "figure.strengthtraining.traditional", label: "Exercises", value: "\(vm.activeExerciseCount)")
        }
    }

    private func statBadge(icon: String, label: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var exerciseSelector: some View {
        if !vm.summaries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.summaries) { summary in
                        let isSelected = summary.exerciseName == vm.selectedExerciseName
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                vm.selectedExerciseName = summary.exerciseName
                                vm.selectedPoint = nil
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.exerciseName)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                                Text("\(formatNumber(summary.totalVolume)) lb")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .frame(minWidth: 118, alignment: .leading)
                            .background(
                                isSelected
                                    ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.white.opacity(0.13), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.14), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var progressChartCard: some View {
        let points = vm.selectedPoints

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                Text(vm.selectedSummary?.exerciseName ?? localized("Set progress"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                if let point = vm.selectedPoint {
                    Text(String(
                        format: localized("Set %d: %@ lb"),
                        locale: languageManager.locale,
                        point.setNumber,
                        formatWeight(point.weight)
                    ))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            if points.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.chartDate),
                            y: .value("Weight", point.weight),
                            series: .value("Set", setLabel(point.setNumber))
                        )
                        .foregroundStyle(by: .value("Set", setLabel(point.setNumber)))
                        .lineStyle(StrokeStyle(lineWidth: 2.6))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.chartDate),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(by: .value("Set", setLabel(point.setNumber)))
                        .symbolSize(vm.selectedPoint?.id == point.id ? 110 : 42)
                        .annotation(position: .top, spacing: 5) {
                            if vm.selectedPoint?.id == point.id {
                                Text("\(formatWeight(point.weight)) lb")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        .ultraThinMaterial.opacity(0.65),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    )
                            }
                        }
                    }
                }
                .chartYScale(domain: vm.yDomain(for: points))
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.45))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(formatWeight(weight))")
                            }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                let xPosition = location.x - geo.frame(in: .local).minX
                                let yPosition = location.y - geo.frame(in: .local).minY
                                if let date: Date = proxy.value(atX: xPosition) {
                                    let weight: Double? = proxy.value(atY: yPosition)
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                                        vm.selectNearestPoint(to: date, weight: weight)
                                    }
                                }
                            }
                    }
                }
                .frame(height: 230)
            }
        }
        .padding(18)
        .background(
            .ultraThinMaterial.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var emptyChartPlaceholder: some View {
        ContentUnavailableView(
            localized("No set logs yet"),
            systemImage: "dumbbell",
            description: Text(localized("Log the weight for each set during a workout to build this graph."))
        )
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var setHistoryCard: some View {
        let points = Array(vm.selectedPoints.reversed())

        return VStack(alignment: .leading, spacing: 14) {
            Text("Set history")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            if points.isEmpty {
                Text("No set weights logged yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 10) {
                    ForEach(points) { point in
                        setHistoryRow(point)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func setHistoryRow(_ point: LiftSetPoint) -> some View {
        let isSelected = vm.selectedPoint?.id == point.id

        return HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(
                        format: localized("%@ · Set %d"),
                        locale: languageManager.locale,
                        historyDate(point.date),
                        point.setNumber
                    ))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if isSelected {
                        Text(localized("Saved weight"))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.45))
                            .transition(.opacity)
                    }
                }
            } icon: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.4))
                    .font(.subheadline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatWeight(point.weight)) lb")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .orange : .white)
                    .contentTransition(.numericText())
                if isSelected {
                    Text(shortDate(point.date))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .transition(.opacity)
                }
            }

            Button {
                pointToDelete = point
            } label: {
                if vm.isDeleting {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(8)
                        .background(
                            .ultraThinMaterial.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        )
                }
            }
            .disabled(vm.isDeleting)
            .padding(.leading, 8)
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Delete set weight"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? Color.orange.opacity(0.12)
                : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.orange.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                vm.selectedPoint = isSelected ? nil : point
            }
        }
    }

    @ViewBuilder
    private var exerciseBreakdown: some View {
        if !vm.summaries.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Exercise summary")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                ForEach(vm.summaries.prefix(6)) { summary in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.exerciseName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(String(
                                format: localized("%d logged sets"),
                                locale: languageManager.locale,
                                summary.points.count
                            ))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(formatNumber(summary.totalVolume)) lb")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.white)
                            Text(summary.topWeight.map {
                                String(format: localized("Top %@ lb"), locale: languageManager.locale, formatWeight($0))
                            } ?? localized("Top -"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange.opacity(0.85))
                        }
                    }
                    .padding(14)
                    .background(
                        Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }
            .padding(18)
            .background(
                .ultraThinMaterial.opacity(0.35),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 10_000 {
            return String(format: "%.1fk", value / 1_000)
        }

        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = languageManager.locale
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func historyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = languageManager.locale
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func setLabel(_ setNumber: Int) -> String {
        String(format: localized("Set %d"), locale: languageManager.locale, setNumber)
    }

    private func localized(_ key: String) -> String {
        languageManager.localizedString(forKey: key)
    }
}

#Preview {
    LiftSummaryView(userFullWork: nil)
}
