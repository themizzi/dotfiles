#!/usr/bin/env sh
set -eu

menu_sequence=${DOTFILES_ZELLIJ_PALETTE_MENU_SEQUENCE-}
input_sequence=${DOTFILES_ZELLIJ_PALETTE_INPUT_SEQUENCE-}
render_width=${DOTFILES_ZELLIJ_PALETTE_RENDER_WIDTH-}
shortcut_map_cache=''
resolved_render_width=''
resolved_render_width_ready=0
render_line_prefix_width=2

str_len() {
    printf '%s' "$1" | awk '{ print length($0) }'
}

is_positive_int() {
    value=$1
    case "$value" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac
    [ "$value" -gt 0 ]
}

consume_sequence_line() {
    sequence_name=$1
    eval "sequence_value=\${$sequence_name-}"
    if [ "$sequence_value" = "" ]; then
        CONSUMED_SEQUENCE_LINE=''
        return 0
    fi
    first_line=$(printf '%s\n' "$sequence_value" | sed -n '1p')
    remaining_lines=$(printf '%s\n' "$sequence_value" | sed '1d')
    eval "$sequence_name=\$remaining_lines"
    CONSUMED_SEQUENCE_LINE=$first_line
}

normalize_selection() {
    raw_selection=$1
    printf '%s\n' "$raw_selection" | sed 's/\t.*$//'
}

choose_menu_item() {
    prompt=$1
    menu_items=$2
    if [ "$menu_sequence" != "" ]; then
        consume_sequence_line menu_sequence
        CHOSEN_MENU_ITEM=$(normalize_selection "$CONSUMED_SEQUENCE_LINE")
        return 0
    fi
    picked=$(printf '%s\n' "$menu_items" | fzf --prompt "$prompt" || true)
    CHOSEN_MENU_ITEM=$(normalize_selection "$picked")
}

read_input_value() {
    prompt=$1
    if [ "$input_sequence" != "" ]; then
        consume_sequence_line input_sequence
        READ_INPUT_VALUE=$CONSUMED_SEQUENCE_LINE
        return 0
    fi
    query_selection=$(printf '\n' | fzf --print-query --prompt "$prompt" || true)
    READ_INPUT_VALUE=$(printf '%s\n' "$query_selection" | sed -n '1p')
}

action_to_kdl_name() {
    action_name=$1
    printf '%s\n' "$action_name" | awk -F'-' '{ for (i = 1; i <= NF; i++) { $i = toupper(substr($i,1,1)) substr($i,2) } printf "%s", $1; for (i = 2; i <= NF; i++) { printf "%s", $i }; print "" }'
}

