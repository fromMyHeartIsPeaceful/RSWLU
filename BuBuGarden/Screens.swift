import SwiftUI
import UIKit

private enum GardenLayout {
    static let actionCardOuterHeight: CGFloat = 248
}

struct RootView: View {
    @EnvironmentObject private var store: GardenStore
    @State private var visibleToast: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if activeTab != nil {
                        Color.clear
                            .frame(height: 112)
                    }
                }
                .animation(.spring(response: 0.34, dampingFraction: 0.88), value: store.screen)

            if let tab = activeTab {
                BottomNav(active: tab) { selected in
                    store.setMainTab(selected)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if store.screen == .flowerDetail {
                FlowerDetailOverlay()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if let visibleToast {
                ToastView(text: visibleToast)
                    .padding(.bottom, activeTab == nil ? 28 : 98)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: store.statusMessage) { _, message in
            guard let message else { return }
            visibleToast = message
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                await MainActor.run {
                    if visibleToast == message {
                        visibleToast = nil
                        store.statusMessage = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.screen {
        case .onboarding:
            OnboardingView()
        case .health:
            HealthPermissionView()
        case .today:
            TodayView()
        case .atlas:
            AtlasView()
        case .garden:
            GardenGridView()
        case .flowerDetail:
            GardenGridView()
        case .bloom:
            BloomView()
        case .us:
            UsView()
        }
    }

    private var activeTab: MainTab? {
        switch store.screen {
        case .today:
            .today
        case .atlas, .garden:
            .atlas
        case .us:
            .us
        case .onboarding, .health, .flowerDetail, .bloom:
            nil
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
            TopBar()

            Spacer(minLength: 14)

            Image("HifiOnboardingHero")
                .resizable()
                .scaledToFill()
                .frame(height: 390)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .white.opacity(0.16)], startPoint: .top, endPoint: .bottom)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.white.opacity(0.76), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 14)
            .padding(.horizontal, 22)

            WhiteCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("每天走路，\n养出一座花园。")
                        .font(.largeTitle.weight(.heavy))
                        .lineSpacing(3)
                        .foregroundStyle(GardenTheme.leafDark)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("步步花园会把 Apple Health 的每日步数变成浇水机会。每 1000 步浇一次，慢慢收集不同花园。")
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(GardenTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Spacer(minLength: 18)

            HStack(spacing: 12) {
                SecondaryButton(title: "先看看") {
                    store.previewWithoutAuthorization()
                }
                    PrimaryButton(title: "开启步数授权", systemImage: "drop.fill") {
                        store.goToHealth()
                    }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
            }
        }
    }
}

struct HealthPermissionView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(GardenTheme.line, lineWidth: 1)
                        }
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(GardenTheme.water)
                }
                .frame(width: 92, height: 92)
                .shadow(color: GardenTheme.water.opacity(0.12), radius: 22, x: 0, y: 12)

                Text("授权步数，\n开始养花。")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(GardenTheme.ink)
                    .lineSpacing(2)

                Text("我们只读取 Apple Health 的每日步数，用来生成浇水机会；不会读取位置、心率或路线。")
                    .font(.body)
                    .lineSpacing(5)
                    .foregroundStyle(GardenTheme.muted)

                WhiteCard {
                    VStack(spacing: 16) {
                        PrivacyRow(index: 1, text: "每日步数用于计算浇水机会")
                        PrivacyRow(index: 2, text: "每 1000 步生成 1 次浇水机会")
                        PrivacyRow(index: 3, text: "拒绝授权后仍可浏览图鉴")
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    SecondaryButton(title: "暂不授权") {
                        store.previewWithoutAuthorization()
                    }
                    PrimaryButton(title: store.isLoadingSteps ? "连接中" : "连接 Apple Health", systemImage: "heart.text.square.fill", isDisabled: store.isLoadingSteps) {
                        Task {
                            await store.requestHealthAuthorization()
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                TopBar(showVIP: true) {
                    store.setMainTab(.us)
                }

                ZStack(alignment: .top) {
                    PlantView(
                        stage: store.currentStage,
                        assetName: store.currentGarden.flowerAssetName(index: store.progress.currentFlower.flowerIndex, stage: store.currentStage)
                    )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 44)
                    Button {
                        store.statusMessage = store.currentStage.summary
                    } label: {
                        Text(store.currentStage.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(GardenTheme.leafDark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.8), lineWidth: 1)
                            }
                            .shadow(color: GardenTheme.leafDark.opacity(0.08), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(GardenPressStyle())
                    .offset(y: 8)
                }
                .frame(height: max(250, min(320, proxy.size.height * 0.34)))

                Spacer(minLength: 0)

                TodayStepCard {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ZStack {
                                Text("今日步数")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(GardenTheme.leafDark.opacity(0.74))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                if store.isLoadingSteps {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            HStack(alignment: .lastTextBaseline, spacing: 0) {
                                Text("\(store.todaySteps)")
                                    .foregroundStyle(GardenTheme.water)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text("/")
                                    .foregroundStyle(GardenTheme.muted)
                                    .frame(width: 28, alignment: .center)
                                Text("\(store.dailyCap.formatted())")
                                    .foregroundStyle(GardenTheme.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                            .contentTransition(.numericText())
                            .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
                            .padding(.top, 16)
                        }

                        Spacer(minLength: 24)

                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text("每达成 1000 步，获得 1 次浇水机会")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .foregroundStyle(GardenTheme.leafDark)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .center)
                        .padding(.bottom, 10)

                        WateringProgressButton(
                            title: wateringButtonTitle,
                            progress: wateringProgress,
                            isReady: store.canWater,
                            isDisabled: actionDisabled,
                            showsProgress: !store.hasCompletedDailyWatering,
                            showsIcon: !store.hasCompletedDailyWatering
                        ) {
                            store.waterCurrentFlower()
                        }
                    }
                    .frame(height: 216, alignment: .top)
                }
                .frame(height: GardenLayout.actionCardOuterHeight)
                .padding(.horizontal, 20)
                .padding(.bottom, -8)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .background {
                Image("TodayMainBackgroundDev")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }

    private var wateringButtonTitle: String {
        if !store.progress.authorized { return "去授权 Apple Health" }
        if store.hasCompletedDailyWatering { return "浇水完毕，明天再来" }
        return "浇水"
    }

    private var wateringProgress: CGFloat {
        guard store.progress.authorized else { return 0 }
        return CGFloat(store.currentWateringSteps) / CGFloat(Constants.stepsPerWatering)
    }

    private var actionDisabled: Bool {
        return store.progress.authorized && !store.canWater
    }

}

struct AtlasView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    TopBar(showVIP: true) {
                        store.setMainTab(.us)
                    }

                    HStack(spacing: 10) {
                        RoundIconButton(systemImage: "chevron.left") {
                            store.moveAtlas(by: -1)
                        }
                        GardenIslandArtworkCard(garden: store.atlasGarden, locked: !store.isGardenUnlocked(store.progress.atlasGardenIndex))
                        RoundIconButton(systemImage: "chevron.right") {
                            store.moveAtlas(by: 1)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Spacer(minLength: 0)

                    WhiteCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(store.atlasGarden.name)
                                        .font(.title.weight(.heavy))
                                        .foregroundStyle(GardenTheme.ink)
                                    Text(statusLine)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(GardenTheme.muted)
                                }
                                Spacer()
                            }
                            Text(atlasActionHint)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GardenTheme.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.80)
                                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                            Spacer(minLength: 8)
                            PrimaryButton(title: store.isGardenUnlocked(store.progress.atlasGardenIndex) ? "查看花园" : "待解锁", isDisabled: !store.isGardenUnlocked(store.progress.atlasGardenIndex)) {
                                store.enterAtlasGarden()
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 212, alignment: .topLeading)
                    }
                    .frame(height: GardenLayout.actionCardOuterHeight)
                    .padding(.horizontal, 20)
                    .padding(.bottom, -8)
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
    }

    private var atlasActionHint: String {
        if store.isGardenUnlocked(store.progress.atlasGardenIndex) {
            return "收集 \(Constants.ordinaryFlowersPerGarden) 朵普通花，开启下一片花园。"
        }
        return "上一个花园花朵全部绽放即可解锁"
    }

    private var statusLine: String {
        let count = store.gardenFlowerCount(store.atlasGarden.id)
        let prefix: String
        if store.isGardenUnlocked(store.progress.atlasGardenIndex) {
            prefix = store.progress.atlasGardenIndex == store.progress.currentGardenIndex ? "当前花园" : "已解锁"
        } else {
            prefix = store.atlasGarden.isSpecial ? "特殊花园" : "未解锁"
        }
        return "\(prefix) · \(count) / \(Constants.ordinaryFlowersPerGarden) 普通花"
    }
}

