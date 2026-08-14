
video_to_audio() {
  local video="$1"
  local audio="${video%.*}.mp3"
  ffmpeg -i "$video" -vn -acodec mp3 "$audio"
}

video_download_from_youtube() {
  yt-dlp -o "full_video.mp4" "$1"
}

# ---- shared helpers ----

_v2g_is_help() { case "${1:-}" in help|-h|--help) return 0;; *) return 1;; esac; }

_v2g_help() {
  # usage: _v2g_help <topic>
  case "$1" in
    video_to_gif)
      cat <<'EOF'
video_to_gif - convert a video to an optimized GIF (palettegen/paletteuse)

Usage:
  video_to_gif <input> [fps=5] [height=1080] [speed=1] [output=out_<timestamp>.gif]

Examples:
  video_to_gif clip.mov
  video_to_gif clip.mov 8 720 1.25 demo.gif
EOF
      ;;
    video_to_gif_latest)
      cat <<'EOF'
video_to_gif_latest - convert the latest macOS "Screen Recording*.mov" to a GIF

Usage:
  video_to_gif_latest [fps=5] [height=1080] [speed=1] [output=out_<timestamp>.gif]
  video_to_gif_latest help

Searches:
  $SCREEN_RECORDINGS_DIR if set, otherwise ~/Desktop

Examples:
  video_to_gif_latest
  video_to_gif_latest 8 720 1.25
  video_to_gif_latest 8 720 1.25 my.gif

Tip:
  export SCREEN_RECORDINGS_DIR="$HOME/Movies"
EOF
      ;;
    v2g)
      cat <<'EOF'
v2g - shorthand for video_to_gif_latest

Usage:
  v2g [fps] [height] [speed] [output]
  v2g help
EOF
      ;;
  esac
}

# ---- core ----

video_to_gif() {
  _v2g_is_help "$1" && { _v2g_help video_to_gif; return 0; }

  local input="${1:-}"
  local fps="${2:-5}"
  local height="${3:-1080}"
  local speed="${4:-1}"
  local output="${5:-}"

  [ -z "$input" ] && { echo "Missing input. Run: video_to_gif --help"; return 1; }

  [ -z "$output" ] && output="out_$(date +"%Y%m%d_%H%M%S").gif"

  local pts
  pts="$(awk -v s="$speed" 'BEGIN { if (s==0) exit 1; printf "%.6f", 1.0/s }')" || {
    echo "Invalid speed: $speed"; return 1;
  }

  ffmpeg -i "$input" \
    -filter_complex "[0:v]setpts=${pts}*PTS,fps=${fps},scale=-1:${height}:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse=dither=bayer" \
    -y "$output"
}

video_to_gif_latest() {
  _v2g_is_help "$1" && { _v2g_help video_to_gif_latest; return 0; }

  local fps="${1:-5}"
  local height="${2:-1080}"
  local speed="${3:-1}"
  local output="${4:-}"

  local dir="${SCREEN_RECORDINGS_DIR:-$HOME/Desktop}"
  local latest
  latest="$(ls -t "$dir"/Screen\ Recording*.mov 2>/dev/null | head -n 1)"

  [ -z "$latest" ] && { echo "No Screen Recording .mov files found in: $dir"; return 1; }

  [ -z "$output" ] && output="out_$(date -r "$latest" +"%Y%m%d_%H%M%S" 2>/dev/null || date +"%Y%m%d_%H%M%S").gif"

  video_to_gif "$latest" "$fps" "$height" "$speed" "$output"
}

v2g() {
  _v2g_is_help "$1" && { _v2g_help v2g; return 0; }
  video_to_gif_latest "$@"
}