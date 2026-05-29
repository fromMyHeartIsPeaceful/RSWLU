import Foundation
import HealthKit

enum HealthStepError: LocalizedError {
    case unavailable
    case missingStepType
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "这台设备暂不支持 HealthKit。"
        case .missingStepType:
            "无法读取步数字段。"
        case .authorizationDenied:
            "尚未获得 Apple Health 步数读取权限。"
        }
    }
}

@MainActor
final class HealthStepProvider {
    private let store = HKHealthStore()
    private var stepObserverQuery: HKObserverQuery?

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestStepAuthorization() async throws {
        guard isHealthDataAvailable else { throw HealthStepError.unavailable }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthStepError.missingStepType
        }

        try await store.requestAuthorization(toShare: [], read: [stepType])
    }

    func fetchTodaySteps() async throws -> Int {
        guard isHealthDataAvailable else { throw HealthStepError.unavailable }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthStepError.missingStepType
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: max(0, Int(steps.rounded(.down))))
            }

            store.execute(query)
        }
    }

    func startObservingStepChanges(onChange: @escaping @MainActor @Sendable () async -> Void) throws {
        guard isHealthDataAvailable else { throw HealthStepError.unavailable }
        guard stepObserverQuery == nil else { return }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthStepError.missingStepType
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            completionHandler()

            if error == nil {
                Task { @MainActor in
                    await onChange()
                }
            }
        }

        stepObserverQuery = query
        store.execute(query)
    }
}
