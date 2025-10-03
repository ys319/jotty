import Foundation

enum Messages {
    static let outputExists = "Output exists at %@. Use --overwrite to regenerate."
    static let transcriptionCompleted = "Transcription completed."
    static let outputPath = "Output: %@"
    static let error = "Error: %@"
    static let unexpectedError = "Unexpected error: %@"

    static let modelMissing = "Speech model \"%@\" is not installed. Attempting download ..."
    static let modelDownloading = "Downloading model ..."
    static let modelInstalled = "Model installed."
    static let transcribingWithLocale = "Transcribing with locale \"%@\" ..."
}

