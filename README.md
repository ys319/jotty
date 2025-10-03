# Jotty 🎙️

A simple, on-device transcription utility for your audio files.

Slap an audio file in, get a text file out.

-----

## What is this thing?

Jotty is a no-frills command-line tool that uses Apple's Speech framework to transcribe your audio files. It's designed to be simple and work entirely on your machine.

It doesn't spew text into your console. Instead, it saves a transcript file, adding `.jotty.txt` or `.jotty.json` to your original file's name.

## Requirements

  - **macOS 26.0 (Tahoe)** or later

## Installation

### Homebrew

(wip)

```bash
$ brew tap ys319/homebrew-tap
$ brew install jotty
```

### Manual

Download the latest binary from the [Releases](https://github.com/ys319/jotty/releases) page.

## Usage

Just point it at an audio file.

```bash
# Get a plain text transcript
$ jotty ./meeting.mov

# Get a JSON output instead
$ jotty ./meeting.mov --format json

# Overwrite the old transcript if it exists
$ jotty ./meeting.mov --overwrite

# Transcribe a file in a specific language (e.g., Japanese)
$ jotty ./meeting.mov --language ja-JP
```

For all the details, here's the `--help` output:

```
OVERVIEW: On-device transcription utility for audio files.

Uses Apple's Speech framework to transcribe the provided audio file.
Required speech models are verified automatically and downloaded when needed.

USAGE: jotty <input-file-path> [--format <format>] [--language <language>] [--overwrite]

ARGUMENTS:
  <input-file-path>     Path to the audio file to transcribe.

OPTIONS:
  -f, --format <format> Output format ('text' or 'json'). (values: text, json; default: text)
  -l, --language <language>
                        BCP-47 identifier for the transcription language. Defaults to the first supported system language.
  --overwrite           Overwrite the output file if it already exists.
  -h, --help            Show help information.
```

## Disclaimer

Look, I'm no Swift expert. Most of this code was cobbled together with the help of Gemini and ChatGPT. It works for me, but your mileage may vary.

**So yeah, don't hold your breath for updates or bug fixes\!** 😉

## License

This project is licensed under the **MIT License**.
