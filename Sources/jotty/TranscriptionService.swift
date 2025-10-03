import AVFoundation
import Foundation
import Speech
import TranscriptionCore

/// Actor responsible for coordinating model availability and transcription.
actor TranscriptionService {

    init() {}

    /// Transcribes the provided audio file and returns the resulting segments.
    /// - Parameters:
    ///   - fileURL: Location of the audio file that should be transcribed.
    ///   - locale: Locale configured for transcription.
    /// - Returns: Recognised segments.
    /// - Throws: `TranscribeError` when validation or transcription fails.
    func transcribe(file fileURL: URL, locale: Locale) async throws -> [TranscriptionSegment] {
        guard await isLocaleSupported(locale) else {
            throw TranscribeError.unsupportedLanguage(locale.identifier)
        }

        try await ensureModelIsAvailable(for: locale)
        return try await transcribeWithSpeechFramework(file: fileURL, locale: locale)
    }

    // MARK: - Private helpers

    private func isLocaleSupported(_ locale: Locale) async -> Bool {
        let supportedLocales = await SpeechTranscriber.supportedLocales
        let targetIdentifier = locale.identifier(.bcp47)
        return supportedLocales.contains { $0.identifier(.bcp47) == targetIdentifier }
    }

    private func ensureModelIsAvailable(for locale: Locale) async throws {
        let localeIdentifier = locale.identifier(.bcp47)
        let isInstalled = await SpeechTranscriber.installedLocales.contains {
            $0.identifier(.bcp47) == localeIdentifier
        }
        if isInstalled { return }
        try await downloadModel(for: locale)
    }

    private func downloadModel(for locale: Locale) async throws {
        let localeIdentifier = locale.identifier(.bcp47)
        print(String(format: Messages.modelMissing, localeIdentifier))

        guard
            let request = try await AssetInventory.assetInstallationRequest(
                supporting: [
                    SpeechTranscriber(
                        locale: Locale(identifier: localeIdentifier),
                        preset: SpeechTranscriber.Preset.timeIndexedProgressiveTranscription
                    )
                ]
            )
        else {
            throw TranscribeError.modelDownloadNotAvailable
        }

        print(Messages.modelDownloading)
        try await request.downloadAndInstall()
        print(Messages.modelInstalled)
    }

    private func transcribeWithSpeechFramework(file fileURL: URL, locale: Locale) async throws -> [TranscriptionSegment] {
        let localeIdentifier = locale.identifier(.bcp47)

        guard let audioFile = try? AVAudioFile(forReading: fileURL) else {
            throw TranscribeError.audioFileReadFailed
        }

        let transcriber = SpeechTranscriber(
            locale: Locale(identifier: localeIdentifier),
            preset: .timeIndexedProgressiveTranscription
        )
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let segmentCollector = SegmentCollector()
        let progress = ProgressDisplay()

        async let analyzing: Void = try analyzer.start(
            inputAudioFile: audioFile,
            finishAfterFile: true
        )

        print(String(format: Messages.transcribingWithLocale, localeIdentifier))
        await collectSegments(from: transcriber, audioFile: audioFile, progress: progress, collector: segmentCollector)

        try await analyzing
        let hasDuration = audioFile.fileFormat.sampleRate > 0 && audioFile.length > 0
        if hasDuration { progress.update(percent: 100) }
        progress.finish()

        return await segmentCollector.segments
    }

    private func collectSegments(from transcriber: SpeechTranscriber, audioFile: AVAudioFile, progress: ProgressDisplay, collector: SegmentCollector) async {
        var prev: SpeechTranscriber.Result? = nil
        let totalSeconds = audioFile.fileFormat.sampleRate > 0
            ? Double(audioFile.length) / audioFile.fileFormat.sampleRate
            : 0

        do {
            for try await result in transcriber.results {
                // Update progress based on the latest known end time in the audio stream.
                if totalSeconds > 0 {
                    let currentEnd = (result.text.audioTimeRange ?? prev?.text.audioTimeRange)?.end.seconds ?? 0
                    let percent = Int((currentEnd / totalSeconds) * 100)
                    progress.update(percent: percent)
                }

                if let segment = TranscriptionSegment(from: result, prev: prev ?? result) {
                    if result.isFinal {
                        await collector.append(segment)
                    }
                }
                prev = result
            }
        } catch {
            // Errors are handled by the caller.
        }
    }
}

/// Helper actor that safely gathers segments produced by the analyzer.
private actor SegmentCollector {
    private var storage: [TranscriptionSegment] = []

    func append(_ segment: TranscriptionSegment) {
        storage.append(segment)
    }

    var segments: [TranscriptionSegment] {
        storage
    }
}

