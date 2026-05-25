//
//  WeightTrackerView.swift
//  Gym-app-ioss
//

import SwiftUI
import Charts

// MARK: - Model

struct WeightEntry: Identifiable, Codable {
    var id: UUID
    let email: String
    let date: Date
    var weight: Double

    enum CodingKeys: String, CodingKey {
        case id, email, date, weight
    }

    // Custom decoder: handles both secondsSince1970 (Vapor default) and ISO-8601 strings
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

        email  = try c.decode(String.self,  forKey: .email)
        weight = try c.decode(Double.self,  forKey: .weight)

        if let seconds = try? c.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: seconds)
        } else if let raw = try? c.decode(String.self, forKey: .date) {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f.date(from: raw) {
                date = d
            } else {
                f.formatOptions = [.withInternetDateTime]
                date = f.date(from: raw) ?? Date()
            }
        } else {
            date = Date()
        }
    }
}

// MARK: - Service

actor WeightService {
    static let shared = WeightService()
    private let baseURL = Constants.baseURL // <- replace

    func fetchWeights(email: String) async throws -> [WeightEntry] {
        // Percent-encode the email so @ and . are safe in a query string
        var components = URLComponents(string: "\(baseURL)/weights")!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        #if DEBUG
        print("weights JSON:", String(data: data, encoding: .utf8) ?? "<binary>")
        #endif
        // Surface a server-side error clearly instead of a cryptic decode failure
        if let obj = try? JSONDecoder().decode([String: String].self, from: data),
           let reason = obj["reason"] {
            throw NSError(domain: "WeightService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
        return try JSONDecoder().decode([WeightEntry].self, from: data)
    }

    // ISO-8601 with fractional seconds — matches Vapor's Content decoder
    // when configured with app.content.use(.json) or left at default.
    private func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]   // no fractional seconds — Vapor rejects .000Z
        return f.string(from: date)
    }

    func addWeight(email: String, date: Date, weight: Double) async throws {
        guard let url = URL(string: "\(baseURL)/weights/newWeight") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["email": email, "date": isoString(date), "weight": weight]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        print("addWeight body:", String(data: req.httpBody!, encoding: .utf8) ?? "")
        #endif

        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        #if DEBUG
        print("addWeight status:", status,
              "| body:", String(data: respData, encoding: .utf8) ?? "")
        #endif

        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "WeightService", code: status,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }

    func deleteWeight(email: String, date: Date) async throws {
        guard let url = URL(string: "\(baseURL)/weights/by-date") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email, "date": isoString(date)
        ])

        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        #if DEBUG
        print("deleteWeight status:", status,
              "| body:", String(data: respData, encoding: .utf8) ?? "")
        #endif

        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "WeightService", code: status,
                          userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }
}

// MARK: - ViewModel

