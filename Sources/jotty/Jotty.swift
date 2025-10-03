import ArgumentParser
import Foundation
import Speech
import TranscriptionCore

/// Entry point for the transcription command line tool.
/// Parses user input and orchestrates the execution flow.
// Make OutputFormat usable as a CLI argument in this target
extension OutputFormat: ExpressibleByArgument {}

@main
struct Jotty: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "jotty",
        abstract: "On-device transcription utility for audio files.",
        discussion: """
            Uses Apple's Speech framework to transcribe the provided audio file.
            Required speech models are verified automatically and downloaded when needed.
            """
    )

    // MARK: - Command Line Arguments

    @Argument(help: "Path to the audio file to transcribe.")
    var inputFilePath: String

    @Option(name: .shortAndLong, help: "Output format ('text' or 'json').")
    var format: OutputFormat = .text

    @Option(
        name: .shortAndLong,
        help: "BCP-47 identifier for the transcription language. Defaults to the first supported system language."
    )
    var language: String?

    @Flag(name: .long, help: "Overwrite the output file if it already exists.")
    var overwrite: Bool = false

    // MARK: - Execution Logic

    @MainActor
    func run() async {
        do {
            // 1. Validate the input file
            let fileURL = try validateInputFile(path: inputFilePath)
            let destinationURL = outputURL(for: fileURL)

            if FileManager.default.fileExists(atPath: destinationURL.path), !overwrite {
                print(String(format: Messages.outputExists, destinationURL.path))
                return
            }

            let locale = await resolvePreferredLocale(explicitLanguage: language)

            // 2. Transcribe the audio file
            let segments = try await TranscriptionService().transcribe(file: fileURL, locale: locale)

            // 3. Format and write the output
            try writeOutput(for: segments, to: destinationURL)

            print(Messages.transcriptionCompleted)
            print(String(format: Messages.outputPath, destinationURL.path))
        } catch let error as TranscribeError {
            print(String(format: Messages.error, error.localizedDescription))
            Foundation.exit(1)
        } catch {
            print(String(format: Messages.unexpectedError, error.localizedDescription))
            Foundation.exit(1)
        }
    }

    // MARK: - Private Helper Methods

    /// Validates that the provided path points to an existing file and returns its URL.
    private func validateInputFile(path: String) throws -> URL {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscribeError.inputFileMissing(path: path)
        }
        return url
    }

    /// Writes the transcription result to disk in the selected format.
    private func writeOutput(for segments: [TranscriptionSegment], to destinationURL: URL) throws {
        let outputString = try format.formattedString(from: segments)
        try outputString.write(to: destinationURL, atomically: true, encoding: .utf8)
    }

    /// Derives the destination file URL based on the selected output format.
    private func outputURL(for sourceURL: URL) -> URL {
        sourceURL
            .deletingPathExtension()
            .appendingPathExtension(self.format.fileExtension)
    }

    // MARK: - Locale Resolution (simplified)

    /// Resolves a preferred transcription `Locale` using supported locales and system preferences.
    @MainActor
    private func resolvePreferredLocale(explicitLanguage: String?) async -> Locale {
        let supported = await SpeechTranscriber.supportedLocales

        if let explicitLanguage {
            if let matched = matchLocale(for: explicitLanguage, in: supported) {
                return matched
            }
            return Locale(identifier: explicitLanguage)
        }

        for identifier in orderedUniqueLanguageIdentifiers(systemLanguageIdentifiers()) {
            if let matched = matchLocale(for: identifier, in: supported) {
                return matched
            }
        }

        return supported.first { $0.language.languageCode?.identifier == "en" }
            ?? supported.first
            ?? Locale(identifier: "en-US")
    }

    private func matchLocale(for identifier: String, in supportedLocales: [Locale]) -> Locale? {
        let lowered = identifier.lowercased()
        if let exact = supportedLocales.first(where: { $0.identifier(.bcp47).lowercased() == lowered }) {
            return exact
        }
        if let base = lowered.split(separator: "-").first.map(String.init) {
            if let baseMatch = supportedLocales.first(where: { $0.language.languageCode?.identifier == base }) {
                return baseMatch
            }
        }
        return nil
    }

    private func systemLanguageIdentifiers() -> [String] {
        var identifiers: [String] = [Locale.current.identifier(.bcp47)]
        identifiers.append(contentsOf: Locale.preferredLanguages)
        return identifiers
    }

    private func orderedUniqueLanguageIdentifiers(_ identifiers: [String]) -> [String] {
        var seen: Set<String> = []
        var unique: [String] = []
        for id in identifiers {
            let lowered = id.lowercased()
            guard !lowered.isEmpty, !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            unique.append(id)
        }
        return unique
    }
}
