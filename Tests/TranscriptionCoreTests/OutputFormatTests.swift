import Foundation
import Testing
@testable import TranscriptionCore

@Suite("OutputFormat")
struct OutputFormatTests {

    // MARK: - File Extension

    @Test func textFileExtension() {
        #expect(OutputFormat.text.fileExtension == "jotty.txt")
    }

    @Test func jsonFileExtension() {
        #expect(OutputFormat.json.fileExtension == "jotty.json")
    }

    // MARK: - Plain Text Formatting

    @Test func textFormatSingleSegment() throws {
        let segments = [
            TranscriptionSegment(text: "Hello world", startTime: 0.0, endTime: 1.5, duration: 1.5)
        ]
        let result = try OutputFormat.text.formattedString(from: segments)
        #expect(result == "00:00:00.000: Hello world")
    }

    @Test func textFormatMultipleSegments() throws {
        let segments = [
            TranscriptionSegment(text: "First segment", startTime: 0.0, endTime: 2.0, duration: 2.0),
            TranscriptionSegment(text: "Second segment", startTime: 2.0, endTime: 5.0, duration: 3.0),
        ]
        let result = try OutputFormat.text.formattedString(from: segments)
        let lines = result.split(separator: "\n")
        #expect(lines.count == 2)
        #expect(lines[0] == "00:00:00.000: First segment")
        #expect(lines[1] == "00:00:02.000: Second segment")
    }

    @Test func textFormatTimestampOverOneHour() throws {
        let segments = [
            TranscriptionSegment(text: "Late segment", startTime: 3723.456, endTime: 3730.0, duration: 6.544)
        ]
        let result = try OutputFormat.text.formattedString(from: segments)
        #expect(result == "01:02:03.456: Late segment")
    }

    @Test func textFormatEmptySegments() throws {
        let result = try OutputFormat.text.formattedString(from: [])
        #expect(result == "")
    }

    // MARK: - JSON Formatting

    @Test func jsonFormatSingleSegment() throws {
        let segments = [
            TranscriptionSegment(text: "Hello world", startTime: 1.5, endTime: 3.0, duration: 1.5)
        ]
        let result = try OutputFormat.json.formattedString(from: segments)
        let data = try #require(result.data(using: .utf8))
        let decoded = try JSONDecoder().decode([JSONOutputSegment].self, from: data)
        #expect(decoded.count == 1)
        #expect(decoded[0].text == "Hello world")
        #expect(decoded[0].start == 1.5)
    }

    @Test func jsonFormatEmptySegments() throws {
        let result = try OutputFormat.json.formattedString(from: [])
        let data = try #require(result.data(using: .utf8))
        let decoded = try JSONDecoder().decode([JSONOutputSegment].self, from: data)
        #expect(decoded.isEmpty)
    }

    @Test func jsonFormatIsPrettyPrinted() throws {
        let segments = [
            TranscriptionSegment(text: "Test", startTime: 0.0, endTime: 1.0, duration: 1.0)
        ]
        let result = try OutputFormat.json.formattedString(from: segments)
        #expect(result.contains("\n"))
    }
}
