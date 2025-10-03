import Foundation

/// Minimal progress display using a 25-cell Braille bar.
/// Each cell represents up to 4% progress:
///  - 0%: space
///  - 1%: ⣀
///  - 2%: ⣤
///  - 3%: ⣶
///  - 4%: ⣿
final class ProgressDisplay {
    private var lastPercent: Int = -1
    private var lastUpdateTime: TimeInterval = 0
    private let frameInterval: TimeInterval

    // Bar settings: 25 cells × 4% = 100%
    private let barSegments: Int = 25

    /// - Parameters:
    ///   - frameInterval: Minimum seconds between visual updates (default ~6.7 FPS).
    init(frameInterval: TimeInterval = 0.15) {
        self.frameInterval = frameInterval
    }

    /// Update the progress display. This call is throttled to avoid flicker.
    func update(percent: Int) {
        let clamped = max(0, min(100, percent))
        let now = Date().timeIntervalSinceReferenceDate
        let shouldRender = (now - lastUpdateTime) >= frameInterval || clamped != lastPercent
        guard shouldRender else { return }

        lastUpdateTime = now
        lastPercent = clamped

        let bar = renderBar(for: clamped)
        let line = String(format: "\r%3d%% [%@]", clamped, bar)
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }

    func finish() {
        if let data = "\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }

    // MARK: - Rendering

    private func renderBar(for percent: Int) -> String {
        let totalUnits = percent // 1 unit per 1%
        let fullCells = totalUnits / 4
        let partialUnits = totalUnits % 4 // 0..3

        var cells: [String] = []
        cells.reserveCapacity(barSegments)

        for i in 0..<barSegments {
            if i < fullCells {
                cells.append("⣿")
            } else if i == fullCells && partialUnits > 0 {
                cells.append(charForPartial(units: partialUnits))
            } else {
                cells.append(" ")
            }
        }

        return cells.joined()
    }

    private func charForPartial(units: Int) -> String {
        switch units { // 1..3
        case 1: return "⣀" // 1%
        case 2: return "⣤" // 2%
        case 3: return "⣶" // 3%
        default: return " "
        }
    }
}

