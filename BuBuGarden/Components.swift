import SwiftUI
import UIKit

enum GardenTheme {
    static let ink = Color.primary
    static let muted = adaptive(light: UIColor(red: 0.46, green: 0.41, blue: 0.34, alpha: 1), dark: UIColor(red: 0.68, green: 0.63, blue: 0.54, alpha: 1))
    static let soft = adaptive(light: UIColor(red: 0.54, green: 0.58, blue: 0.52, alpha: 1), dark: UIColor(red: 0.58, green: 0.64, blue: 0.56, alpha: 1))
    static let line = Color.primary.opacity(0.10)
    static let paper = adaptive(light: UIColor(red: 0.985, green: 0.972, blue: 0.94, alpha: 1), dark: UIColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1))
    static let cream = adaptive(light: UIColor(red: 0.96, green: 0.98, blue: 0.92, alpha: 1), dark: UIColor(red: 0.13, green: 0.18, blue: 0.14, alpha: 1))
    static let creamDeep = adaptive(light: UIColor(red: 0.90, green: 0.94, blue: 0.84, alpha: 1), dark: UIColor(red: 0.08, green: 0.12, blue: 0.09, alpha: 1))
    static let leaf = adaptive(light: UIColor(red: 0.27, green: 0.58, blue: 0.24, alpha: 1), dark: UIColor(red: 0.50, green: 0.82, blue: 0.42, alpha: 1))
    static let leafDark = adaptive(light: UIColor(red: 0.13, green: 0.36, blue: 0.20, alpha: 1), dark: UIColor(red: 0.67, green: 0.91, blue: 0.58, alpha: 1))
    static let leafLight = adaptive(light: UIColor(red: 0.64, green: 0.76, blue: 0.36, alpha: 1), dark: UIColor(red: 0.37, green: 0.67, blue: 0.30, alpha: 1))
    static let gold = Color.orange
    static let goldSoft = adaptive(light: UIColor(red: 1.00, green: 0.87, blue: 0.52, alpha: 1), dark: UIColor(red: 0.45, green: 0.31, blue: 0.11, alpha: 1))
    static let coral = adaptive(light: UIColor(red: 0.92, green: 0.37, blue: 0.31, alpha: 1), dark: UIColor(red: 1.00, green: 0.55, blue: 0.49, alpha: 1))
    static let coralSoft = adaptive(light: UIColor(red: 1.00, green: 0.86, blue: 0.82, alpha: 1), dark: UIColor(red: 0.34, green: 0.15, blue: 0.14, alpha: 1))
    static let water = adaptive(light: UIColor(red: 0.18, green: 0.55, blue: 0.86, alpha: 1), dark: UIColor(red: 0.38, green: 0.72, blue: 1.00, alpha: 1))
    static let waterDeep = adaptive(light: UIColor(red: 0.05, green: 0.43, blue: 0.78, alpha: 1), dark: UIColor(red: 0.18, green: 0.57, blue: 0.92, alpha: 1))
    static let waterSoft = adaptive(light: UIColor(red: 0.86, green: 0.94, blue: 1.00, alpha: 1), dark: UIColor(red: 0.10, green: 0.22, blue: 0.35, alpha: 1))
    static let cardWarm = adaptive(light: UIColor(red: 1.00, green: 0.995, blue: 0.972, alpha: 1), dark: UIColor(red: 0.17, green: 0.15, blue: 0.12, alpha: 1))
    static let cardWarmLow = adaptive(light: UIColor(red: 0.995, green: 0.982, blue: 0.945, alpha: 1), dark: UIColor(red: 0.14, green: 0.12, blue: 0.10, alpha: 1))
    static let cardStroke = adaptive(light: UIColor(red: 0.72, green: 0.64, blue: 0.50, alpha: 1), dark: UIColor(red: 0.58, green: 0.52, blue: 0.42, alpha: 1))
    static let cardShadow = adaptive(light: UIColor(red: 0.42, green: 0.34, blue: 0.22, alpha: 1), dark: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1))

    static let primaryGradient = LinearGradient(
        colors: [leafLight, leaf],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct AppBackground: View {
    var body: some View {
        GardenTheme.paper
            .ignoresSafeArea()
    }
}

struct GardenPressStyle: ButtonStyle {
    var scale: CGFloat = 0.975

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct TopBar: View {
    var showVIP = false
    var onVIP: () -> Void = {}

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                DaisyMark()
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.16), radius: 5, x: 0, y: 3)
                Text("步步花园")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(GardenTheme.leafDark)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            if showVIP {
                Button(action: onVIP) {
                    Label("VIP", systemImage: "crown.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(GardenTheme.gold)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 42)
                    .background(
                        LinearGradient(colors: [GardenTheme.goldSoft.opacity(0.78), .white.opacity(0.70)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(GardenTheme.gold.opacity(0.38), lineWidth: 1)
                    }
                    .shadow(color: GardenTheme.gold.opacity(0.18), radius: 12, x: 0, y: 6)
                }
                .accessibilityLabel("高级版")
                .buttonStyle(GardenPressStyle())
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
    }
}

struct DaisyMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.96, green: 0.90, blue: 0.55))
                    .frame(width: 7, height: 14)
                    .offset(y: -7)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle()
                .fill(Color(red: 0.94, green: 0.78, blue: 0.28))
                .frame(width: 8, height: 8)
        }
    }
}

