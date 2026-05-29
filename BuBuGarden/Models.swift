import Foundation

enum GardenScreen: Equatable {
    case onboarding
    case health
    case today
    case atlas
    case garden
    case flowerDetail
    case bloom
    case us
}

enum MainTab: Hashable {
    case today
    case atlas
    case us
}

enum FlowerStage: String, CaseIterable, Codable, Identifiable {
    case seed
    case sprout
    case bud
    case bloom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seed: "种子"
        case .sprout: "小芽"
        case .bud: "花苞"
        case .bloom: "绽放"
        }
    }

    var summary: String {
        switch self {
        case .seed: "刚刚种下，等待第一次浇水唤醒。"
        case .sprout: "叶片长出，花开始建立生命力。"
        case .bud: "花苞形成，继续浇水就会接近绽放。"
        case .bloom: "花已经绽放，可以种进花园收藏。"
        }
    }

    static func from(growth: Int) -> FlowerStage {
        if growth >= Constants.wateringsPerFlower { return .bloom }
        if growth >= 2 { return .bud }
        if growth >= 1 { return .sprout }
        return .seed
    }
}

enum PlanTier: String, Codable {
    case free
    case premium
}

struct Garden: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let isSpecial: Bool
    let artworkAssetName: String
    let atlasSceneAssetName: String
    let flowers: [String]
    let flowerSlugs: [String]

    init(
        id: String,
        name: String,
        isSpecial: Bool,
        artworkAssetName: String,
        atlasSceneAssetName: String,
        flowers: [String],
        flowerSlugs: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.isSpecial = isSpecial
        self.artworkAssetName = artworkAssetName
        self.atlasSceneAssetName = atlasSceneAssetName
        self.flowers = flowers
        self.flowerSlugs = flowerSlugs ?? flowers.map { _ in "" }
    }
}

struct FlowerProgress: Codable, Equatable {
    var gardenId: String
    var flowerIndex: Int
    var growth: Int
}

struct BloomSnapshot: Equatable {
    let flowerName: String
    let gardenName: String
    let gardenId: String
    let flowerIndex: Int
}

struct AppProgress: Codable, Equatable {
    var hasSeenIntro: Bool
    var authorized: Bool
    var plan: PlanTier
    var usedWateringsToday: Int
    var lastWateringDay: String
    var currentGardenIndex: Int
    var atlasGardenIndex: Int
    var selectedGardenIndex: Int
    var selectedFlowerIndex: Int?
    var currentFlower: FlowerProgress
    var collectedFlowerIndexes: [String: [Int]]

    static let fresh = AppProgress(
        hasSeenIntro: false,
        authorized: false,
        plan: .free,
        usedWateringsToday: 0,
        lastWateringDay: Date.dayKey(),
        currentGardenIndex: 0,
        atlasGardenIndex: 0,
        selectedGardenIndex: 0,
        selectedFlowerIndex: nil,
        currentFlower: FlowerProgress(gardenId: "spring_meadow", flowerIndex: 0, growth: 0),
        collectedFlowerIndexes: ["spring_meadow": [], "mist_jiangnan": [], "mediterranean_sun": []]
    )
}

enum Constants {
    static let stepsPerWatering = 1_000
    static let freeDailyCap = 2_000
    static let premiumDailyCap = 3_000
    static let wateringsPerFlower = 4
    static let ordinaryFlowersPerGarden = 9
}

extension Date {
    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension Garden {
    static let catalog: [Garden] = [
        Garden(
            id: "spring_meadow",
            name: "北境春原",
            isSpecial: false,
            artworkAssetName: "GardenSpringMeadow",
            atlasSceneAssetName: "GardenSpringMeadowAtlasScene",
            flowers: ["雪滴花", "番红花", "报春花", "勿忘我", "雏菊", "铃兰", "矢车菊", "三色堇", "风信子", "蓝罂粟", "黑郁金香", "羽冠银莲花"],
            flowerSlugs: ["snowdrop", "crocus", "primrose", "forget_me_not", "daisy", "lily_of_the_valley", "cornflower", "pansy", "hyacinth", "blue_poppy", "black_tulip", "crested_anemone"]
        ),
        Garden(
            id: "mist_jiangnan",
            name: "江南雨庭",
            isSpecial: false,
            artworkAssetName: "GardenMistJiangnan",
            atlasSceneAssetName: "GardenMistJiangnanAtlasScene",
            flowers: ["迎春花", "杜鹃", "紫藤", "鸢尾", "荷花", "睡莲", "栀子", "绣球", "木槿", "玉兰", "牡丹", "幽兰"]
        ),
        Garden(
            id: "mediterranean_sun",
            name: "地中海夏园",
            isSpecial: false,
            artworkAssetName: "GardenMediterraneanSun",
            atlasSceneAssetName: "GardenMediterraneanSunAtlasScene",
            flowers: ["薰衣草", "迷迭香花", "百里香花", "金盏菊", "罂粟", "天竺葵", "夹竹桃", "矮牵牛", "向日葵", "帝王贝母", "朱顶红", "火焰百合"]
        )
    ]

    func flowerAssetName(index: Int, stage: FlowerStage) -> String? {
        guard let slug = flowerSlugs[safe: index], !slug.isEmpty else { return nil }
        return "\(id)_\(slug)_\(stage.rawValue)"
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
