import Foundation

public enum CheckCategory: String, Codable, Sendable, Equatable, CaseIterable {
    case file
    case pdf
    case pages
    case marks
    case colour
    case fonts
    case images
    case lines
}