struct GardenGridView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Button {
                    store.backToAtlas()
                } label: {
                        Label("花园图鉴", systemImage: "chevron.left")
                            .font(.headline.weight(.semibold))
                        .foregroundStyle(GardenTheme.leafDark)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.currentGarden.name)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(GardenTheme.leafDark)
                    Text("\(store.gardenFlowerCount(store.currentGarden.id)) / \(Constants.ordinaryFlowersPerGarden) 朵普通花 · 集满后开启下一片花园")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GardenTheme.muted)
                }
                .padding(.horizontal, 22)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(store.currentGarden.flowers.indices, id: \.self) { index in
                        GardenSlot(garden: store.currentGarden, index: index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 34)
        }
    }
}

private struct FlowerDetailOverlay: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        let garden = store.gardens[safe: store.progress.selectedGardenIndex] ?? store.currentGarden
        let index = store.progress.selectedFlowerIndex ?? store.progress.currentFlower.flowerIndex
        let isCurrent = store.progress.currentFlower.gardenId == garden.id && store.progress.currentFlower.flowerIndex == index
        let collected = (store.progress.collectedFlowerIndexes[garden.id] ?? []).contains(index)
        let stage = store.selectedFlowerStage(collected: collected, isCurrent: isCurrent)
        let mystery = stage == .bloom && !collected

        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.backToGarden()
                    }

                FlowerDetailSheet(
                    garden: garden,
                    index: index,
                    stage: stage,
                    collected: collected,
                    isCurrent: isCurrent,
                    mystery: mystery
                )
                .frame(maxWidth: .infinity)
                .frame(height: min(650, max(560, proxy.size.height * 0.68)))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct FlowerDetailSheet: View {
    @EnvironmentObject private var store: GardenStore
    let garden: Garden
    let index: Int
    let stage: FlowerStage
    let collected: Bool
    let isCurrent: Bool
    let mystery: Bool

    private var flowerName: String {
        garden.flowers[safe: index] ?? "花朵"
    }

    private var displayedName: String {
        mystery ? "?????" : flowerName
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.backToGarden()
                } label: {
                    Text("关闭")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(GardenTheme.ink)
                        .frame(width: 82, height: 56)
                        .background(GardenTheme.cardWarm, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.52), lineWidth: 1)
                        }
                        .shadow(color: GardenTheme.cardShadow.opacity(0.08), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(GardenPressStyle())

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.title3.weight(.bold))
                        Text(displayedName)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Image(systemName: "leaf.fill")
                            .font(.title3.weight(.bold))
                    }
                    .foregroundStyle(GardenTheme.ink.opacity(mystery ? 0.74 : 0.90))
                    .padding(.top, 12)

                    PlantView(stage: stage, assetName: garden.flowerAssetName(index: index, stage: stage), mystery: mystery)
                        .scaleEffect(stage == .seed ? 1.05 : 0.92)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(statusText)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(GardenTheme.ink)
                                Text(stage.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GardenTheme.muted)
                            }

                            Spacer()
                        }

                        HStack(spacing: 8) {
                            ForEach(FlowerStage.allCases) { item in
                                Button {
                                    store.selectedPreviewStage = item
                                } label: {
                                    Text(item.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(stage == item ? .white : GardenTheme.leafDark)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            stage == item
                                                ? GardenTheme.primaryGradient
                                                : LinearGradient(colors: [GardenTheme.creamDeep, GardenTheme.cream], startPoint: .top, endPoint: .bottom),
                                            in: Capsule()
                                        )
                                        .overlay {
                                            Capsule()
                                                .stroke(stage == item ? .white.opacity(0.30) : GardenTheme.line, lineWidth: 1)
                                        }
                                }
                                .buttonStyle(GardenPressStyle())
                            }
                        }

                        Text(mystery ? "绽放形态暂时隐藏，等真正收集时再揭晓。" : stage.summary)
                            .font(.body.weight(.medium))
                            .foregroundStyle(GardenTheme.muted)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(GardenTheme.paper)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 28, x: 0, y: -6)
    }

    private var statusText: String {
        if collected { return "已收集" }
        if isCurrent { return "正在养成" }
        return "未收集"
    }
}