infer_action_shortcut() {
    action_name=$1
    config_path="$HOME/.config/zellij/config.kdl"
    [ -f "$config_path" ] || { printf ''; return 0; }
    kdl_name=$(action_to_kdl_name "$action_name")

    build_shortcut_map() {
        map_config_path=$1
        awk '
            function trim(s) {
                gsub(/^[ \t]+/, "", s)
                gsub(/[ \t]+$/, "", s)
                return s
            }
            function list_contains(list, needle, parts, n, i) {
                n = split(list, parts, /[[:space:]]+/)
                for (i = 1; i <= n; i++) {
                    if (parts[i] == needle) {
                        return 1
                    }
                }
                return 0
            }
            function normal_accessible(kind, value) {
                if (kind == "MODE") {
                    return value == "normal"
                }
                if (kind == "SHARED_EXCEPT") {
                    return !list_contains(value, "normal")
                }
                if (kind == "SHARED_AMONG") {
                    return list_contains(value, "normal")
                }
                return 0
            }
            function remember_shortest(map_name, map_key, candidate, existing) {
                existing = map_name[map_key]
                if (existing == "" || length(candidate) < length(existing)) {
                    map_name[map_key] = candidate
                }
            }
            {
                line = $0
                if (match(line, /^[ \t]*shared_except/)) {
                    kind = "SHARED_EXCEPT"
                    value = ""
                    rest = line
                    while (match(rest, /"[^"]+"/)) {
                        token = substr(rest, RSTART + 1, RLENGTH - 2)
                        if (value == "") {
                            value = token
                        } else {
                            value = value " " token
                        }
                        rest = substr(rest, RSTART + RLENGTH)
                    }
                } else if (match(line, /^[ \t]*shared_among/)) {
                    kind = "SHARED_AMONG"
                    value = ""
                    rest = line
                    while (match(rest, /"[^"]+"/)) {
                        token = substr(rest, RSTART + 1, RLENGTH - 2)
                        if (value == "") {
                            value = token
                        } else {
                            value = value " " token
                        }
                        rest = substr(rest, RSTART + RLENGTH)
                    }
                } else if (match(line, /^[ \t]*[a-z][a-z0-9-]*[ \t]*\{/)) {
                    mode = line
                    sub(/^[ \t]*/, "", mode)
                    sub(/[ \t]*\{.*/, "", mode)
                    kind = "MODE"
                    value = mode
                }

                if (!(line ~ /bind "[^"]+"/ && line ~ /\{[^}]*\}/)) {
                    next
                }

                key = line
                sub(/^.*bind "/, "", key)
                sub(/".*$/, "", key)
                key = trim(key)

                body = line
                sub(/^.*\{/, "", body)
                sub(/\}.*$/, "", body)
                body = trim(body)

                accessible = normal_accessible(kind, value)
                rest = body
                while (match(rest, /[A-Z][A-Za-z0-9]*/)) {
                    action_name = substr(rest, RSTART, RLENGTH)
                    rest = substr(rest, RSTART + RLENGTH)
                    if (action_name == "SwitchToMode") {
                        continue
                    }
                    if (accessible) {
                        remember_shortest(direct_shortcut, action_name, key)
                    }
                    if (kind == "MODE" && value != "normal") {
                        remember_shortest(mode_action_shortcut, value SUBSEP action_name, key)
                    }
                }

                if (accessible && match(body, /SwitchToMode[[:space:]]+"[^"]+"/)) {
                    mode_name = substr(body, RSTART, RLENGTH)
                    sub(/^SwitchToMode[[:space:]]+"/, "", mode_name)
                    sub(/"$/, "", mode_name)
                    remember_shortest(mode_prefix_shortcut, mode_name, key)
                }
            }
            END {
                for (action_name in direct_shortcut) {
                    final_shortcut[action_name] = direct_shortcut[action_name]
                }
                for (pair in mode_action_shortcut) {
                    split(pair, parts, SUBSEP)
                    mode_name = parts[1]
                    action_name = parts[2]
                    prefix = mode_prefix_shortcut[mode_name]
                    if (prefix == "") {
                        continue
                    }
                    chain = prefix " > " mode_action_shortcut[pair]
                    existing = final_shortcut[action_name]
                    if (existing == "" || length(chain) < length(existing)) {
                        final_shortcut[action_name] = chain
                    }
                }
                for (action_name in final_shortcut) {
                    print action_name "|" final_shortcut[action_name]
                }
            }
        ' "$map_config_path"
    }

    if [ "$shortcut_map_cache" = "" ]; then
        shortcut_map_cache=$(build_shortcut_map "$config_path")
    fi

    printf '%s\n' "$shortcut_map_cache" | awk -F'|' -v key="$kdl_name" '$1 == key { print $2; exit }'
}

resolve_render_width() {
    if [ "$render_width" != "" ]; then
        if is_positive_int "$render_width"; then
            printf '%s\n' "$render_width"
            return 0
        fi
        printf ''
        return 0
    fi

    detected_columns=''
    if [ -t 0 ] || [ -t 1 ]; then
        if command -v stty >/dev/null 2>&1; then
            stty_size=$(stty size 2>/dev/null || true)
            stty_cols=$(printf '%s\n' "$stty_size" | awk '{ print $2 }')
            if is_positive_int "$stty_cols"; then
                detected_columns=$stty_cols
            fi
        fi

        if [ "$detected_columns" = "" ] && command -v tput >/dev/null 2>&1; then
            tput_cols=$(tput cols 2>/dev/null || true)
            if is_positive_int "$tput_cols"; then
                detected_columns=$tput_cols
            fi
        fi
    fi

    if [ "$detected_columns" = "" ] && [ "${COLUMNS-}" != "" ]; then
        if is_positive_int "$COLUMNS"; then
            detected_columns=$COLUMNS
        fi
    fi

    if [ "$detected_columns" = "" ] || [ "$detected_columns" -le 1 ]; then
        printf ''
        return 0
    fi

    inner_width=$((detected_columns - 1 - render_line_prefix_width))
    if [ "$inner_width" -le 0 ]; then
        printf ''
        return 0
    fi
    printf '%s\n' "$inner_width"
}

render_action_line() {
    action_name=$1
    shortcut=$2
    label="Action: $action_name"
    if [ "$shortcut" = "" ]; then
        printf '%s\n' "$label"
        return 0
    fi

    if [ "$resolved_render_width_ready" -eq 0 ]; then
        resolved_render_width=$(resolve_render_width)
        resolved_render_width_ready=1
    fi

    effective_width=$resolved_render_width
    if [ "$effective_width" = "" ]; then
        printf '%s\t%s\n' "$label" "$shortcut"
        return 0
    fi
    case "$effective_width" in
        ''|*[!0-9]*)
            printf '%s\t%s\n' "$label" "$shortcut"
            return 0
            ;;
    esac

    if [ "$effective_width" -eq 0 ]; then
        printf '%s\t%s\n' "$label" "$shortcut"
        return 0
    fi

    label_len=$(str_len "$label")
    hint_len=$(str_len "$shortcut")
    tabstop=8
    tab_width=$((tabstop - (label_len % tabstop)))
    min_total=$((label_len + tab_width + hint_len))
    if [ "$effective_width" -lt "$min_total" ]; then
        printf '%s\t%s\n' "$label" "$shortcut"
        return 0
    fi

    hint_col_width=$((effective_width - label_len - tab_width))
    padded_hint=$(printf '%*s' "$hint_col_width" "$shortcut")
    printf '%s\t%s\n' "$label" "$padded_hint"
}

discover_actions() {
    if [ "$resolved_render_width_ready" -eq 0 ]; then
        resolved_render_width=$(resolve_render_width)
        resolved_render_width_ready=1
    fi

    zellij action --help 2>/dev/null \
        | sed -n '/^SUBCOMMANDS:/,$p' \
        | grep -E '^    [a-z0-9-]+' \
        | sed -E 's/^    ([a-z0-9-]+).*/\1/' \
        | while IFS= read -r action; do
            [ "$action" = "help" ] && continue
            shortcut=$(infer_action_shortcut "$action")
            render_action_line "$action" "$shortcut"
        done
}

discover_option_defs() {
    action_help=$1
    printf '%s\n' "$action_help" \
        | sed -n '/^OPTIONS:/,/^[A-Z][A-Z0-9_]*:/p' \
        | grep -E '^    -|^        --' \
        | sed 's/^ *//'
}

discover_arg_defs() {
    action_help=$1
    printf '%s\n' "$action_help" \
        | sed -n '/^ARGS:/,/^[A-Z][A-Z0-9_]*:/p' \
        | grep -E '^    <[^>]+>(\.\.\.)?' \
        | sed 's/^ *//'
}

option_primary_token() {
    option_def=$1
    printf '%s\n' "$option_def" | sed -E 's/,.*$//' | awk '{ print $1 }'
}

option_long_token() {
    option_def=$1
    printf '%s\n' "$option_def" | sed -n 's/.*\(--[a-z0-9-]*\).*/\1/p'
}

option_requires_value() {
    option_def=$1
    if printf '%s\n' "$option_def" | grep -q '<[^>][^>]*>'; then
        printf '1'
    else
        printf '0'
    fi
}

option_value_name() {
    option_def=$1
    printf '%s\n' "$option_def" | sed -n 's/.*<\([^>]*\)>.*/\1/p'
}

is_repeatable_option() {
    option_def=$1
    action_help=$2
    option_long=$(option_long_token "$option_def")
    if printf '%s\n' "$option_def" | grep -q '\.\.\.'; then
        printf '1'
        return 0
    fi
    if [ "$option_long" != "" ]; then
        key_phrase=$(printf '%s\n' "$option_long" | sed 's/^--//; s/-/ /g')
        if printf '%s\n' "$action_help" | grep -i "$key_phrase" | grep -Eiq 'space separated list|multiple|one or more|more than once'; then
            printf '1'
            return 0
        fi
    fi
    printf '0'
}

extract_enum_values() {
    context_text=$1
    enum_line=$(printf '%s\n' "$context_text" | grep -E '\[[^]]*\|[^]]*\]' | sed -n '1p' || true)
    [ "$enum_line" = "" ] && { printf ''; return 0; }
    enum_blob=$(printf '%s\n' "$enum_line" | sed -n 's/.*\[\([^]]*\)\].*/\1/p')
    [ "$enum_blob" = "" ] && { printf ''; return 0; }
    printf '%s\n' "$enum_blob" | tr '|' '\n'
}

option_enum_values() {
    option_def=$1
    action_help=$2
    option_long=$(option_long_token "$option_def")
    if [ "$option_long" = "" ]; then
        printf ''
        return 0
    fi
    key_phrase=$(printf '%s\n' "$option_long" | sed 's/^--//; s/-/ /g')
    contextual=$(printf '%s\n' "$action_help" | grep -i "$key_phrase" || true)
    values=$(extract_enum_values "$contextual")
    if [ "$values" != "" ]; then
        printf '%s\n' "$values"
        return 0
    fi
    printf ''
}

arg_name_from_def() {
    arg_def=$1
    printf '%s\n' "$arg_def" | sed -n 's/^<\([^>]*\)>.*/\1/p'
}

arg_is_repeatable() {
    arg_def=$1
    if printf '%s\n' "$arg_def" | grep -q '\.\.\.'; then
        printf '1'
    else
        printf '0'
    fi
}

arg_is_required() {
    arg_name=$1
    usage_line=$2
    if printf '%s\n' "$usage_line" | grep -q "\[[^]]*<$arg_name>[^]]*\]"; then
        printf '0'
        return 0
    fi
    if printf '%s\n' "$usage_line" | grep -q "<$arg_name>"; then
        printf '1'
        return 0
    fi
    printf '0'
}

arg_enum_values() {
    arg_name=$1
    action_help=$2
    key_phrase=$(printf '%s\n' "$arg_name" | tr '[:upper:]' '[:lower:]' | sed 's/_/ /g')
    contextual=$(printf '%s\n' "$action_help" | grep -i "$key_phrase" || true)
    values=$(extract_enum_values "$contextual")
    if [ "$values" != "" ]; then
        printf '%s\n' "$values"
        return 0
    fi
    printf ''
}

append_line() {
    current=$1
    line=$2
    if [ "$current" = "" ]; then
        printf '%s\n' "$line"
    else
        printf '%s\n%s\n' "$current" "$line"
    fi
}

remove_matching_option() {
    options_state=$1
    option_key=$2
    printf '%s\n' "$options_state" | awk -F'|' -v k="$option_key" '$1 != k'
}

render_command() {
    base=$1
    options_state=$2
    args_state=$3
    arg_defs=$4
    cmd=$base

    if [ "$options_state" != "" ]; then
        while IFS='|' read -r option_key option_token option_value; do
            [ "$option_key" = "" ] && continue
            cmd="$cmd $option_token"
            if [ "$option_value" != "" ]; then
                cmd="$cmd $option_value"
            fi
        done <<EOF_OPTIONS
$options_state
EOF_OPTIONS
    fi

    if [ "$arg_defs" != "" ] && [ "$args_state" != "" ]; then
        while IFS= read -r arg_def; do
            [ "$arg_def" = "" ] && continue
            arg_name=$(arg_name_from_def "$arg_def")
            while IFS='|' read -r state_name state_value; do
                [ "$state_name" = "$arg_name" ] || continue
                cmd="$cmd $state_value"
            done <<EOF_ARGSTATE
$args_state
EOF_ARGSTATE
        done <<EOF_ARGDEFS
$arg_defs
EOF_ARGDEFS
    fi

    printf '%s\n' "$cmd"
}

missing_required_args() {
    usage_line=$1
    arg_defs=$2
    args_state=$3
    missing_list=""
    if [ "$arg_defs" = "" ]; then
        printf ''
        return 0
    fi
    while IFS= read -r arg_def; do
        [ "$arg_def" = "" ] && continue
        arg_name=$(arg_name_from_def "$arg_def")
        required=$(arg_is_required "$arg_name" "$usage_line")
        [ "$required" = "1" ] || continue
        has_value=0
        while IFS='|' read -r state_name state_value; do
            [ "$state_name" = "$arg_name" ] || continue
            [ "$state_value" = "" ] && continue
            has_value=1
            break
        done <<EOF_REQUIRED
$args_state
EOF_REQUIRED
        if [ "$has_value" = "0" ]; then
            missing_list=$(append_line "$missing_list" "$arg_name")
        fi
    done <<EOF_REQUIRED_ARGS
$arg_defs
EOF_REQUIRED_ARGS
    printf '%s\n' "$missing_list" | sed '/^$/d'
}

menu_items=$(discover_actions)

if [ "${DOTFILES_ZELLIJ_PALETTE_LIST_ONLY-0}" = "1" ]; then
    printf '%s\n' "$menu_items"
    exit 0
fi

if [ "${DOTFILES_ZELLIJ_PALETTE_CHOICE-}" != "" ]; then
    selection=$DOTFILES_ZELLIJ_PALETTE_CHOICE
else
    choose_menu_item "Action> " "$menu_items"
    selection=$CHOSEN_MENU_ITEM
fi

selection=$(normalize_selection "$selection")

case "$selection" in
    "Action: "*)
        action=${selection#Action: }
        [ "$action" = "" ] && exit 0
        ;;
    "") exit 0 ;;
    *) exit 0 ;;
esac

base_cmd="zellij action $action"
action_help=$(zellij action "$action" --help 2>/dev/null || true)
usage_line=$(printf '%s\n' "$action_help" | sed -n '/^USAGE:/,/^$/p' | grep "zellij action $action" | sed -n '1p' || true)
option_defs=$(discover_option_defs "$action_help")
arg_defs=$(discover_arg_defs "$action_help")

options_state=""
args_state=""

while :; do
    choose_menu_item "Build> " "Add option
Add argument
Review command
Run command
Cancel"
    builder_choice=$CHOSEN_MENU_ITEM
    case "$builder_choice" in
        "Add option")
            [ "$option_defs" = "" ] && continue
            choose_menu_item "Option> " "$option_defs"
            selected_option=$CHOSEN_MENU_ITEM
            [ "$selected_option" = "" ] && continue

            option_token=$(option_primary_token "$selected_option")
            option_long=$(option_long_token "$selected_option")
            if [ "$option_long" != "" ]; then
                option_key=$option_long
            else
                option_key=$option_token
            fi
            option_repeatable=$(is_repeatable_option "$selected_option" "$action_help")

            duplicate_found=0
            if [ "$options_state" != "" ]; then
                if printf '%s\n' "$options_state" | awk -F'|' -v k="$option_key" '$1 == k { found = 1 } END { if (found == 1) { exit 0 } else { exit 1 } }'; then
                    duplicate_found=1
                fi
            fi

            if [ "$duplicate_found" = "1" ] && [ "$option_repeatable" = "0" ]; then
                choose_menu_item "Duplicate option> " "Replace existing option
Keep existing option"
                duplicate_choice=$CHOSEN_MENU_ITEM
                [ "$duplicate_choice" = "Keep existing option" ] && continue
                options_state=$(remove_matching_option "$options_state" "$option_key")
            fi

            option_value=""
            requires_value=$(option_requires_value "$selected_option")
            if [ "$requires_value" = "1" ]; then
                option_values=$(option_enum_values "$selected_option" "$action_help")
                if [ "$option_values" != "" ]; then
                    choose_menu_item "Option value> " "$option_values"
                    option_value=$CHOSEN_MENU_ITEM
                else
                    value_name=$(option_value_name "$selected_option")
                    read_input_value "$value_name> "
                    option_value=$READ_INPUT_VALUE
                fi
            fi

            options_state=$(append_line "$options_state" "$option_key|$option_token|$option_value")
            ;;
        "Add argument")
            [ "$arg_defs" = "" ] && continue
            choose_menu_item "Argument> " "$arg_defs"
            selected_arg=$CHOSEN_MENU_ITEM
            [ "$selected_arg" = "" ] && continue
            arg_name=$(arg_name_from_def "$selected_arg")
            arg_repeatable=$(arg_is_repeatable "$selected_arg")

            arg_values=$(arg_enum_values "$arg_name" "$action_help")
            if [ "$arg_values" != "" ]; then
                choose_menu_item "Argument value> " "$arg_values"
                arg_value=$CHOSEN_MENU_ITEM
            else
                read_input_value "$arg_name> "
                arg_value=$READ_INPUT_VALUE
            fi
            [ "$arg_value" = "" ] && continue

            if [ "$arg_repeatable" = "0" ]; then
                args_state=$(printf '%s\n' "$args_state" | awk -F'|' -v n="$arg_name" '$1 != n')
            fi
            args_state=$(append_line "$args_state" "$arg_name|$arg_value")
            ;;
        "Review command")
            render_command "$base_cmd" "$options_state" "$args_state" "$arg_defs" 1>&2
            ;;
        "Run command")
            missing_args=$(missing_required_args "$usage_line" "$arg_defs" "$args_state")
            if [ "$missing_args" != "" ]; then
                printf 'Required arguments missing:\n%s\n' "$missing_args" 1>&2
                continue
            fi
            cmd=$(render_command "$base_cmd" "$options_state" "$args_state" "$arg_defs")
            if [ "${DOTFILES_ZELLIJ_PALETTE_DRY_RUN-0}" = "1" ]; then
                printf '%s\n' "$cmd"
                exit 0
            fi
            sh -c "$cmd"
            exit $?
            ;;
        "Cancel")
            exit 0
            ;;
        "")
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
done
