# arte_ia — local AI card art lab

Generated card art lives here; nothing in the game source was changed.
Gallery: `python -m http.server 8791 --bind 127.0.0.1 -d arte_ia` → http://127.0.0.1:8791/

## Setup (12 Nov 2026)
- ComfyUI (git, commit 0f05af6) + city96/ComfyUI-GGUF at `C:\AI\ComfyUI`, venv on Python 3.11, torch 2.14.1+cu126
  (the driver, 560.94, supports CUDA 12.6 at most, so the portable cu128/cu130 build would not start).
- Start: `C:\AI\ComfyUI\venv\Scripts\python main.py --listen 127.0.0.1 --port 8188 --lowvram`
- Models (all from Hugging Face):
  - `unsloth/Qwen-Image-2.1-Turbo-GGUF` / `qwen-image-2.1-turbo-Q6_K.gguf` (6.27 GB)
  - `Comfy-Org/Qwen-Image-2.1` / `text_encoders/qwen3vl_8b_w4a8.safetensors` (6.31 GB). The GGUF encoder
    `Qwen3-VL-8B-Instruct-UD-Q4_K_XL.gguf` (5.15 GB, also downloaded) **does not work**: ComfyUI-GGUF only attaches
    vision weights (mmproj) for Qwen2-VL, so ComfyUI reads the file as plain Qwen3-8B and returns 12288-dim features
    where the model expects 4096. It can be deleted.
- Timing (RTX 2060 12 GB, --lowvram, 1056×1024): t2i ≈ 110 s/image, i2i (5 steps) ≈ 72 s; first run 126 s.
- img2img at denoise 0.50 and 0.65 barely changes the code art: the turbo schedule changes structure only at high sigma.
  To get a painted look you need about 0.8 or more.
  - `Comfy-Org/Qwen-Image-2.1` / `vae/qwen_image_2.1_vae_bf16.safetensors` (0.68 GB)
- Graph = the official template `image_qwen_image_2_1_turbo_t2i` with the GGUF loaders swapped in:
  TextEncodeQwenImage21 → QwenImage21Cache → CFGGuider cfg 1 → ManualSigmas (the turbo schedule, 8 steps) → euler.

## Decisions I made without asking (you said to work autonomously)
- **Your GPU has 12 GB, not 6** (an RTX 2060 12 GB). So I used Q6_K instead of Q4_K_M; Q6_K's LPIPS against bf16 is
  0.055, Q4_K_M's is 0.153. `--lowvram` stays on as you asked.
- Output size 1056×1024, close to the card window's ratio (556×534). Not portrait, because the game's art window is nearly square.
- img2img: the code art is VAE-encoded, and the turbo sigma curve is resampled to start at sigma = denoise (5 steps).
- "Krea2 Anime v3.0": no Hugging Face repo by that name. There are `ricecake/Krea-2-Anime-tuned-Turbo` and some LoRAs. To check later.
- Scripts live in `arte_ia/_tools/` (gen.py, grain.py, build_gallery.py, subjects.json).

## Krea 2 Anime (12 Nov, second round)
- Designer's reference: krea2anime, refine of a favourite at i2i 0.5, then grain 0.9, seed 1000, shorter texture block
  (now style `gouache2` in gen.py). New flags: `gen.py i2i --src <file in arte_ia/<card>/>` (mode `ref<denoise>`),
  `grain.py --strength=0.9` (writes `__grain90.png`).
- Downloaded from Comfy-Org/Krea-2 (official, not gated): `qwen3vl_4b_int8_convrot.safetensors` (4.86 GB),
  `qwen_image_vae.safetensors` (0.25 GB).
- Downloaded after the designer accepted the license: `ricecake/Krea-2-Anime-tuned-Turbo` / `krea2_anime_tuned_turbo_int8_convrot.safetensors` (13.49 GB).
  The repo is gated (Krea 2 Community License): the designer has to accept it and log in to Hugging Face.
  int8_convrot because the RTX 2060 has no FP8; at 13.5 GB it will not fit fully in 12 GB, so --lowvram offloads part.
- Graph = official template `image_krea2_turbo_t2i` (UNETLoader, CLIPLoader type krea2, KSampler 8 steps euler/simple cfg 1).
- Qwen version of the same recipe: t2i 127 s, refine 74 s.
- Krea Anime timing (--lowvram, 1056×1024): t2i 146 s (first load), refine 0.5 69 s; ~7.6 GB VRAM after the run, no OOM.

## Deck style and the cartas-ia skill (12 Nov, after the grilling)
- Designer's decisions: style B (flat gouache poster) = `STYLES["deck"]` (the darker variant + fixed composition sentence was rejected: floating crown, smaller swarm; master = poster s1000 + grain90); consistency = fixed text + master
  card (Rat King, `_tools/mestra.png` once approved) through the official `krea2_style_reference` LoRA (Comfy-Org, 0.46 GB);
  natural creature colour + one of 6 fixed backgrounds; grain 0.9; 1 image per card; batches by villain; output in
  `arte_ia/final/` (556×534). Skill: `.claude/skills/cartas-ia/`; `arte-de-carta` archived in `.claude/skills-arquivo/`.
- Reference test (goblin, seed 1000; `pranchas/teste_referencia_goblin.jpg`): LoRA 1.0 copies the master's grey
  background and loses the cart (203 s); 0.6 keeps the sand background and cart and the master's brushwork, but a pink rat
  tail leaked in (184 s); no reference is sharper and closer to poster style, 94 s. `deck.py` defaults to 0.6.

## Pilot (12 Nov night): coherence and anti-cartoon rules
- Designer's new rules: coherence inside the image (no limb vanishing, morphing, duplicated item), never cartoony, never AI-looking.
  Added: `TONE` sentence in gen.py (deck style), goblin sheet rewritten, subject rules 10-11 and the per-card QA checklist in the skill.
- v1 (agent-written subjects, seed 1000): all 10 images failed QA (second sword, ghost leg/tail, fused rats, hand on face, rope-like smoke).
- v2 (simpler, countable poses written by the controller, seed 1001): passed = death_knight (text-only), rat_burrow (ref),
  weakness_curse (ref); failed both ways = elder_dragon (ghost far wing), goblin_dynamiter (ghost limb / missing fuse).
  Sheet: `pranchas/piloto_v2_comparacao.png`; v1 kept in `final_piloto/v1/`.
- Time: text-only ~78 s/card, with master reference ~165 s/card.
- Token cost: each Sonnet subagent costs ~65k tokens even for one card (fixed start-up context). 20 runs in the pilot ≈ 1.3M.
  One agent per card for the whole deck (subjects + QA) would be ~11M tokens; one agent per ~8 cards would be ~1.5M.
- Speed (12 Nov): GPU at 100% with one image, so parallel images cannot help. 768×736 takes 37 s vs 69 s at 1056×1024, same look at 556×534 (rat_brute test). deck.py now renders at 768×736; rat_brute and the pilot cards were made at 1056.