struct BloomView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        let bloom = store.recentBloom
        let flowerName = bloom?.flowerName ?? store.currentFlowerName
        let gardenName = bloom?.gardenName ?? store.currentGarden.name
        let bloomGarden = bloom.flatMap { snapshot in
            store.gardens.first { $0.id == snapshot.gardenId }
        } ?? store.currentGarden
        let bloomFlowerIndex = bloom?.flowerIndex ?? store.progress.currentFlower.flowerIndex

        VStack(spacing: 20) {
            TopBar(showVIP: true) {
                store.setMainTab(.us)
            }

            Spacer()

            PlantView(stage: .bloom, assetName: bloomGarden.flowerAssetName(index: bloomFlowerIndex, stage: .bloom))
                .scaleEffect(1.28)
                .frame(height: 330)
                .background {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(LinearGradient(colors: [GardenTheme.coralSoft.opacity(0.62), GardenTheme.cream.opacity(0.30)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .padding(.horizontal, 18)
                }

            VStack(spacing: 10) {
                Text("\(flowerName)绽放了")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(GardenTheme.ink)
                Text("所属花园：\(gardenName)\n新增图鉴：已种进花园")
                    .font(.body)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GardenTheme.muted)
            }

            HStack(spacing: 12) {
                SecondaryButton(title: "查看图鉴") {
                    store.leaveBloom(to: .atlas)
                }
                PrimaryButton(title: "去花园") {
                    store.leaveBloom(to: .garden)
                }
            }
            .padding(.horizontal, 22)

            Spacer()
        }
    }
}

