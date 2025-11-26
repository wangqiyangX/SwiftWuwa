import Foundation

/// Catalogue categories available on the wiki
enum EncyclopediaCategory: String, CaseIterable, Identifiable {
    case characters = "共鸣者"
    case weapons = "武器"
    case weaponProjections = "武器投影"
    case echoes = "声骸"
    case resonanceEffects = "合鸣效果"
    case enemies = "敌人"
    case holographicStrategy = "全息战略"
    case craftableItems = "可合成道具"
    case craftingBlueprints = "道具合成图纸"
    case specialItems = "特殊道具"
    case supplies = "补给"
    case resources = "资源"
    case materials = "素材"
    case journeyStamps = "羁旅印章"
    case avatars = "头像"

    var id: String { rawValue }

    /// The catalogue ID (sid parameter) for this category
    /// IDs start from 1105 and increment by 1
    var catalogueID: Int {
        switch self {
        case .characters: return 1105
        case .weapons: return 1106
        case .weaponProjections: return 1315
        case .echoes: return 1107
        case .resonanceEffects: return 1219
        case .enemies: return 1158
        case .holographicStrategy: return 1313
        case .craftableItems: return 1264
        case .craftingBlueprints: return 1265
        case .specialItems: return 1223
        case .supplies: return 1217
        case .resources: return 1161
        case .materials: return 1218
        case .journeyStamps: return 1350
        case .avatars: return 1363
        }
    }

    /// Build the catalogue URL for this category
    func buildURL() -> URL {
        URL(string: "https://wiki.kurobbs.com/mc/catalogue/list?fid=1099&sid=\(catalogueID)")!
    }
}
