#!/usr/bin/env bash

ffcompare() {
  local M1 M2 FROM MODE SCALE CODEC FILTER FILES SHARP
  # defaults
  FROM="00:10:00"
  MODE="blink"
  SHARP="0.8"

  FILES=()

  while [[ $# -gt 0 ]]; do
      case "$1" in
          -s|--start)
              FROM="$2"
              shift 2
              ;;
          -m|--mode)
              MODE="$2"
              shift 2
              ;;
          -S|--sharp)
            SHARP=$(awk -v n="$2" 'BEGIN {print (n<0.2)?0.2:((n>1.5)?1.5:n)}')
            shift 2
            ;;
          -h|--help)
            cat << EOF
Compare two videos:

Usage: ffcompare [start offset] [mode] [sharp] <video1> <video2>
Modes: blink (default), split, diff, hstack
Sharpness: 0.8 (default) 0.2 - 1.5
Start: ffmpeg compatible timestamp like 600 or 00:10:00 (default)

Options:
  -h --help    show help text
  -s --start   [val] start offset
  -m --mode    [val] mode
  -S --sharp   [val] Sharpness intensity (Shield-Look, default: 0.8)
EOF
              return 0
              ;;
          -*)
              echo "Unknown option: $1"
              return 1
              ;;
          *)
              FILES+=("$1")
              shift
              ;;
      esac
  done

  if [ "${#FILES[@]}" -ne 2 ]; then
  cat << EOF
Error: Need exactly 2 video files, but got ${#FILES[@]}.
Use -h/--help for usage instructions.
EOF
      return 1
  fi

  M1="${FILES[0]}"
  M2="${FILES[1]}"
  SCALE="scale=1920:1080:flags=lanczos,unsharp=3:3:${SHARP}:3:3:0.0"
  CODEC="libx264 -crf 10 -preset ultrafast -tune zerolatency"

  case ${MODE} in
    split)
        FILTER="[0:v]${SCALE}[v0];[1:v]${SCALE},crop=iw/2:ih:0:0,drawbox=x=iw-2:y=0:w=2:h=ih:color=red@0.05:t=fill[v1];[v0][v1]overlay=0:0"
        ;;
    diff)
        FILTER="[0:v]${SCALE}[v0];[1:v]${SCALE}[v1];[v0][v1]blend=all_mode='difference',format=yuv420p"
        ;;
    blink)
        FILTER="[0:v]${SCALE},eq=gamma_b=1.05:saturation=1.05,drawbox=x=10:y=10:w=40:h=40:color=blue:t=fill[v0];\
                [1:v]${SCALE},eq=gamma_r=1.05:saturation=1.05,drawbox=x=iw-50:y=10:w=40:h=40:color=green:t=fill[v1];\
                [v0][v1]blend=all_expr='if(lt(mod(T\,2)\,1)\,A\,B)'"
        ;;
    hstack|*)
        FILTER="[0:v]${SCALE}[v0];[1:v]${SCALE}[v1];[v0][v1]hstack"
        ;;
  esac

  COMMAND="ffmpeg -hide_banner \
    -ss \"${FROM}\" -i \"${M1}\" \
    -ss \"${FROM}\" -i \"${M2}\" \
    -filter_complex \"${FILTER}\" \
    -c:v  ${CODEC}\
    -an -f matroska -"

  echo ===========================================
  echo ${COMMAND} \| ffplay -hide_banner -
  echo ===========================================

  eval ${COMMAND} | ffplay -hide_banner -
}

_ffcompare_completion() {
    local cur prev opts modes
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    modes="hstack split diff blink"
    local all_opts="-h --help -s --start -m --mode -S --sharp"

    local video_count=0
    local used_opts=()
    local i

    # --- 1. Analyse der Kommandozeile ---
    for (( i=1; i < COMP_CWORD; i++ )); do
        local word="${COMP_WORDS[i]}"
        local p_word="${COMP_WORDS[i-1]}"

        # Optionen erfassen
        if [[ "$word" == -* ]]; then
            used_opts+=("$word")
            # Aliase blocken
            [[ "$word" == "-s" ]] && used_opts+=("--start")
            [[ "$word" == "--start" ]] && used_opts+=("-s")
            [[ "$word" == "-m" ]] && used_opts+=("--mode")
            [[ "$word" == "--mode" ]] && used_opts+=("-m")
            [[ "$word" == "-S" ]] && used_opts+=("--sharp")
            [[ "$word" == "--sharp" ]] && used_opts+=("-S")
            continue
        fi

        # Werte nach Optionen überspringen
        if [[ "$p_word" == -s || "$p_word" == --start || \
              "$p_word" == -m || "$p_word" == --mode || \
              "$p_word" == -S || "$p_word" == --sharp ]]; then
            continue
        fi

        # Dateien zählen (nur wenn existent oder Videomuster)
        ((video_count++))
    done

    # --- 2. Dynamische Filterung der Optionen ---
    local filtered_opts=""
    for o in $all_opts; do
        # NEU: Hilfe nur vorschlagen, wenn absolut NICHTS bisher eingegeben wurde
        if [[ "$o" == "-h" || "$o" == "--help" ]]; then
            if [[ $video_count -gt 0 || ${#used_opts[@]} -gt 0 ]]; then
                continue
            fi
        fi

        # Bereits genutzte Optionen filtern
        local skip=false
        for u in "${used_opts[@]}"; do
            if [[ "$u" == "$o" ]]; then skip=true; break; fi
        done

        [[ "$skip" == "false" ]] && filtered_opts+="$o "
    done

    # --- 3. Vorschläge ausgeben ---

    # Spezialfall: Modus-Werte
    case "$prev" in
        -m|--mode)
            COMPREPLY=( $(compgen -W "${modes}" -- "${cur}") )
            return 0
            ;;
        -s|--start|-S|--sharp) return 0 ;;
    esac

    # Wenn ein "-" getippt wird oder bereits 2 Videos da sind: schlage Optionen vor
    if [[ "$cur" == -* || $video_count -ge 2 ]]; then
        COMPREPLY=( $(compgen -W "${filtered_opts}" -- "${cur}") )
        return 0
    fi

    # Dateivorschläge (nur solange < 2 Dateien)
    local IFS=$'\n'
    local raw_list=$(compgen -f -- "${cur}")
    for x in $raw_list; do
        if [[ -d "$x" || "$x" == *.[mM][kK][vV] || "$x" == *.[mM][pP]4 || "$x" == *.[aA][vV][iI] || "$x" == *.[wW][eE][bB][mM] ]]; then
            COMPREPLY+=("$x")
        fi
    done
}

complete -F _ffcompare_completion -o filenames -o plusdirs ffcompare
