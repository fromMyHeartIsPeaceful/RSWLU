# 步步花园美术资产清单 v1

本清单用于后续替换当前 SwiftUI 占位美术。当前 App 仍使用 SwiftUI 绘制植物、花园岛和装饰元素；收到下列资源后，可导入到 `BuBuGarden/Assets.xcassets` 或 `BuBuGarden/Resources/Animations` 并替换对应视图。

## 交付目录

建议把素材包放在：

```text
IncomingArt/BuBuGardenAssets_v1/
  flowers/
  gardens/
  backgrounds/
  decorations/
  animations/
```

最终 App 内建议路径：

```text
BuBuGarden/Assets.xcassets/Flowers/
BuBuGarden/Assets.xcassets/Gardens/
BuBuGarden/Assets.xcassets/Backgrounds/
BuBuGarden/Assets.xcassets/Decorations/
BuBuGarden/Resources/Animations/
```

## 命名规则

花朵静态图命名：

```text
{gardenId}_{flowerSlug}_{stage}.png
```

阶段固定为：

```text
seed
sprout
bud
bloom
```

示例：

```text
dew_carnation_seed.png
dew_carnation_sprout.png
dew_carnation_bud.png
dew_carnation_bloom.png
```

## 推荐格式

静态花朵：

- 格式：透明背景 PNG。
- 色彩：sRGB。
- 推荐画布：1024 x 1024 px，主体居中，四周保留 8%-12% 安全边距。
- 缩略图不需要单独出图，App 可复用同一张并缩放。

动态花朵：

- 首选：Lottie JSON，每个阶段可选一个 idle loop。
- 次选：PNG 序列，透明背景，24 fps，建议 24-48 帧。
- 复杂透明短动画：HEVC with alpha `.mov`，仅用于较短庆祝或绽放动画。
- 不推荐：GIF/APNG 作为主资源。

花园/背景：

- 静态：透明 PNG 或全屏 PNG。
- 花园岛推荐画布：1600 x 1200 px，透明背景。
- 页面背景装饰推荐画布：1290 x 2796 px 或可平铺小纹理。

## 花朵资源

每朵花需要 4 个阶段。`priority = core` 表示前 10 朵普通收集核心花；`priority = premium` 表示高级版扩展花。

### dew / 晨露花园

| priority | flowerIndex | flowerName | flowerSlug | required files |
| --- | ---: | --- | --- | --- |
| core | 0 | 康乃馨 | carnation | `dew_carnation_{seed,sprout,bud,bloom}.png` |
| core | 1 | 蓝铃花 | bluebell | `dew_bluebell_{seed,sprout,bud,bloom}.png` |
| core | 2 | 晨光草 | morning_grass | `dew_morning_grass_{seed,sprout,bud,bloom}.png` |
| core | 3 | 蜜糖花 | honey_flower | `dew_honey_flower_{seed,sprout,bud,bloom}.png` |
| core | 4 | 橘风铃 | orange_bell | `dew_orange_bell_{seed,sprout,bud,bloom}.png` |
| core | 5 | 云边花 | cloud_flower | `dew_cloud_flower_{seed,sprout,bud,bloom}.png` |
| core | 6 | 雪绒花 | snow_fleece | `dew_snow_fleece_{seed,sprout,bud,bloom}.png` |
| core | 7 | 小蔷薇 | mini_rose | `dew_mini_rose_{seed,sprout,bud,bloom}.png` |
| core | 8 | 雨点兰 | raindrop_orchid | `dew_raindrop_orchid_{seed,sprout,bud,bloom}.png` |
| core | 9 | 星点草 | stargrass | `dew_stargrass_{seed,sprout,bud,bloom}.png` |
| premium | 10 | 金盏花 | marigold | `dew_marigold_{seed,sprout,bud,bloom}.png` |
| premium | 11 | 玻璃玫瑰 | glass_rose | `dew_glass_rose_{seed,sprout,bud,bloom}.png` |

### creek / 溪畔花园

| priority | flowerIndex | flowerName | flowerSlug | required files |
| --- | ---: | --- | --- | --- |
| core | 0 | 溪石花 | creekstone | `creek_creekstone_{seed,sprout,bud,bloom}.png` |
| core | 1 | 苔影兰 | moss_orchid | `creek_moss_orchid_{seed,sprout,bud,bloom}.png` |
| core | 2 | 青豆芽 | pea_sprout | `creek_pea_sprout_{seed,sprout,bud,bloom}.png` |
| core | 3 | 水纹菊 | ripple_daisy | `creek_ripple_daisy_{seed,sprout,bud,bloom}.png` |
| core | 4 | 芦叶花 | reed_flower | `creek_reed_flower_{seed,sprout,bud,bloom}.png` |
| core | 5 | 小睡莲 | mini_waterlily | `creek_mini_waterlily_{seed,sprout,bud,bloom}.png` |
| core | 6 | 银露草 | silver_dew | `creek_silver_dew_{seed,sprout,bud,bloom}.png` |
| core | 7 | 风铃藤 | windbell_vine | `creek_windbell_vine_{seed,sprout,bud,bloom}.png` |
| core | 8 | 浅蓝鸢尾 | pale_blue_iris | `creek_pale_blue_iris_{seed,sprout,bud,bloom}.png` |
| core | 9 | 月白花 | moonwhite_flower | `creek_moonwhite_flower_{seed,sprout,bud,bloom}.png` |
| premium | 10 | 琥珀莲 | amber_lotus | `creek_amber_lotus_{seed,sprout,bud,bloom}.png` |
| premium | 11 | 星河藤 | galaxy_vine | `creek_galaxy_vine_{seed,sprout,bud,bloom}.png` |

