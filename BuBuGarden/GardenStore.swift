import Foundation
import SwiftUI

@MainActor
final class GardenStore: ObservableObject {
    @Published var screen: GardenScreen
    @Published private(set) var progress: AppProgress
    @Published private(set) var todaySteps: Int = 0
    @Published private(set) var isLoadingSteps = false
    @Published var statusMessage: String?
    @Published var selectedPreviewStage: FlowerStage?
    @Published private(set) var recentBloom: BloomSnapshot?

    let gardens = Garden.catalog

    private let healthProvider = HealthStepProvider()
    private let persistenceKey = "BuBuGarden.Progress.v1"

    init() {
        let loaded = GardenStore.loadProgress(key: persistenceKey)
        let migrated = loaded.migratedForCurrentCatalog(gardens: gardens).normalizedForToday()
        progress = migrated
        screen = migrated.hasSeenIntro ? .today : .onboarding
        normalizeCurrentFlower()
        save()
    }

    var currentGarden: Garden {
        gardens[safe: progress.currentGardenIndex] ?? gardens[0]
    }

    var atlasGarden: Garden {
        gardens[safe: progress.atlasGardenIndex] ?? gardens[0]
    }

    var currentFlowerName: String {
        flowerName(gardenId: progress.currentFlower.gardenId, index: progress.currentFlower.flowerIndex)
    }

    var currentStage: FlowerStage {
        FlowerStage.from(growth: progress.currentFlower.growth)
    }

    var dailyCap: Int {
        progress.plan == .premium ? Constants.premiumDailyCap : Constants.freeDailyCap
    }

    var acceptedSteps: Int {
        min(max(0, todaySteps), dailyCap)
    }

    var earnedWaterings: Int {
        acceptedSteps / Constants.stepsPerWatering
    }

    var availableWaterings: Int {
        max(0, earnedWaterings - progress.usedWateringsToday)
    }

    var stepsUntilNextWatering: Int {
        guard todaySteps < dailyCap else { return 0 }
        let nextTarget = min(dailyCap, (todaySteps / Constants.stepsPerWatering + 1) * Constants.stepsPerWatering)
        return max(0, nextTarget - todaySteps)
    }

    var currentWateringSteps: Int {
        if availableWaterings > 0 { return Constants.stepsPerWatering }
        let usedSteps = progress.usedWateringsToday * Constants.stepsPerWatering
        return min(max(0, acceptedSteps - usedSteps), Constants.stepsPerWatering)
    }

    var hasCompletedDailyWatering: Bool {
        todaySteps >= dailyCap && availableWaterings == 0
    }

    var canWater: Bool {
        progress.authorized && availableWaterings > 0 && progress.currentFlower.growth < Constants.wateringsPerFlower
    }

    func requestHealthAuthorization() async {
        isLoadingSteps = true
        defer { isLoadingSteps = false }

        do {
            try await healthProvider.requestStepAuthorization()
            progress.authorized = true
            progress.hasSeenIntro = true
            todaySteps = try await healthProvider.fetchTodaySteps()
            statusMessage = "Apple Health 已连接"
            screen = .today
            save()
        } catch {
            progress.authorized = false
            progress.hasSeenIntro = true
            statusMessage = error.localizedDescription
            screen = .today
            save()
        }
    }

