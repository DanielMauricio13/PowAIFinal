//
//  DailyNutritionEntry.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/25/26.
//


//
//  NutritionTrackerView.swift
//  Gym-app-ioss
//
//
//  NutritionTrackerView.swift
//  Gym-app-ioss
//

import SwiftUI
import Charts

// MARK: - Model

struct DailyNutritionEntry: Identifiable, Codable {
    var id: UUID
    let email: String
    let date: Date
    var protein: Double
    var carbs: Double
    var calories: Double
    var sugars: Double

    enum CodingKeys: String, CodingKey {
        case id, email, date, protein, carbs, calories, sugars
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
        } else if let str = try? c.decode(String.self, forKey: .id),
                  let uuid = UUID(uuidString: str) {
            id = uuid
        } else {
            id = UUID()
        }

        email    = try c.decode(String.self, forKey: .email)
        protein  = try c.decode(Double.self, forKey: .protein)
        carbs    = try c.decode(Double.self, forKey: .carbs)
        calories = try c.decode(Double.self, forKey: .calories)
        sugars   = try c.decode(Double.self, forKey: .sugars)

        if let seconds = try? c.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: seconds)
        } else if let raw = try? c.decode(String.self, forKey: .date) {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f.date(from: raw) { date = d } else {
                f.formatOptions = [.withInternetDateTime]
                date = f.date(from: raw) ?? Date()
            }
        } else {
            date = Date()
        }
    }
}

// MARK: - Service

