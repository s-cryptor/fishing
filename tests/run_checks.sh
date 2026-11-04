#!/usr/bin/env bash
# Godot может завершиться с кодом 0 после ошибки скрипта: проверяем и журнал.
set -euo pipefail

godot_bin=${1:-godot}
task_log=$(mktemp)
trap 'rm -f "$task_log"' EXIT

run_check() {
    "$godot_bin" "$@" 2>&1 | tee "$task_log"
    if grep -nE 'SCRIPT ERROR|^ERROR:' "$task_log"; then
        return 1
    fi
}

run_check --headless --path . --editor --import --quit
run_check --headless --path . -s res://tests/test_fishing_session.gd -- --save=user://logic-test.json --mute
run_check --headless --path . -s res://tests/test_save_store.gd -- --save=user://save-store-test.json --mute
run_check --headless --path . -s res://tests/test_boat_session.gd -- --save=user://sailing-test.json --mute
run_check --headless --path . -s res://tests/test_boat_sailing.gd -- --save=user://sailing-scene-test.json --mute
run_check --headless --path . -s res://tests/test_fishing_spots.gd -- --save=user://spots-test.json --mute
run_check --headless --path . -s res://tests/test_trophy_gallery.gd -- --save=user://gallery-test.json --mute
run_check --headless --path . -s res://tests/test_fish_art.gd -- --save=user://fish-art-test.json --mute
run_check --headless --path . -s res://tests/test_imported_fish.gd -- --save=user://imported-fish-test.json --mute
run_check --headless --path . -s res://tests/test_fishing_targets.gd -- --save=user://targets-test.json --mute
run_check --headless --path . -s res://tests/test_fishing_feedback.gd -- --save=user://feedback-test.json --mute
run_check --headless --path . -s res://tests/test_discoveries.gd -- --save=user://discoveries-test.json --mute
run_check --headless --path . -s res://tests/test_cast_aiming.gd -- --save=user://aiming-test.json --mute
run_check --headless --path . -s res://tests/test_cooking.gd -- --save=user://cooking-test.json --mute
run_check --headless --path . -s res://tests/test_menu_navigation.gd -- --save=user://menu-test.json --mute
run_check --headless --path . -s res://tests/test_basket.gd -- --save=user://basket-test.json --mute
run_check --headless --path . -s res://tests/test_camera_view.gd -- --save=user://camera-test.json --mute
run_check --headless --path . -s res://tests/test_drift_messages.gd -- --save=user://letters-test.json --mute
run_check --headless --path . -s res://tests/test_boat_travel.gd -- --save=user://boat-test.json --mute
run_check --headless --path . -s res://tests/test_progression.gd -- --save=user://progression-test.json --mute
