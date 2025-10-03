import CoreMedia
import Foundation
import Speech

/// Value type that represents a single transcription segment.
/// Encapsulates the transformation from raw `SpeechAnalyzer.Result` instances.
public struct TranscriptionSegment: Equatable, Sendable {
    /// Recognised text for the segment.
    let text: String
    /// Segment start time in seconds.
    let startTime: TimeInterval
    /// Segment end time in seconds.
    let endTime: TimeInterval
    /// Segment duration in seconds.
    let duration: TimeInterval

    /// Convenience initializer used by tests to construct segments directly.
    public init(text: String, startTime: TimeInterval, endTime: TimeInterval, duration: TimeInterval) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }

    /// Failable initializer that converts from a `SpeechTranscriber.Result`.
    /// Returns `nil` when timestamp metadata is not available.
    public init?(from result: SpeechTranscriber.Result, prev: SpeechTranscriber.Result) {

        // Some final results do not contain timestamps, so fall back to the previous interim output.
        guard let timeRange = (result.text.audioTimeRange ?? prev.text.audioTimeRange) else {
            // Ignore partial results that do not include timing information.
            return nil
        }
        // Trim whitespace so only meaningful text is kept.
        let trimmedText = String(result.text.characters)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            // Skip segments that only contain whitespace.
            return nil
        }

        self.text = trimmedText
        self.startTime = timeRange.start.seconds
        self.endTime = timeRange.end.seconds
        self.duration = timeRange.duration.seconds
    }
}

/// Codable shape that mirrors `TranscriptionSegment` for JSON serialization.
public struct JSONOutputSegment: Codable, Equatable, Sendable {
    public let start: TimeInterval
    public let text: String

    public init(from segment: TranscriptionSegment) {
        self.start = segment.startTime
        self.text = segment.text
    }
}

/// Application-specific errors surfaced by the transcription workflow.
public enum TranscribeError: Error, LocalizedError {
    case inputFileMissing(path: String)
    case unsupportedLanguage(String)
    case audioFileReadFailed
    case modelDownloadNotAvailable
    case jsonEncodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .inputFileMissing(let path):
            return "Input file not found: \(path)"
        case .unsupportedLanguage(let lang):
            return "Language '\(lang)' is not supported."
        case .audioFileReadFailed:
            return "Failed to read the audio file."
        case .modelDownloadNotAvailable:
            return "Could not create a download request for the speech model."
        case .jsonEncodingFailed:
            return "Failed to encode the results in JSON format."
        }
    }
}