actor NutritionService {
    static let shared = NutritionService()
    private let baseURL = Constants.baseURL

    private func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
    }

    func fetchEntries(email: String) async throws -> [DailyNutritionEntry] {
        guard let url = URL(string: "\(baseURL)/daily-nutrition") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.applyBearerToken()
        let (data, _) = try await URLSession.shared.data(for: request)
        if let obj = try? JSONDecoder().decode([String: String].self, from: data),
           let reason = obj["reason"] {
            throw NSError(domain: "NutritionService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
        return try JSONDecoder().decode([DailyNutritionEntry].self, from: data)
    }

    func addEntry(email: String, date: Date, protein: Double,
                  carbs: Double, calories: Double, sugars: Double) async throws {
        guard let url = URL(string: "\(baseURL)/daily-nutrition/newEntry") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.applyBearerToken()
        let body: [String: Any] = [
            "date": isoString(date),
            "protein": protein, "carbs": carbs,
            "calories": calories, "sugars": sugars
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "NutritionService", code: status,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }

    func updateEntry(email: String, date: Date, protein: Double,
                     carbs: Double, calories: Double, sugars: Double) async throws {
        guard let url = URL(string: "\(baseURL)/daily-nutrition/by-date") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.applyBearerToken()
        let body: [String: Any] = [
            "date": isoString(date),
            "protein": protein, "carbs": carbs,
            "calories": calories, "sugars": sugars
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "NutritionService", code: status,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }

    func deleteEntry(email: String, date: Date) async throws {
        guard let url = URL(string: "\(baseURL)/daily-nutrition/by-date") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.applyBearerToken()
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "date": isoString(date)
        ])
        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "NutritionService", code: status,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }
}

// MARK: - ViewModel

@MainActor
final class NutritionTrackerViewModel: ObservableObject {
    @Published var entries: [DailyNutritionEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedEntry: DailyNutritionEntry?

    let email: String
    let user: User
    private let service = NutritionService.shared

    init(email: String, user: User) {
        self.email = email
        self.user  = user
    }

    // Goal values from User profile
    var goalCalories: Double { Double(user.DailyCalories ?? 2000) }
    var goalProtein:  Double { Double(user.DailyProtein  ?? 150)  }
    var goalCarbs:    Double { Double(user.carbs          ?? 250)  }
    var goalSugars:   Double { Double(user.sugars         ?? 50)   }

    // Latest entry
    var latest: DailyNutritionEntry? { entries.last }

    // Averages
    var avgCalories: Double? { avg(entries.map(\.calories)) }
    var avgProtein:  Double? { avg(entries.map(\.protein))  }
    var avgCarbs:    Double? { avg(entries.map(\.carbs))    }
    var avgSugars:   Double? { avg(entries.map(\.sugars))   }

    private func avg(_ vals: [Double]) -> Double? {
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    func yDomain(for values: [Double], goal: Double) -> ClosedRange<Double> {
        let all = values + [goal]
        guard let lo = all.min(), let hi = all.max() else { return 0...300 }
        let pad = max((hi - lo) * 0.25, 10)
        return (lo - pad)...(hi + pad)
    }

    func load() async {
        isLoading = true; errorMessage = nil
        do { entries = try await service.fetchEntries(email: email) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func addToday(protein: Double, carbs: Double, calories: Double, sugars: Double) async {
        let today = Calendar.current.startOfDay(for: Date())
        do {
            try await service.addEntry(email: email, date: today,
                                       protein: protein, carbs: carbs,
                                       calories: calories, sugars: sugars)
            await load()
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ entry: DailyNutritionEntry) async {
        do {
            try await service.deleteEntry(email: email, date: entry.date)
            entries.removeAll { $0.id == entry.id }
            if selectedEntry?.id == entry.id { selectedEntry = nil }
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Macro Config

private struct MacroConfig {
    let title: String
    let unit: String
    let keyPath: KeyPath<DailyNutritionEntry, Double>
    let goal: Double
    let gradientColors: [Color]
    let icon: String
}

// MARK: - Root View

struct NutritionTrackerView: View {
    @StateObject private var vm: NutritionTrackerViewModel
    @State private var showAddSheet   = false
    @State private var entryToDelete: DailyNutritionEntry?

    init(email: String, user: User) {
        _vm = StateObject(wrappedValue: NutritionTrackerViewModel(email: email, user: user))
    }

    private let accentGradient = LinearGradient(
        colors: [.red, .orange], startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        ZStack {
            gymBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    heroCard
                    statsRow
                    macroCharts
                    historyCard
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }

            VStack {
                Spacer()
//                logNutritionButton
//                    .padding(.horizontal, 24)
//                    .padding(.bottom, 96)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showAddSheet) {
            AddNutritionSheet { p, c, cal, s in
                Task { await vm.addToday(protein: p, carbs: c, calories: cal, sugars: s) }
            }
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
            .presentationBackground(
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.10),
                        Color(red: 0.20, green: 0.03, blue: 0.06)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        .confirmationDialog("Remove this entry?",
                            isPresented: .constant(entryToDelete != nil),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let e = entryToDelete { Task { await vm.delete(e) }; entryToDelete = nil }
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: { Text(vm.errorMessage ?? "") }
    }

    // MARK: Background

    private var gymBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.10),
                Color(red: 0.15, green: 0.02, blue: 0.05),
                Color(red: 0.48, green: 0.08, blue: 0.12)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260)
                .blur(radius: 18)
                .offset(x: 140, y: -260)
        )
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your nutrition")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Macros")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Fuel your goals. Track every macro.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            if vm.isLoading {
                ProgressView().tint(.white).padding(.top, 6)
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

    // MARK: Hero Card — today's totals vs goals

    private var heroCard: some View {
        let entry = vm.latest
        return VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's calories")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(entry.map { String(format: "%.0f", $0.calories) } ?? "—")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("kcal")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.bottom, 4)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Goal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(String(format: "%.0f kcal", vm.goalCalories))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.blue.opacity(0.9))

                    if let cal = entry?.calories {
                        let delta = cal - vm.goalCalories
                        Text(String(format: "%+.0f kcal", delta))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(delta <= 0 ? .green : .red)
                    }
                }
            }

            // Mini goal bars
            VStack(spacing: 10) {
                goalBar(label: "Protein",  value: entry?.protein  ?? 0, goal: vm.goalProtein,  color: .orange)
                goalBar(label: "Carbs",    value: entry?.carbs    ?? 0, goal: vm.goalCarbs,    color: .yellow)
                goalBar(label: "Sugars",   value: entry?.sugars   ?? 0, goal: vm.goalSugars,   color: .pink)
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

    private func goalBar(label: String, value: Double, goal: Double, color: Color) -> some View {
        let pct = goal > 0 ? min(value / goal, 1.0) : 0
        return VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.0f / %.0f g", value, goal))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * pct, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pct)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Stats Row

    private var statsRow: some View {
        HStack(spacing: 14) {
            statBadge(icon: "flame.fill",        label: "Avg kcal",
                      value: vm.avgCalories.map { String(format: "%.0f", $0) } ?? "—")
            statBadge(icon: "bolt.fill",         label: "Avg protein",
                      value: vm.avgProtein.map  { String(format: "%.0f g", $0) } ?? "—")
            statBadge(icon: "calendar",          label: "Entries",
                      value: "\(vm.entries.count)")
        }
    }

    private func statBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
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

    // MARK: All Macro Charts

    private var macroCharts: some View {
        let configs: [MacroConfig] = [
            MacroConfig(title: "Calories",  unit: "kcal", keyPath: \.calories,
                        goal: vm.goalCalories,
                        gradientColors: [.red, .orange],    icon: "flame.fill"),
            MacroConfig(title: "Protein",   unit: "g",    keyPath: \.protein,
                        goal: vm.goalProtein,
                        gradientColors: [.orange, .yellow], icon: "bolt.fill"),
            MacroConfig(title: "Carbs",     unit: "g",    keyPath: \.carbs,
                        goal: vm.goalCarbs,
                        gradientColors: [.yellow, .green],  icon: "leaf.fill"),
            MacroConfig(title: "Sugars",    unit: "g",    keyPath: \.sugars,
                        goal: vm.goalSugars,
                        gradientColors: [.pink, .purple],   icon: "drop.fill"),
        ]

        return VStack(spacing: 16) {
            ForEach(configs, id: \.title) { config in
                macroChartCard(config: config)
            }
        }
    }

    // MARK: Single Macro Chart Card

    private func macroChartCard(config: MacroConfig) -> some View {
        let values   = vm.entries.map { $0[keyPath: config.keyPath] }
        let yDomain  = vm.yDomain(for: values, goal: config.goal)
        let gradient = LinearGradient(colors: config.gradientColors,
                                      startPoint: .leading, endPoint: .trailing)
        let areaGrad = LinearGradient(
            colors: [config.gradientColors[0].opacity(0.35),
                     config.gradientColors[0].opacity(0.03)],
            startPoint: .top, endPoint: .bottom
        )

        return VStack(alignment: .leading, spacing: 14) {
            // Card header
            HStack(spacing: 10) {
                Image(systemName: config.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(config.gradientColors[0])
                Text(config.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()

                // Goal pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 7, height: 7)
                    Text("Goal: \(String(format: "%.0f %@", config.goal, config.unit))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color.blue.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )

                // Selected value
                if let sel = vm.selectedEntry {
                    Text(String(format: "%.0f %@", sel[keyPath: config.keyPath], config.unit))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(config.gradientColors[0])
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            if vm.entries.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    // Area fill
                    ForEach(vm.entries) { e in
                        AreaMark(
                            x: .value("Date", e.date),
                            y: .value(config.title, e[keyPath: config.keyPath])
                        )
                        .foregroundStyle(areaGrad)
                        .interpolationMethod(.catmullRom)
                    }

                    // Line
                    ForEach(vm.entries) { e in
                        LineMark(
                            x: .value("Date", e.date),
                            y: .value(config.title, e[keyPath: config.keyPath])
                        )
                        .foregroundStyle(gradient)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                        .shadow(color: config.gradientColors[0].opacity(0.45), radius: 6)
                    }

                    // Points
                    ForEach(vm.entries) { e in
                        let isSelected = vm.selectedEntry?.id == e.id
                        PointMark(
                            x: .value("Date", e.date),
                            y: .value(config.title, e[keyPath: config.keyPath])
                        )
                        .symbolSize(isSelected ? 110 : 40)
                        .foregroundStyle(isSelected ? .white : config.gradientColors[0])
                        .annotation(position: .top, spacing: 5) {
                            if isSelected {
                                Text(e.date, style: .date)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        .ultraThinMaterial.opacity(0.6),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    )
                            }
                        }
                    }

                    // ── Blue dotted goal line ──
                    RuleMark(y: .value("Goal", config.goal))
                        .foregroundStyle(Color.blue.opacity(0.75))
                        .lineStyle(StrokeStyle(lineWidth: 1.8, dash: [6, 5]))
                        .annotation(position: .trailing, alignment: .center, spacing: 4) {
                            Text("Goal")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.blue.opacity(0.85))
                        }
                }
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.4))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.4))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .chartBackground { _ in Color.clear }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { loc in
                                if let date: Date = proxy.value(
                                    atX: loc.x - geo.frame(in: .local).minX) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        let nearest = vm.entries.min {
                                            abs($0.date.timeIntervalSince(date)) <
                                            
                                            abs($1.date.timeIntervalSince(date))
                                        }
                                        vm.selectedEntry =
                                            (vm.selectedEntry?.id == nearest?.id) ? nil : nearest
                                    }
                                }
                            }
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.3))
            Text("No data yet. Start logging!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: History Card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            if vm.entries.isEmpty {
                Text("No entries logged yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.entries.reversed()) { entry in
                        historyRow(entry)
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

    private func historyRow(_ entry: DailyNutritionEntry) -> some View {
        let isSelected = vm.selectedEntry?.id == entry.id

        return VStack(spacing: 0) {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date,
                             format: .dateTime.weekday(.wide).month(.abbreviated).day())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text(String(format: "%.0f kcal", entry.calories))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange.opacity(0.85))
                    }
                } icon: {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(isSelected ? .orange : .white.opacity(0.4))
                        .font(.subheadline)
                }

                Spacer()

                Button {
                    entryToDelete = entry
                } label: {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Expanded macro breakdown on selection
            if isSelected {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 12)

                HStack(spacing: 0) {
                    macroDetailCell(label: "Protein",  value: entry.protein,  unit: "g",    color: .orange)
                    macroDetailCell(label: "Carbs",    value: entry.carbs,    unit: "g",    color: .yellow)
                    macroDetailCell(label: "Sugars",   value: entry.sugars,   unit: "g",    color: .pink)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.orange.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                vm.selectedEntry = isSelected ? nil : entry
            }
        }
    }

    private func macroDetailCell(label: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(String(format: "%.0f%@", value, unit))
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Log Button

    private var logNutritionButton: some View {
        Button { showAddSheet = true } label: {
            HStack(spacing: 12) {
                Text("Log Nutrition")
                    .font(.headline.weight(.bold))
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.red, .orange],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 6)
        }
    }
}

// MARK: - Add Nutrition Sheet

struct AddNutritionSheet: View {
    var onSave: (Double, Double, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var proteinText  = ""
    @State private var carbsText    = ""
    @State private var caloriesText = ""
    @State private var sugarsText   = ""
    @FocusState private var focused: Bool

    private var protein:  Double? { Double(proteinText)  }
    private var carbs:    Double? { Double(carbsText)     }
    private var calories: Double? { Double(caloriesText)  }
    private var sugars:   Double? { Double(sugarsText)    }

    private var isValid: Bool {
        (protein  ?? 0) >= 0 &&
        (carbs    ?? 0) >= 0 &&
        (calories ?? 0) > 0  &&
        (sugars   ?? 0) >= 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Log today's nutrition")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Today")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date.now,
                     format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Input fields
            VStack(spacing: 14) {
                macroField(label: "Calories", placeholder: "0",
                           text: $carbsText, unit: "kcal",
                           color: .orange, icon: "flame.fill",
                           binding: $caloriesText)
                macroField(label: "Protein",  placeholder: "0",
                           text: $proteinText, unit: "g",
                           color: .yellow, icon: "bolt.fill",
                           binding: $proteinText)
                macroField(label: "Carbs",    placeholder: "0",
                           text: $carbsText, unit: "g",
                           color: .green, icon: "leaf.fill",
                           binding: $carbsText)
                macroField(label: "Sugars",   placeholder: "0",
                           text: $sugarsText, unit: "g",
                           color: .pink, icon: "drop.fill",
                           binding: $sugarsText)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Save button
            Button {
                guard isValid,
                      let p = protein, let c = carbs,
                      let cal = calories, let s = sugars else { return }
                onSave(p, c, cal, s)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Text("Save Entry")
                        .font(.headline.weight(.bold))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    AnyShapeStyle(
                        isValid
                        ? AnyShapeStyle(LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.white.opacity(0.1))
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: isValid ? Color.red.opacity(0.4) : .clear, radius: 10, x: 0, y: 6)
            }
            .disabled(!isValid)
            .animation(.easeInOut(duration: 0.2), value: isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func macroField(label: String, placeholder: String,
                            text: Binding<String>, unit: String,
                            color: Color, icon: String,
                            binding: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 70, alignment: .leading)

            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)

            Text(unit)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 30, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            .ultraThinMaterial.opacity(0.35),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