### star / 星光温室

| priority | flowerIndex | flowerName | flowerSlug | required files |
| --- | ---: | --- | --- | --- |
| core | 0 | 夜灯花 | night_lamp | `star_night_lamp_{seed,sprout,bud,bloom}.png` |
| core | 1 | 星砂草 | star_sand | `star_star_sand_{seed,sprout,bud,bloom}.png` |
| core | 2 | 蓝月兰 | blue_moon_orchid | `star_blue_moon_orchid_{seed,sprout,bud,bloom}.png` |
| core | 3 | 银边菊 | silver_edge_daisy | `star_silver_edge_daisy_{seed,sprout,bud,bloom}.png` |
| core | 4 | 云母藤 | mica_vine | `star_mica_vine_{seed,sprout,bud,bloom}.png` |
| core | 5 | 柔光蔷薇 | softlight_rose | `star_softlight_rose_{seed,sprout,bud,bloom}.png` |
| core | 6 | 霜点草 | frostdot_grass | `star_frostdot_grass_{seed,sprout,bud,bloom}.png` |
| core | 7 | 灯芯花 | lamplight_flower | `star_lamplight_flower_{seed,sprout,bud,bloom}.png` |
| core | 8 | 薄雾莲 | mist_lotus | `star_mist_lotus_{seed,sprout,bud,bloom}.png` |
| core | 9 | 晚安花 | goodnight_flower | `star_goodnight_flower_{seed,sprout,bud,bloom}.png` |
| premium | 10 | 金星花 | venus_flower | `star_venus_flower_{seed,sprout,bud,bloom}.png` |
| premium | 11 | 水晶兰 | crystal_orchid | `star_crystal_orchid_{seed,sprout,bud,bloom}.png` |

> 注意：上表共 3 个花园 x 12 朵花 x 4 阶段 = 144 张静态花朵 PNG。若首版只做普通收集核心，则优先 3 个花园 x 10 朵花 x 4 阶段 = 120 张。

## 花园资源

| asset | required file | optional files | notes |
| --- | --- | --- | --- |
| 晨露花园岛 | `dew_garden_island_unlocked.png` | `dew_garden_island_locked.png`, `dew_garden_island_complete.png` | 图鉴页主视觉 |
| 溪畔花园岛 | `creek_garden_island_unlocked.png` | `creek_garden_island_locked.png`, `creek_garden_island_complete.png` | 解锁后使用 |
| 星光温室 | `star_greenhouse_island_unlocked.png` | `star_greenhouse_island_locked.png`, `star_greenhouse_island_complete.png` | 高级版/特殊花园 |

## 背景与装饰资源

| asset | file | format | notes |
| --- | --- | --- | --- |
| 启动页窗景 | `onboarding_window_light.png` | PNG | 背景窗景/植物光影 |
| 授权页光影 | `health_window_light.png` | PNG | 可复用启动页风格 |
| 今日页背景光 | `today_light_wash.png` | PNG | 植物舞台后方轻背景 |
| 品牌小花 logo | `daisy_logo.png` | PNG/SVG source | App 内最终建议 PNG asset 或 PDF vector |
| 叶子装饰 | `leaf_accent.png` | PNG | 我们页/卡片装饰 |
| 花盆底座 | `plant_pot_base.png` | PNG | 如果各花共用花盆，可单独提供 |
| 植物投影 | `plant_ground_shadow.png` | PNG | 可共用，透明渐变 |
| 浇水反馈 | `watering_success_burst.json` | Lottie JSON | 浇水成功反馈 |
| 绽放庆祝 | `flower_bloom_celebration.json` | Lottie JSON | 花朵完成页 |

## 动态资源命名

花朵 idle 动画：

```text
animations/flowers/{gardenId}_{flowerSlug}_{stage}_idle.json
```

阶段转场动画：

```text
animations/flowers/{gardenId}_{flowerSlug}_{fromStage}_to_{toStage}.json
```

示例：

```text
animations/flowers/dew_carnation_seed_idle.json
animations/flowers/dew_carnation_seed_to_sprout.json
animations/flowers/dew_carnation_bud_to_bloom.json
```

## 导入后的 App 映射建议

后续接入真实资产时，建议新增：

```swift
struct FlowerAssetKey {
    let gardenId: String
    let flowerIndex: Int
    let stage: FlowerStage
}
```

然后使用 `Garden.catalog` 中的 `gardenId + flowerIndex` 映射到 `flowerSlug`，在 `FlowerAssetView` 中加载：

```text
{gardenId}_{flowerSlug}_{stage.rawValue}
```

这样现有业务逻辑不需要改，只替换当前 SwiftUI 占位 `PlantView` 的渲染来源。
