import Foundation

/// Errors thrown during PDF parsing.
public enum ParsingError: Error, Sendable, Equatable {
    case fileNotFound(URL)
    case cannotOpenPDF(URL)
    case encrypted(URL)
}
