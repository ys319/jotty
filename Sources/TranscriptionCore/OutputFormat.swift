import Foundation

/// Enumerates the supported output formats and contains the related formatting logic.
/// Add a new case here when introducing additional export formats.
public enum OutputFormat: String, CaseIterable {
    case text
    case json

    /// File extension for the given format.
    public var fileExtension: String {
        switch self {
        case .text: return "jotty.txt"
        case .json: return "jotty.json"
        }
    }

    /// Converts transcription segments into the string representation for the current format.
    /// - Parameter segments: Segments that should be rendered.
    /// - Returns: Formatted string ready for writing to disk.
    /// - Throws: `TranscribeError.jsonEncodingFailed` if JSON encoding fails.
    public func formattedString(from segments: [TranscriptionSegment]) throws -> String {
        switch self {
        case .text:
            return formatAsPlainText(segments)
        case .json:
            return try formatAsJSON(segments)
        }
    }

    // MARK: - Private Formatting Logic

    private func formatAsPlainText(_ segments: [TranscriptionSegment]) -> String {
        segments.map {
            let startTime = formatTime($0.startTime)
            return "\(startTime): \($0.text)"
        }.joined(separator: "\n")
    }

    private func formatAsJSON(_ segments: [TranscriptionSegment]) throws -> String {
        let encodableSegments = segments.map(JSONOutputSegment.init)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let jsonData = try encoder.encode(encodableSegments)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            throw TranscribeError.jsonEncodingFailed(error)
        }
    }

    /// Helper that formats a `TimeInterval` as `HH:mm:ss.SSS`.
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
}
