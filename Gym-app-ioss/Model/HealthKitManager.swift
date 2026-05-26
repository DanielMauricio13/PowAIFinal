//  HealthKitManager.swift
//  Gym-app-ioss

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: - Published state
    @Published var latestBPM: Int?          // nil until first sample arrives
    @Published var authorized: Bool = false
    @Published var authError: String?
    @Published var isMonitoring: Bool = false

    // MARK: - Private
    private let store = HKHealthStore()
    private var observerQuery: HKObserverQuery?
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var anchor: HKQueryAnchor?

    private let heartRateType = HKQuantityType(.heartRate)
    private let bpmUnit      = HKUnit.count().unitDivided(by: .minute())

    // ─── Authorization ────────────────────────────────────────────────────────

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authError = "HealthKit is not available on this device."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [heartRateType])
            authorized = store.authorizationStatus(for: heartRateType) == .sharingAuthorized
                      || store.authorizationStatus(for: heartRateType) == .sharingDenied
            // Note: iOS never returns .sharingAuthorized for read-only types.
            // We treat any non-notDetermined status as "user was prompted".
            startMonitoring()
        } catch {
            authError = error.localizedDescription
        }
    }

    // ─── Start / Stop Monitoring ──────────────────────────────────────────────
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        observerQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) {
            [weak self] _, completionHandler, error in
            guard error == nil else { completionHandler(); return }
            Task { await self?.fetchLatestSample() }   // already correct
            completionHandler()
        }
        store.execute(observerQuery!)
        store.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(), end: nil, options: .strictStartDate
        )

        anchoredQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, _ in
            // ✅ Hop back to MainActor before touching isolated state
            Task { @MainActor [weak self] in
                self?.anchor = newAnchor
                self?.process(samples: samples)
            }
        }

        anchoredQuery!.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            // ✅ Same fix for the update handler
            Task { @MainActor [weak self] in
                self?.anchor = newAnchor
                self?.process(samples: samples)
            }
        }

        store.execute(anchoredQuery!)
    }

    func stopMonitoring() {
        if let oq = observerQuery { store.stop(oq) }
        if let aq = anchoredQuery { store.stop(aq) }
        observerQuery  = nil
        anchoredQuery  = nil
        isMonitoring   = false
        latestBPM      = nil
        store.disableBackgroundDelivery(for: heartRateType) { _, _ in }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private func fetchLatestSample() async {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, _ in
            self?.process(samples: samples)
        }
        store.execute(query)
    }

    private func process(samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let last = samples.last else { return }
        let bpm = Int(last.quantity.doubleValue(for: bpmUnit).rounded())
        Task { @MainActor in self.latestBPM = bpm }
    }
}
