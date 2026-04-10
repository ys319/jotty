import Foundation
import Testing
@testable import TranscriptionCore

@Suite("TranscriptionSegment")
struct TranscriptionSegmentTests {

    @Test func initializesWithCorrectValues() {
        let segment = TranscriptionSegment(text: "Hello", startTime: 1.0, endTime: 3.0, duration: 2.0)
        #expect(segment.text == "Hello")
        #expect(segment.startTime == 1.0)
        #expect(segment.endTime == 3.0)
        #expect(segment.duration == 2.0)
    }

    @Test func equatable() {
        let a = TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, duration: 1.0)
        let b = TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, duration: 1.0)
        let c = TranscriptionSegment(text: "World", startTime: 0.0, endTime: 1.0, duration: 1.0)
        #expect(a == b)
        #expect(a != c)
    }
}

@Suite("JSONOutputSegment")
struct JSONOutputSegmentTests {

    @Test func initFromTranscriptionSegment() {
        let segment = TranscriptionSegment(text: "Hello", startTime: 5.0, endTime: 8.0, duration: 3.0)
        let json = JSONOutputSegment(from: segment)
        #expect(json.text == "Hello")
        #expect(json.start == 5.0)
    }

    @Test func encodesAndDecodes() throws {
        let original = JSONOutputSegment(from: TranscriptionSegment(
            text: "Test", startTime: 1.5, endTime: 3.0, duration: 1.5
        ))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONOutputSegment.self, from: data)
        #expect(decoded == original)
    }
}

@Suite("TranscribeError")
struct TranscribeErrorTests {

    @Test func inputFileMissingDescription() {
        let error = TranscribeError.inputFileMissing(path: "/tmp/missing.wav")
        #expect(error.localizedDescription == "Input file not found: /tmp/missing.wav")
    }

    @Test func unsupportedLanguageDescription() {
        let error = TranscribeError.unsupportedLanguage("xx-YY")
        #expect(error.localizedDescription == "Language 'xx-YY' is not supported.")
    }

    @Test func audioFileReadFailedDescription() {
        let error = TranscribeError.audioFileReadFailed
        #expect(error.localizedDescription == "Failed to read the audio file.")
    }

    @Test func modelDownloadNotAvailableDescription() {
        let error = TranscribeError.modelDownloadNotAvailable
        #expect(error.localizedDescription == "Could not create a download request for the speech model.")
    }

    @Test func jsonEncodingFailedDescription() {
        struct Dummy: Error {}
        let error = TranscribeError.jsonEncodingFailed(Dummy())
        #expect(error.localizedDescription == "Failed to encode the results in JSON format.")
    }
}