struct UsView: View {
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TopBar()

                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(GardenTheme.goldSoft)
                        Image(systemName: "sparkles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(GardenTheme.gold)
                    }
                    .frame(width: 70, height: 70)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.progress.plan == .premium ? "已开启" : "高级版")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GardenTheme.coral)
                        Text(store.progress.plan == .premium ? "高级版已解锁" : "更多花园能力规划中")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(GardenTheme.ink)
                        Text("每日 3000 步上限 · 解锁全部花园")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(GardenTheme.muted)
                    }
                    Spacer()
                }
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(GardenTheme.line, lineWidth: 1)
                }
                .shadow(color: GardenTheme.gold.opacity(0.13), radius: 24, x: 0, y: 14)
                .padding(.horizontal, 20)

                WhiteCard {
                    VStack(spacing: 0) {
                        SettingsRow(icon: "envelope.fill", tint: Color(red: 0.85, green: 0.92, blue: 0.81), title: "反馈与建议") {
                            store.statusMessage = "反馈入口已记录"
                        }
                        SettingsRow(icon: "lock.shield.fill", tint: Color(red: 0.86, green: 0.92, blue: 0.97), title: "协议与隐私") {
                            store.statusMessage = "协议与隐私二级入口待设计"
                        }
                        SettingsRow(icon: "icloud.fill", tint: GardenTheme.goldSoft, title: "数据备份") {
                            store.statusMessage = "数据备份会在后续版本开放"
                        }
                        SettingsRow(icon: "info.circle.fill", tint: Color(red: 0.90, green: 0.85, blue: 0.96), title: "关于我们") {
                            store.statusMessage = "步步花园，一个轻量步数养花应用"
                        }
                    }
                }
                .padding(.horizontal, 20)

                WhiteCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("感谢支持独立开发团队")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(GardenTheme.ink)
                            Text("首版先验证步数养花体验，后续可接入分享卡片和小组件。")
                                .font(.footnote)
                                .foregroundStyle(GardenTheme.muted)
                        }
                        Spacer()
                        Button {
                            store.statusMessage = "分享卡片已准备好"
                        } label: {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(GardenTheme.leaf, in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 142)
            }
        }
    }
}

private struct PrivacyRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(GardenTheme.leaf, in: Circle())
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(GardenTheme.ink)
            Spacer()
        }
    }
}

private struct RoundIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(GardenTheme.leafDark)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [GardenTheme.cardWarm, GardenTheme.cardWarmLow],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(GardenTheme.cardStroke.opacity(0.28), lineWidth: 1)
                }
                .overlay {
                    Circle()
                        .inset(by: 0.7)
                        .stroke(.white.opacity(0.30), lineWidth: 0.7)
                }
                .shadow(color: GardenTheme.cardShadow.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(GardenPressStyle())
    }
}

private struct GardenIslandArtworkCard: View {
    let garden: Garden
    let locked: Bool

