# SongGeneration – Detailed Usage Guide

This guide provides step-by-step instructions for setting up and using **SongGeneration / LeVo 2** to generate AI music from lyrics.

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [Installation](#2-installation)
   - [Option A – Install from Source](#option-a--install-from-source)
   - [Option B – Docker (Pre-built Image)](#option-b--docker-pre-built-image)
   - [Option C – Docker (Build Your Own)](#option-c--docker-build-your-own)
3. [Downloading Model Weights](#3-downloading-model-weights)
4. [Quick Start](#4-quick-start)
5. [CLI Usage (Batch Generation)](#5-cli-usage-batch-generation)
   - [Basic Command](#basic-command)
   - [All CLI Flags](#all-cli-flags)
   - [Generation Modes](#generation-modes)
   - [Example Commands](#example-commands)
6. [Gradio Web UI](#6-gradio-web-ui)
   - [Starting the UI](#starting-the-ui)
   - [UI Walkthrough](#ui-walkthrough)
7. [Input Format Reference](#7-input-format-reference)
   - [JSONL File Format](#jsonl-file-format)
   - [Lyrics Formatting](#lyrics-formatting)
   - [Description Tags](#description-tags)
   - [Audio Prompt](#audio-prompt)
8. [Output Files](#8-output-files)
9. [Memory Optimisation](#9-memory-optimisation)
10. [Troubleshooting](#10-troubleshooting)
11. [FAQ](#11-faq)

---

## 1. System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | Linux (Ubuntu 20.04+) | Linux (Ubuntu 22.04+) |
| Python | 3.8.12+ | 3.10+ |
| CUDA | 11.8 | 12.0+ |
| GPU (VRAM) | 10 GB (base, no prompt) | 22–28 GB (large models) |
| RAM | 32 GB | 64 GB |
| Disk space | ~30 GB (model + runtime) | ~50 GB |

> **VRAM note:**
> - `SongGeneration-base` / `SongGeneration-base-new`: 10 GB (no prompt) / 16 GB (with prompt)
> - `SongGeneration-base-full`: 12 GB / 18 GB
> - `SongGeneration-large` / `SongGeneration-v2-large`: 22 GB / 28 GB

---

## 2. Installation

### Option A – Install from Source

**Step 1 – Clone the repository**

```bash
git clone https://github.com/tencent-ailab/SongGeneration.git
cd SongGeneration
```

**Step 2 – Create and activate a virtual environment** *(recommended)*

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Or with conda:

```bash
conda create -n songgen python=3.10
conda activate songgen
```

**Step 3 – Install core dependencies**

```bash
pip install -r requirements.txt
pip install -r requirements_nodeps.txt --no-deps
```

**Step 4 – (Optional) Install Flash Attention for faster inference**

Flash Attention significantly speeds up generation. Install the wheel that matches your Python version and CUDA version.

*Example for Python 3.10 + CUDA 12.0:*

```bash
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
```

Browse all available Flash Attention wheels at https://github.com/Dao-AILab/flash-attention/releases

---

### Option B – Docker (Pre-built Image)

The easiest way to get started without any environment setup:

```bash
# Pull the pre-built Docker image
docker pull juhayna/song-generation-levo:hf0613

# Run the container with GPU access
docker run -it --gpus all --network=host \
  -v $(pwd)/models:/workspace/models \
  juhayna/song-generation-levo:hf0613 /bin/bash
```

Inside the container, the repository is already set up. Proceed to [Downloading Model Weights](#3-downloading-model-weights).

---

### Option C – Docker (Build Your Own)

A `Dockerfile` is included in the repository root for building a custom image.

```bash
# Build the image
docker build -t songgeneration:local .

# Run the container
docker run -it --gpus all --network=host \
  -v $(pwd)/models:/workspace/models \
  -p 8081:8081 \
  songgeneration:local /bin/bash
```

**Using Docker Compose** *(recommended for the Web UI)*:

```bash
# Start the Gradio Web UI service
docker compose up

# The UI will be available at http://localhost:8081
```

> You must populate the `./models` directory with the downloaded model weights before running Docker Compose. See [Downloading Model Weights](#3-downloading-model-weights).

---

## 3. Downloading Model Weights

All model weights are hosted on Hugging Face. You need **two parts**:

1. **Runtime files** – shared codec, tokenizer, and third-party components
2. **Model checkpoint** – the specific version of the generation model

### Step 1 – Download runtime files

```bash
# Install huggingface-cli if not already available
pip install huggingface_hub

# Download shared runtime (codec + third-party dependencies)
huggingface-cli download lglg666/SongGeneration-Runtime --local-dir ./runtime
mv runtime/ckpt ckpt
mv runtime/third_party third_party
```

### Step 2 – Download a model checkpoint

Choose the model that fits your VRAM and language needs:

| Model | Max Length | Languages | Min VRAM | Download |
|-------|-----------|-----------|---------|--------|
| `SongGeneration-base` | 2m 30s | Chinese | 10 GB | [HF](https://huggingface.co/tencent/SongGeneration/tree/main/ckpt/songgeneration_base) |
| `SongGeneration-base-new` | 2m 30s | Chinese, English | 10 GB | [HF](https://huggingface.co/lglg666/SongGeneration-base-new) |
| `SongGeneration-base-full` | 4m 30s | Chinese, English | 12 GB | [HF](https://huggingface.co/lglg666/SongGeneration-base-full) |
| `SongGeneration-large` | 4m 30s | Chinese, English | 22 GB | [HF](https://huggingface.co/lglg666/SongGeneration-large) |
| `SongGeneration-v2-large` | 4m 30s | zh, en, es, ja, … | 22 GB | [HF](https://huggingface.co/lglg666/SongGeneration-v2-large) |

```bash
# Examples – pick ONE that matches your hardware:

# Lowest VRAM – Chinese only, up to 2m 30s
huggingface-cli download lglg666/SongGeneration-base-new --local-dir ./songgeneration_base_new

# Recommended – multilingual, full-length
huggingface-cli download lglg666/SongGeneration-v2-large --local-dir ./songgeneration_v2_large
```

### Expected directory structure after download

```
SongGeneration/
├── ckpt/                      ← shared runtime checkpoint
├── third_party/               ← codec, tokenizer and other dependencies
├── songgeneration_base_new/   ← (or whichever model you chose)
├── generate.py
├── generate.sh
└── ...
```

---

## 4. Quick Start

After completing installation and model download, generate your first song with:

```bash
sh generate.sh songgeneration_base_new sample/lyrics.jsonl sample/output
```

This uses the provided sample lyrics file and saves the generated audio under `sample/output/audio/`.

For an interactive Web UI, skip directly to [Section 6](#6-gradio-web-ui).

---

## 5. CLI Usage (Batch Generation)

### Basic Command

```bash
sh generate.sh <ckpt_path> <input.jsonl> <output_dir> [flags]
```

| Argument | Description |
|----------|-------------|
| `ckpt_path` | Path to the model checkpoint directory |
| `input.jsonl` | JSON Lines file – one generation request per line |
| `output_dir` | Directory where generated audio files will be saved |

### All CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| *(none)* | – | Mixed vocals + accompaniment (default) |
| `--separate` | – | Generate vocals and accompaniment as **separate tracks** |
| `--bgm` | – | Generate **pure background music** (no vocals) |
| `--vocal` | – | Generate **vocals only** (a cappella) |
| `--low_mem` | off | Reduce VRAM usage (enables model offloading) |
| `--not_use_flash_attn` | off | Disable Flash Attention (use if not installed) |

### Generation Modes

| Mode | Flag | Output |
|------|------|--------|
| Mixed (default) | *(none)* | Single file with vocals + accompaniment |
| Separate | `--separate` | Two files: `*_vocal.wav` and `*_bgm.wav` |
| Pure music | `--bgm` | Single file with accompaniment only |
| Vocals only | `--vocal` | Single file with vocals only |

### Example Commands

**Standard generation:**
```bash
sh generate.sh songgeneration_v2_large sample/lyrics.jsonl outputs/
```

**Low VRAM (< 16 GB):**
```bash
sh generate.sh songgeneration_base_new sample/lyrics.jsonl outputs/ --low_mem
```

**Without Flash Attention:**
```bash
sh generate.sh songgeneration_base_new sample/lyrics.jsonl outputs/ --not_use_flash_attn
```

**Generate separate vocal and accompaniment tracks:**
```bash
sh generate.sh songgeneration_v2_large sample/lyrics.jsonl outputs/ --separate
```

**Pure instrumental music:**
```bash
sh generate.sh songgeneration_v2_large sample/lyrics.jsonl outputs/ --bgm
```

**Combine flags:**
```bash
sh generate.sh songgeneration_base_new sample/lyrics.jsonl outputs/ --low_mem --not_use_flash_attn
```

---

## 6. Gradio Web UI

The Web UI provides an interactive browser-based interface for generating songs without writing JSONL files.

### Starting the UI

```bash
sh tools/gradio/run.sh <ckpt_path>
```

Example:

```bash
sh tools/gradio/run.sh songgeneration_v2_large
```

The server starts on **port 8081** and listens on all interfaces. Open your browser at:

```
http://localhost:8081
```

If running on a remote server, replace `localhost` with the server's IP address, or set up SSH port forwarding:

```bash
# On your local machine
ssh -L 8081:localhost:8081 user@remote-server
```

Then open `http://localhost:8081` in your local browser.

### UI Walkthrough

The Web UI has the following sections:

#### Lyrics Input

Enter your song lyrics using the structured format. Each paragraph is a musical section:

```
[intro-short]

[verse]
Line one of verse
Line two of verse
Line three of verse

[chorus]
Line one of chorus
Line two of chorus

[outro-short]
```

- Instrumental sections (`[intro-*]`, `[inst-*]`, `[outro-*]`) must be empty.
- Lyric sections (`[verse]`, `[chorus]`, `[bridge]`) must contain at least one line.
- Each section must be separated by a **blank line**.

#### Style Control (tabs below lyrics)

Choose **one** of three ways to control the musical style:

1. **Genre Select** – Pick a genre from the radio buttons (Pop, Rock, Electronic, Jazz, etc.)
2. **Audio Prompt** – Upload a 10-second reference audio clip. The model will match its style.
3. **Text Prompt** – Type comma-separated style tags (e.g., `female, sad, pop, piano and drums`)

> Only one style source is used at a time. Audio Prompt takes priority over the others.

#### Advanced Config *(optional)*

Click **Advanced Config** to expose generation parameters:

| Parameter | Default | Effect |
|-----------|---------|--------|
| CFG Coefficient | 1.5 | Higher = stronger adherence to the style prompt |
| Temperature | 0.9 | Higher = more creative / varied output |
| Top-K | 50 | Lower = more deterministic; higher = more diverse |

#### Generate Buttons

- **Generate Song** – Generates a song with vocals and accompaniment.
- **Generate Pure Music** – Generates background music without vocals.

#### Output

- **Generated Song** – Audio player with download button.
- **Generated Info** – JSON with the exact input configuration and inference duration.

---

## 7. Input Format Reference

### JSONL File Format

Each line in your `.jsonl` file is a JSON object with the following fields:

| Field | Required | Description |
|-------|----------|-------------|
| `idx` | ✅ | Unique ID used as the output filename |
| `gt_lyric` | ✅ | Structured lyrics string (see [Lyrics Formatting](#lyrics-formatting)) |
| `descriptions` | ✅ / optional | Comma-separated style tags (see [Description Tags](#description-tags)) |
| `prompt_audio_path` | ✅ / optional | Path to a 10-second reference `.wav` file |
| `auto_prompt_audio_type` | optional | Auto-select a reference style; ignored if `prompt_audio_path` is set |

**Priority rule:** `prompt_audio_path` > `descriptions` > `auto_prompt_audio_type`

#### Example JSONL lines

*With audio prompt (overrides text descriptions):*
```json
{"idx": "song_01", "gt_lyric": "[intro-short] ; [verse] Line one.Line two. ; [chorus] Refrain one.Refrain two. ; [outro-short]", "descriptions": "female, pop, happy", "prompt_audio_path": "sample/sample_prompt_audio.wav"}
```

*With text description only:*
```json
{"idx": "song_02", "gt_lyric": "[intro-short] ; [verse] Line one.Line two. ; [chorus] Refrain one.Refrain two. ; [outro-short]", "descriptions": "male, dark, hip hop, sad, piano and drums, the bpm is 95."}
```

*With auto prompt:*
```json
{"idx": "song_03", "gt_lyric": "[intro-short] ; [verse] Line one.Line two. ; [chorus] Refrain one.Refrain two. ; [outro-short]", "auto_prompt_audio_type": "Jazz"}
```

*No style control:*
```json
{"idx": "song_04", "gt_lyric": "[intro-short] ; [verse] Line one.Line two. ; [chorus] Refrain one.Refrain two. ; [outro-short]"}
```

---

### Lyrics Formatting

The `gt_lyric` field is a single string where sections are separated by ` ; `.

#### Section types

| Type | Tag | Requires lyrics? | Approx. duration |
|------|-----|-----------------|-----------------|
| Intro (short) | `[intro-short]` | No | 0–10 s |
| Intro (medium) | `[intro-medium]` | No | 10–20 s |
| Intro (long) | `[intro-long]` | No | > 20 s |
| Verse | `[verse]` | **Yes** | variable |
| Chorus | `[chorus]` | **Yes** | variable |
| Bridge | `[bridge]` | **Yes** | variable |
| Instrumental (short) | `[inst-short]` | No | 0–10 s |
| Instrumental (medium) | `[inst-medium]` | No | 10–20 s |
| Instrumental (long) | `[inst-long]` | No | > 20 s |
| Outro (short) | `[outro-short]` | No | 0–10 s |
| Outro (medium) | `[outro-medium]` | No | 10–20 s |
| Outro (long) | `[outro-long]` | No | > 20 s |
| Silence | `[silence]` | No | variable |

#### Punctuation rules

- Use **only English punctuation** (`.`, `,`). This applies even when writing Chinese lyrics — do **not** use Chinese punctuation marks (`。`, `，`, `！`, `？`, `、`).
- Separate sentences within a lyric section with a period (`.`).
- **English lyrics:** End the last sentence in a section with a period (`.`).
- **Chinese lyrics:** Do **not** add a period at the end of the last phrase.

#### English example

```
[intro-medium] ; [verse] Trails wind through the forest.Trees stand tall and honest.Birds sing in the branches. ; [chorus] Forest is the sanctuary where the promise does fondest.Is the peace that makes the restless heart honest. ; [outro-short]
```

#### Chinese example

```
[intro-short] ; [verse] 夜晚的街灯闪烁.我漫步在熟悉的角落.回忆像潮水般涌来 ; [chorus] 这里是城市的守夜人.收容所有流浪的灵魂 ; [outro-short]
```

---

### Description Tags

Use comma-separated keywords from these categories:

**Gender:** `male`, `female`, `mixed`

**Genre** (select a few from the list):
```
pop, rock, hip-hop, jazz, electronic, ballad, latin, folk, country, r&b, soul,
funk, blues, edm, synth-pop, indie pop, acoustic, orchestral, classical, …
```
*Full list: `sample/description/genre.txt` (300+ genres)*

**Emotion** (select one or two):
```
energetic, melancholic, nostalgic, uplifting, romantic, sad, happy, dark,
dreamy, epic, chill, aggressive, passionate, hopeful, playful, anthemic, …
```
*Full list: `sample/description/emotion.txt` (200+ emotions)*

**Instrument** (select relevant ones):
```
piano, guitar, drums, synthesizer, strings, bass, violin, saxophone,
electric guitar, acoustic guitar, trumpet, choir, organ, …
```
*Full list: `sample/description/instrument.txt` (130+ instruments)*

**BPM** *(optional)*: `the bpm is 120.`

#### Valid examples

```
female, sad, pop, piano and drums.
male, energetic, rock, electric guitar and drums, the bpm is 140.
female, dark, synth-pop, sweet, synthesizer and drum machine.
mixed, nostalgic, folk, acoustic guitar and violin.
```

#### ⚠️ Invalid examples (do not use full sentences)

```
Please generate a sad pop song with piano and female vocals.
A dark jazz song with a male singer and saxophone.
```

---

### Audio Prompt

- Provide a path to a `.wav` file (stereo or mono, any sample rate).
- Only the **first 10 seconds** are used.
- For best results, use the **chorus** of a song as the reference.
- The prompt influences genre, instrumentation, rhythm, and vocal timbre.
- Avoid combining `prompt_audio_path` and `descriptions` in the same request. If both are provided, `prompt_audio_path` takes precedence and `descriptions` is ignored; conflicting signals can degrade output quality.

#### Auto-prompt types (no audio file needed)

When `prompt_audio_path` is absent, you can set `auto_prompt_audio_type` to one of:

```
Auto, Pop, Latin, Rock, Electronic, Metal, Country, R&B/Soul,
Ballad, Jazz, World, Hip-Hop, Funk, Soundtrack
```

---

## 8. Output Files

After running `generate.sh`, the output directory contains:

```
output_dir/
├── audio/
│   ├── song_01.wav          ← mixed (vocals + BGM)
│   ├── song_02.wav
│   └── ...
│
│   # If --separate was used:
│   ├── song_01_vocal.wav
│   ├── song_01_bgm.wav
│   └── ...
│
└── jsonl/
    └── results.jsonl        ← generation metadata
```

All audio files are **WAV format**, 44.1 kHz stereo.

---

## 9. Memory Optimisation

| Scenario | Recommendation |
|----------|---------------|
| 10–12 GB VRAM | Use `SongGeneration-base-new` + `--low_mem` flag |
| 12–18 GB VRAM | Use `SongGeneration-base-full` (or `--low_mem` for large models) |
| 22–28 GB VRAM | Use `SongGeneration-large` or `SongGeneration-v2-large` |
| No Flash Attention | Add `--not_use_flash_attn` flag |
| OOM during generation | Add `--low_mem` flag to enable CPU offloading |

With `--low_mem`, inference is slower but uses significantly less GPU memory by offloading layers to CPU when not in use.

---

## 10. Troubleshooting

### `CUDA out of memory`

- Add `--low_mem` to the generate command.
- Switch to a smaller model (e.g., `SongGeneration-base-new`).
- Close other GPU processes.
- Try generating shorter songs (fewer sections).

### Flash Attention errors

- Add `--not_use_flash_attn` to disable it.
- Alternatively, install the correct Flash Attention wheel for your Python + CUDA combination.

### `ModuleNotFoundError` or `ImportError`

Ensure the `PYTHONPATH` is set correctly. The `generate.sh` script handles this automatically. If running `generate.py` directly, set:

```bash
export PYTHONPATH="$(pwd)/codeclm/tokenizer/":"$(pwd)":"$(pwd)/codeclm/tokenizer/Flow1dVAE/":$PYTHONPATH
```

### `FileNotFoundError` for model weights

- Verify the `ckpt/` and `third_party/` folders exist in the repository root.
- Verify the checkpoint directory name matches exactly what you pass as `ckpt_path`.
- Re-run the `huggingface-cli download` commands from [Section 3](#3-downloading-model-weights).

### Gradio UI not reachable

- Check the server started without errors: look for `Running on http://0.0.0.0:8081`.
- Make sure port 8081 is not blocked by a firewall.
- For remote servers, use SSH port forwarding (see [Section 6](#6-gradio-web-ui)).

### Generated audio has wrong lyrics / hallucinations

- Re-check the lyrics format strictly:
  - Sections separated by ` ; ` (space–semicolon–space)
  - Correct section tags used
  - English punctuation only
  - Proper use of `.` to separate sentences
- Use the newer `SongGeneration-v2-large` model which has the lowest Phoneme Error Rate (8.55%).

### Lyrics validation error in the UI

- Make sure every vocal section (`[verse]`, `[chorus]`, `[bridge]`) contains at least one non-empty line.
- Make sure every instrumental section (`[intro-*]`, `[inst-*]`, `[outro-*]`) contains **no** lyrics.
- Make sure sections are separated by a blank line in the UI text box.

---

## 11. FAQ

**Q: Can I use this commercially?**  
A: Refer to the [LICENSE](LICENSE) file in the repository root.

**Q: What languages are supported?**  
A: `SongGeneration-base` supports Chinese only. `SongGeneration-base-new` and later models support Chinese and English. `SongGeneration-v2-large` additionally supports Spanish, Japanese, and other languages.

**Q: How long can a generated song be?**  
A: Base models support up to **2 minutes 30 seconds**. Full and large models support up to **4 minutes 30 seconds**.

**Q: Can I run this on CPU?**  
A: The model requires a CUDA-capable GPU. CPU-only inference is not supported.

**Q: Can I fine-tune the model?**  
A: Fine-tuning scripts are listed as a TODO in the roadmap and have not been released yet.

**Q: The generation is very slow. How can I speed it up?**  
A: Install Flash Attention (see [Step 4](#step-4--optional-install-flash-attention-for-faster-inference)), use a GPU with more VRAM (avoid `--low_mem`), and use the latest model version.

**Q: Where can I try the model without installing anything?**  
A: An online demo is available at https://huggingface.co/spaces/tencent/SongGeneration

**Q: Can I provide both an audio prompt and a text description?**  
A: Technically yes, but it is not recommended. If both are provided, `prompt_audio_path` takes precedence and the text description is ignored. Conflicting signals can degrade output quality.

**Q: What sample rate does the model output?**  
A: Generated audio is 44.1 kHz stereo WAV.
