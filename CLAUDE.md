# Jotty

macOS向けのオンデバイス音声文字起こしCLIツール。Apple Speech frameworkを使用。

## Build & Test

```bash
swift build --arch arm64 -c release --product jotty
swift test --arch arm64
```

## Architecture

- **Sources/jotty/** - CLI実行ターゲット (ArgumentParser, Speech framework)
- **Sources/TranscriptionCore/** - 共有ライブラリ (モデル, 出力フォーマット)
- **Tests/TranscriptionCoreTests/** - ユニットテスト (Swift Testing)

## Requirements

- macOS 26.0 (Tahoe) 以降
- Apple Silicon (arm64)
- Swift 6.3+

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI引数パーサー

## Notes

- `ProgressDisplay` は `@unchecked Sendable` — actor境界で使われるが、実際にはTranscriptionService actor内でのみアクセスされる
- 出力ファイル拡張子: `.jotty.txt` (text), `.jotty.json` (json)
- テストフレームワーク: Swift Testing (`import Testing`)