struct BottomNav: View {
    let active: MainTab
    let action: (MainTab) -> Void

    var body: some View {
        HStack(spacing: 6) {
            item(.today, title: "今日", systemImage: "drop")
            item(.atlas, title: "图鉴", systemImage: "leaf")
            item(.us, title: "我们", systemImage: "person.2")
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private func item(_ tab: MainTab, title: String, systemImage: String) -> some View {
        Button {
            action(tab)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .symbolVariant(active == tab ? .fill : .none)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(active == tab ? .white : Color(uiColor: .secondaryLabel))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(active == tab ? GardenTheme.primaryGradient : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            .shadow(color: active == tab ? GardenTheme.leaf.opacity(0.22) : .clear, radius: 9, x: 0, y: 5)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(active == tab ? .isSelected : [])
        .buttonStyle(GardenPressStyle())
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(isDisabled ? GardenTheme.ink.opacity(0.42) : GardenTheme.leafDark)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [
                        GardenTheme.cardWarm,
                        GardenTheme.cardWarmLow
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(GardenTheme.cardStroke.opacity(isDisabled ? 0.16 : 0.28), lineWidth: 1)
            }
            .overlay {
                Capsule()
                    .inset(by: 0.8)
                    .stroke(.white.opacity(0.30), lineWidth: 0.7)
            }
            .shadow(color: GardenTheme.cardShadow.opacity(isDisabled ? 0.03 : 0.12), radius: 13, x: 0, y: 7)
            .shadow(color: GardenTheme.cardShadow.opacity(isDisabled ? 0.02 : 0.05), radius: 3, x: 0, y: 1)
        }
        .disabled(isDisabled)
        .buttonStyle(GardenPressStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(GardenTheme.leafDark)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [
                        GardenTheme.cardWarm,
                        GardenTheme.cardWarmLow
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(GardenTheme.cardStroke.opacity(0.24), lineWidth: 1)
            }
            .overlay {
                Capsule()
                    .inset(by: 0.8)
                    .stroke(.white.opacity(0.30), lineWidth: 0.7)
            }
            .shadow(color: GardenTheme.cardShadow.opacity(0.10), radius: 11, x: 0, y: 6)
            .shadow(color: GardenTheme.cardShadow.opacity(0.04), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(GardenPressStyle())
    }
}

struct WateringProgressButton: View {
    let title: String
    let progress: CGFloat
    let isReady: Bool
    let isDisabled: Bool
    var showsProgress = true
    var showsIcon = true
    let action: () -> Void

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    private var textRestsOnWater: Bool {
        isReady || (showsProgress && clampedProgress >= 0.45)
    }

    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack {
                    Capsule()
                        .fill(emptyGradient)

                    Capsule()
                        .stroke(GardenTheme.cardStroke.opacity(0.26), lineWidth: 1)

                    if showsProgress && clampedProgress > 0 {
                        HStack(spacing: 0) {
                            waterFill(width: geometry.size.width)
                            Spacer(minLength: 0)
                        }
                        .clipShape(Capsule())
                    }

                    Capsule()
                        .inset(by: 0.8)
                        .stroke(.white.opacity(isReady ? 0.22 : 0.30), lineWidth: 0.7)

                    LinearGradient(
                        colors: [.white.opacity(isReady ? 0.10 : 0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, 14)
                    .padding(.top, 7)
                    .frame(height: 22)
                    .allowsHitTesting(false)
                        .frame(maxHeight: .infinity, alignment: .top)

                    HStack(spacing: 8) {
                        if showsIcon {
                            Image(systemName: isReady ? "drop.fill" : "drop")
                                .font(.headline.weight(.bold))
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.bounce, value: isReady)
                        }

                        Text(title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(textColor)
                    .shadow(color: .white.opacity(isReady ? 0.44 : 0.18), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .contentShape(Capsule())
        }
        .disabled(isDisabled)
        .buttonStyle(GardenPressStyle())
        .shadow(color: GardenTheme.cardShadow.opacity(0.12), radius: 13, x: 0, y: 7)
        .shadow(color: GardenTheme.water.opacity(isReady ? 0.12 : 0), radius: 12, x: 0, y: 5)
        .sensoryFeedback(.success, trigger: isReady) { _, newValue in
            newValue
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: clampedProgress)
        .animation(.easeInOut(duration: 0.28), value: isReady)
    }

    private var emptyGradient: LinearGradient {
        LinearGradient(
            colors: [
                GardenTheme.cardWarm.opacity(isDisabled ? 0.82 : 1),
                GardenTheme.cardWarmLow.opacity(isDisabled ? 0.72 : 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var textColor: Color {
        if textRestsOnWater { return .white }
        return isDisabled ? GardenTheme.ink.opacity(0.46) : GardenTheme.leafDark
    }

    private func waterFill(width: CGFloat) -> some View {
        let fillWidth = clampedProgress <= 0 ? 0 : max(34, width * clampedProgress)

        return ZStack(alignment: .topLeading) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isReady
                            ? [GardenTheme.water.opacity(0.96), GardenTheme.waterDeep.opacity(0.96)]
                            : [GardenTheme.water.opacity(0.54), GardenTheme.water.opacity(0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: fillWidth)
    }
}

struct WhiteCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .gardenCardSurface()
    }
}

struct TodayStepCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .gardenCardSurface()
    }
}

private extension View {
    func gardenCardSurface(cornerRadius: CGFloat = 28) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            GardenTheme.cardWarm,
                            GardenTheme.cardWarmLow
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(GardenTheme.cardStroke.opacity(0.26), lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.6)
                .stroke(.white.opacity(0.38), lineWidth: 0.7)
        }
        .shadow(color: GardenTheme.cardShadow.opacity(0.12), radius: 18, x: 0, y: 9)
        .shadow(color: GardenTheme.cardShadow.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct PlantView: View {
    let stage: FlowerStage
    var assetName: String? = nil
    var mystery = false

    var body: some View {
        artwork
            .frame(width: 300, height: stage == .seed ? 230 : 350)
            .blur(radius: mystery ? 7 : 0)
            .saturation(mystery ? 0.1 : 1)
            .opacity(mystery ? 0.52 : 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var artwork: some View {
        if let assetName, let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(fallbackAssetName)
                .resizable()
                .scaledToFill()
                .clipped()
        }
    }

    private var fallbackAssetName: String {
        switch stage {
        case .seed:
            "HifiStageSeed"
        case .sprout, .bud:
            "HifiStageSprout"
        case .bloom:
            "HifiStageBloom"
        }
    }

}

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(GardenTheme.ink.opacity(0.94), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 24)
    }
}