    var body: some View {
        ZStack {
            Image(garden.artworkAssetName)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .saturation(locked ? 0.18 : 1)
                .blur(radius: locked ? 2.5 : 0)

            if locked {
                Image(systemName: "lock.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(GardenTheme.muted)
                    .frame(width: 58, height: 58)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(
            LinearGradient(
                colors: [GardenTheme.cardWarm, GardenTheme.cardWarmLow],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(GardenTheme.cardStroke.opacity(0.24), lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .inset(by: 0.8)
                .stroke(.white.opacity(0.30), lineWidth: 0.7)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: GardenTheme.cardShadow.opacity(0.10), radius: 18, x: 0, y: 9)
        .accessibilityLabel(garden.name)
    }
}

private struct GardenSlot: View {
    @EnvironmentObject private var store: GardenStore
    let garden: Garden
    let index: Int

    var body: some View {
        let done = (store.progress.collectedFlowerIndexes[garden.id] ?? []).contains(index)
        let isCurrent = store.progress.currentFlower.gardenId == garden.id && store.progress.currentFlower.flowerIndex == index
        let locked = index >= Constants.ordinaryFlowersPerGarden && store.progress.plan != .premium
        let slotStage: FlowerStage = done ? .bloom : isCurrent ? store.currentStage : .seed
        let assetName = garden.flowerAssetName(index: index, stage: slotStage)

        Button {
            if locked {
                store.statusMessage = "高级版限定花"
            } else {
                store.openGardenSlot(index)
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if !locked, let assetName, let image = UIImage(named: assetName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                            .saturation(!done && !isCurrent ? 0.34 : 1)
                            .opacity(!done && !isCurrent ? 0.62 : 1)
                    } else {
                        FlowerArtworkPlaceholder(
                            stage: slotStage,
                            locked: locked,
                            muted: !done && !isCurrent
                        )
                        .frame(height: 88)
                    }

                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(GardenTheme.muted)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial, in: Circle())
                    } else if done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(GardenTheme.leaf)
                            .background(.white, in: Circle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(8)
                    }
                }
                .frame(height: 88)

                Text("当前")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(GardenTheme.leaf)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(GardenTheme.cream, in: Capsule())
                    .opacity(isCurrent ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .padding(.horizontal, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isCurrent ? GardenTheme.leaf.opacity(0.72) : .white.opacity(0.72), lineWidth: isCurrent ? 2 : 1)
            }
            .shadow(color: GardenTheme.leafDark.opacity(isCurrent ? 0.12 : 0.06), radius: isCurrent ? 14 : 8, x: 0, y: isCurrent ? 8 : 4)
        }
        .buttonStyle(GardenPressStyle())
    }
}

private struct FlowerArtworkPlaceholder: View {
    let stage: FlowerStage
    let locked: Bool
    let muted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardFill)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(iconColor.opacity(0.13))
                        .frame(width: 58, height: 8)
                        .blur(radius: 1.2)
                        .padding(.bottom, 14)
                }

            Image(systemName: symbolName)
                .font(.system(size: 36, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
                .offset(y: -4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        }
        .saturation(muted || locked ? 0.25 : 1)
        .opacity(locked ? 0.62 : 1)
        .accessibilityHidden(true)
    }

    private var cardFill: LinearGradient {
        if locked || muted {
            return LinearGradient(
                colors: [Color(uiColor: .secondarySystemBackground).opacity(0.72), GardenTheme.cream.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [GardenTheme.cream.opacity(0.92), GardenTheme.leafLight.opacity(0.28)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconColor: Color {
        if locked || muted {
            return GardenTheme.soft
        }
        return stage == .bloom ? GardenTheme.coral : GardenTheme.leaf
    }

    private var symbolName: String {
        if locked {
            return "leaf.fill"
        }

        switch stage {
        case .seed:
            return "drop.fill"
        case .sprout:
            return "leaf.fill"
        case .bud:
            return "camera.macro"
        case .bloom:
            return "flower.fill"
        }
    }
}

private struct FlowerDetailBody: View {
    @EnvironmentObject private var store: GardenStore
    let garden: Garden
    let index: Int
    let stage: FlowerStage
    let collected: Bool
    let isCurrent: Bool
    let mystery: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(garden.flowers[safe: index] ?? "花朵")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(GardenTheme.ink)
                Text("\(collected ? "已收集" : isCurrent ? "正在养成" : "未收集") · \(stage.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GardenTheme.muted)
            }

            HStack(spacing: 7) {
                ForEach(FlowerStage.allCases) { item in
                    Button {
                        store.selectedPreviewStage = item
                    } label: {
                        Text(item.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(stage == item ? .white : GardenTheme.leafDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(stage == item ? GardenTheme.primaryGradient : LinearGradient(colors: [GardenTheme.creamDeep, GardenTheme.cream], startPoint: .top, endPoint: .bottom), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(stage == item ? .white.opacity(0.30) : GardenTheme.line, lineWidth: 1)
                            }
                    }
                    .buttonStyle(GardenPressStyle())
                }
            }

            Text(mystery ? "绽放形态先保持隐藏，只露出模糊边缘，等真正收集时再揭晓。" : stage.summary)
                .font(.body)
                .foregroundStyle(GardenTheme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(GardenTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GardenTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(GardenTheme.soft)
            }
            .padding(.vertical, 11)
            .frame(minHeight: 54)
        }
        .buttonStyle(GardenPressStyle())
    }
}