@MainActor
final class WeightTrackerViewModel: ObservableObject {
    @Published var entries: [WeightEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedEntry: WeightEntry?

    let email: String
    private let service = WeightService.shared

    init(email: String) { self.email = email }

    var latestWeight: Double?  { entries.last?.weight }
    var peakWeight:   Double?  { entries.map(\.weight).max() }
    var lowWeight:    Double?  { entries.map(\.weight).min() }

    var totalChange: Double? {
        guard entries.count >= 2 else { return nil }
        return entries.last!.weight - entries.first!.weight
    }

    var yDomain: ClosedRange<Double> {
        guard let lo = entries.map(\.weight).min(),
              let hi = entries.map(\.weight).max() else { return 0...200 }
        let pad = max((hi - lo) * 0.2, 8)
        return (lo - pad)...(hi + pad)
    }

    func load() async {
        isLoading = true; errorMessage = nil
        do { entries = try await service.fetchWeights(email: email) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func addToday(weight: Double) async {
        let today = Calendar.current.startOfDay(for: Date())
        do { try await service.addWeight(email: email, date: today, weight: weight); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    func delete(_ entry: WeightEntry) async {
        do {
            try await service.deleteWeight(email: email, date: entry.date)
            entries.removeAll { $0.id == entry.id }
            if selectedEntry?.id == entry.id { selectedEntry = nil }
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Root View

struct WeightTrackerView: View {
    @StateObject private var vm: WeightTrackerViewModel
    @State private var showAddSheet  = false
    @State private var entryToDelete: WeightEntry?

    init(email: String) {
        _vm = StateObject(wrappedValue: WeightTrackerViewModel(email: email))
    }

    // Red → orange, matching "Start Workout" button
    private let accentGradient = LinearGradient(
        colors: [.red, .orange],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        ZStack {
            gymBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    heroCard
                    statsRow
                    chartCard
                    historyCard
                    Color.clear.frame(height: 80)   // FAB clearance
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }

            // Floating action button — pinned bottom
            VStack {
                Spacer()
                logWeightButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 96)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showAddSheet) {
            AddWeightSheet { w in Task { await vm.addToday(weight: w) } }
                .presentationDetents([.height(340)])
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
        .confirmationDialog("Remove this entry?", isPresented: .constant(entryToDelete != nil), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let e = entryToDelete { Task { await vm.delete(e) }; entryToDelete = nil }
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: { Text(vm.errorMessage ?? "") }
    }

    // MARK: Background — identical gradient to MainWindow2

    private var gymBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.10),
                Color(red: 0.15, green: 0.02, blue: 0.05),
                Color(red: 0.48, green: 0.08, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
                Text("Your progress")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Weight")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Consistent tracking. Visible results.")
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

    // MARK: Hero Card

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current weight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(vm.latestWeight.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("lbs")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 4)
                }
            }

            Spacer()

            if let delta = vm.totalChange {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total change")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(String(format: "%+.1f lbs", delta))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(delta <= 0 ? Color.green : Color.red)

                    Label(delta <= 0 ? "Trending down" : "Trending up",
                          systemImage: delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
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

    // MARK: Stats Row

    private var statsRow: some View {
        HStack(spacing: 14) {
            statBadge(
                icon: "scalemass.fill",
                label: "Peak",
                value: vm.peakWeight.map { String(format: "%.1f", $0) } ?? "—"
            )
            statBadge(
                icon: "arrow.down.to.line",
                label: "Low",
                value: vm.lowWeight.map { String(format: "%.1f", $0) } ?? "—"
            )
            statBadge(
                icon: "calendar",
                label: "Entries",
                value: "\(vm.entries.count)"
            )
        }
    }

    private func statBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
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

    // MARK: Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Progress over time")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                if let sel = vm.selectedEntry {
                    Text(String(format: "%.1f lbs", sel.weight))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            if vm.entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No entries yet. Start logging!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            } else {
                Chart {
                    ForEach(vm.entries) { e in
                        AreaMark(
                            x: .value("Date", e.date),
                            y: .value("lbs",  e.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.35), Color.red.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", e.date),
                            y: .value("lbs",  e.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                        .shadow(color: .orange.opacity(0.45), radius: 6)

                        PointMark(
                            x: .value("Date", e.date),
                            y: .value("lbs",  e.weight)
                        )
                        .symbolSize(vm.selectedEntry?.id == e.id ? 110 : 40)
                        .foregroundStyle(vm.selectedEntry?.id == e.id ? .white : .orange)
                        .annotation(position: .top, spacing: 5) {
                            if vm.selectedEntry?.id == e.id {
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
                }
                .chartYScale(domain: vm.yDomain)
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
                                if let date: Date = proxy.value(atX: loc.x - geo.frame(in: .local).minX) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        let nearest = vm.entries.min {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        }
                                        vm.selectedEntry = (vm.selectedEntry?.id == nearest?.id) ? nil : nearest
                                    }
                                }
                            }
                    }
                }
                .frame(height: 200)
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

    private func historyRow(_ entry: WeightEntry) -> some View {
        let isSelected = vm.selectedEntry?.id == entry.id

        return HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    if isSelected {
                        Text(entry.date, style: .time)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.45))
                            .transition(.opacity)
                    }
                }
            } icon: {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.4))
                    .font(.subheadline)
            }

            Spacer()

            Text(String(format: "%.1f lbs", entry.weight))
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .orange : .white)
                .contentTransition(.numericText())

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
            .padding(.leading, 8)
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
                vm.selectedEntry = isSelected ? nil : entry
            }
        }
    }

    // MARK: Log Weight Button — matches "Start Workout" style exactly

    private var logWeightButton: some View {
        Button { showAddSheet = true } label: {
            HStack(spacing: 12) {
                Text("Log Weight")
                    .font(.headline.weight(.bold))

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 6)
        }
    }
}

// MARK: - Add Weight Sheet

struct AddWeightSheet: View {
    /// Called with the final value always converted to lbs
    var onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var selectedUnit = "lbs"
    @FocusState private var focused: Bool

    private let unitOptions = ["lbs", "kg"]

    private var value: Double? { Double(weightText) }
    private var isValid: Bool { (value ?? 0) > 0 && (value ?? 9999) < 9999 }

    /// Always in lbs for storage
    private var valueInLbs: Double? {
        guard let v = value else { return nil }
        return selectedUnit == "kg" ? v * 2.20462 : v
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Log today's weight")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Today")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Input card
            VStack(spacing: 16) {
                // Number
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    TextField("0.0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
                        }
                    Text(selectedUnit)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 6)
                        .animation(.none, value: selectedUnit)
                }

                // Unit segmented picker
                HStack(spacing: 0) {
                    ForEach(unitOptions, id: \.self) { unit in
                        Button {
                            guard unit != selectedUnit else { return }
                            if let v = value {
                                let converted = unit == "kg" ? v / 2.20462 : v * 2.20462
                                weightText = String(format: "%.1f", converted)
                            }
                            withAnimation(.easeInOut(duration: 0.2)) { selectedUnit = unit }
                        } label: {
                            Text(unit)
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(selectedUnit == unit ? .black : .white.opacity(0.5))
                                .background(
                                    selectedUnit == unit
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .leading, endPoint: .trailing))
                                        : AnyShapeStyle(Color.clear)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .padding(4)
                .background(
                    .ultraThinMaterial.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 28)
            .background(
                .ultraThinMaterial.opacity(0.35),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()

            // Save button
            Button {
                if let lbs = valueInLbs, isValid { onSave(lbs); dismiss() }
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
                            ? AnyShapeStyle(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
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
}