    func refreshStepsIfPossible() async {
        guard progress.authorized else { return }
        isLoadingSteps = true
        defer { isLoadingSteps = false }

        do {
            todaySteps = try await healthProvider.fetchTodaySteps()
            progress = progress.normalizedForToday()
            save()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func previewWithoutAuthorization() {
        progress.hasSeenIntro = true
        screen = .today
        save()
    }

    func goToHealth() {
        progress.hasSeenIntro = true
        screen = .health
        save()
    }

    func setMainTab(_ tab: MainTab) {
        selectedPreviewStage = nil
        switch tab {
        case .today:
            normalizeCurrentFlower()
            recentBloom = nil
            screen = .today
        case .atlas:
            recentBloom = nil
            progress.atlasGardenIndex = progress.currentGardenIndex
            screen = .atlas
        case .us:
            recentBloom = nil
            screen = .us
        }
        save()
    }

    func waterCurrentFlower() {
        guard progress.authorized else {
            screen = .health
            return
        }

        guard availableWaterings > 0 else {
            statusMessage = todaySteps >= dailyCap ? "今日浇水机会已用完" : "还差 \(stepsUntilNextWatering) 步"
            return
        }

        guard progress.currentFlower.growth < Constants.wateringsPerFlower else {
            screen = .bloom
            return
        }

        progress.usedWateringsToday += 1
        progress.currentFlower.growth += 1

        if progress.currentFlower.growth >= Constants.wateringsPerFlower {
            let bloom = collectBloomingFlower()
            statusMessage = "\(bloom.flowerName)绽放了"
            screen = .bloom
        } else {
            statusMessage = "浇水成功，\(currentFlowerName)现在是「\(currentStage.title)」"
        }

        save()
    }

    func moveAtlas(by delta: Int) {
        let count = gardens.count
        progress.atlasGardenIndex = (progress.atlasGardenIndex + delta + count) % count
        save()
    }

    func enterAtlasGarden() {
        let index = progress.atlasGardenIndex
        guard isGardenUnlocked(index) else {
            statusMessage = gardens[index].isSpecial && progress.plan != .premium ? "这片花园暂未开放" : "先完成上一片花园"
            return
        }

        progress.currentGardenIndex = index
        progress.selectedGardenIndex = index
        progress.selectedFlowerIndex = nil
        selectedPreviewStage = nil
        normalizeCurrentFlower()
        screen = .garden
        save()
    }

    func openGardenSlot(_ index: Int) {
        progress.selectedGardenIndex = progress.currentGardenIndex
        progress.selectedFlowerIndex = index
        selectedPreviewStage = nil
        screen = .flowerDetail
        save()
    }

    func backToAtlas() {
        recentBloom = nil
        progress.atlasGardenIndex = progress.currentGardenIndex
        progress.selectedFlowerIndex = nil
        selectedPreviewStage = nil
        screen = .atlas
        save()
    }

    func backToGarden() {
        recentBloom = nil
        selectedPreviewStage = nil
        screen = .garden
        save()
    }

    func leaveBloom(to screen: GardenScreen) {
        recentBloom = nil
        if screen == .atlas {
            progress.atlasGardenIndex = progress.currentGardenIndex
        }
        self.screen = screen
        save()
    }

    func gardenFlowerCount(_ gardenId: String, ordinaryOnly: Bool = true) -> Int {
        let indexes = progress.collectedFlowerIndexes[gardenId] ?? []
        return ordinaryOnly ? indexes.filter { $0 < Constants.ordinaryFlowersPerGarden }.count : indexes.count
    }

    func isGardenUnlocked(_ index: Int) -> Bool {
        guard gardens.indices.contains(index) else { return false }
        if index == 0 { return true }
        if gardens[index].isSpecial && progress.plan != .premium { return false }
        return gardenFlowerCount(gardens[index - 1].id) >= Constants.ordinaryFlowersPerGarden
    }

    func flowerName(gardenId: String, index: Int) -> String {
        let garden = gardens.first { $0.id == gardenId } ?? gardens[0]
        return garden.flowers[safe: index] ?? garden.flowers[0]
    }

    func selectedFlowerStage(collected: Bool, isCurrent: Bool) -> FlowerStage {
        selectedPreviewStage ?? (isCurrent ? currentStage : collected ? .bloom : .seed)
    }

    private func normalizeCurrentFlower() {
        if progress.currentFlower.growth >= Constants.wateringsPerFlower {
            _ = collectBloomingFlower()
            return
        }

        let garden = currentGarden
        let collected = progress.collectedFlowerIndexes[progress.currentFlower.gardenId] ?? []
        let alreadyCollected = collected.contains(progress.currentFlower.flowerIndex)

        guard progress.currentFlower.gardenId == garden.id, !alreadyCollected else {
            progress.currentFlower = FlowerProgress(
                gardenId: garden.id,
                flowerIndex: nextFlowerIndex(gardenId: garden.id) ?? 0,
                growth: 0
            )
            return
        }
    }

    private func collectBloomingFlower() -> BloomSnapshot {
        let gardenId = progress.currentFlower.gardenId
        let flowerIndex = progress.currentFlower.flowerIndex
        let garden = gardens.first { $0.id == gardenId } ?? gardens[0]
        let bloom = BloomSnapshot(
            flowerName: flowerName(gardenId: gardenId, index: flowerIndex),
            gardenName: garden.name,
            gardenId: gardenId,
            flowerIndex: flowerIndex
        )

        var collected = progress.collectedFlowerIndexes[gardenId] ?? []
        if !collected.contains(flowerIndex) {
            collected.append(flowerIndex)
            progress.collectedFlowerIndexes[gardenId] = collected.sorted()
        }

        progress.currentGardenIndex = gardens.firstIndex { $0.id == gardenId } ?? progress.currentGardenIndex
        let nextIndex = nextFlowerIndex(gardenId: gardenId) ?? flowerIndex
        progress.currentFlower = FlowerProgress(gardenId: gardenId, flowerIndex: nextIndex, growth: 0)
        progress.selectedFlowerIndex = nil
        selectedPreviewStage = nil
        recentBloom = bloom

        return bloom
    }

    private func nextFlowerIndex(gardenId: String) -> Int? {
        let garden = gardens.first { $0.id == gardenId } ?? gardens[0]
        let collected = progress.collectedFlowerIndexes[gardenId] ?? []
        return garden.flowers.indices.first { !collected.contains($0) && ($0 < Constants.ordinaryFlowersPerGarden || progress.plan == .premium) }
    }

    private func save() {
        progress = progress.normalizedForToday()
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private static func loadProgress(key: String) -> AppProgress {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppProgress.self, from: data) else {
            return .fresh
        }

        return decoded
    }
}

private extension AppProgress {
    func migratedForCurrentCatalog(gardens: [Garden]) -> AppProgress {
        guard let firstGarden = gardens.first else { return self }

        let validIds = Set(gardens.map(\.id))
        var copy = self

        if !validIds.contains(copy.currentFlower.gardenId) {
            copy.currentGardenIndex = 0
            copy.atlasGardenIndex = 0
            copy.selectedGardenIndex = 0
            copy.selectedFlowerIndex = nil
            copy.currentFlower = FlowerProgress(gardenId: firstGarden.id, flowerIndex: 0, growth: 0)
        }

        copy.currentGardenIndex = min(max(0, copy.currentGardenIndex), gardens.count - 1)
        copy.atlasGardenIndex = min(max(0, copy.atlasGardenIndex), gardens.count - 1)
        copy.selectedGardenIndex = min(max(0, copy.selectedGardenIndex), gardens.count - 1)

        for garden in gardens where copy.collectedFlowerIndexes[garden.id] == nil {
            copy.collectedFlowerIndexes[garden.id] = []
        }

        return copy
    }

    func normalizedForToday() -> AppProgress {
        var copy = self
        let today = Date.dayKey()
        if copy.lastWateringDay != today {
            copy.lastWateringDay = today
            copy.usedWateringsToday = 0
        }
        return copy
    }
}
