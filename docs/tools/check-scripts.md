# The check and test scripts (A-CODE-04; written by `node tools/check-scripts-table.mjs --write`, 2026-11-14)

262 scripts (`*_check.gd`, `*check.gd`, `*_test.gd` outside docs/). **116 run in CI**, 64 more run in the landing gate only, 0 are deliberately not run (reason given), **82 unreviewed** (their owners have not said yet; the number may only go down: `unreviewedMax` in tools/check-scripts.json).

| Folder | Scripts | CI | Gate only | Not run | Unreviewed |
| :--- | ---: | ---: | ---: | ---: | ---: |
| audio/tools | 14 | 0 | 1 | 0 | 13 |
| net/tools | 10 | 10 | 0 | 0 | 0 |
| render/anim/tools | 3 | 0 | 1 | 0 | 2 |
| render/camera/tests | 13 | 1 | 0 | 0 | 12 |
| render/tools | 24 | 4 | 15 | 0 | 5 |
| render/vfx/tools | 2 | 0 | 0 | 0 | 2 |
| sim/core/tools | 16 | 12 | 0 | 0 | 4 |
| sim/director/tools | 43 | 5 | 1 | 0 | 37 |
| sim/input/test | 45 | 0 | 45 | 0 | 0 |
| sim/world/tools | 84 | 84 | 0 | 0 | 0 |
| tools/l10n | 1 | 0 | 0 | 0 | 1 |
| ui/tools | 7 | 0 | 1 | 0 | 6 |

## Every script

| Script | Status | Reason |
| :--- | :--- | :--- |
| audio/tools/babble_check.gd | UNREVIEWED |  |
| audio/tools/beat_check.gd | UNREVIEWED |  |
| audio/tools/brawl_check.gd | UNREVIEWED |  |
| audio/tools/carry_check.gd | UNREVIEWED |  |
| audio/tools/coop_check.gd | UNREVIEWED |  |
| audio/tools/host_check.gd | GATE |  |
| audio/tools/moments_check.gd | UNREVIEWED |  |
| audio/tools/status_check.gd | UNREVIEWED |  |
| audio/tools/tone_check.gd | UNREVIEWED |  |
| audio/tools/tug_check.gd | UNREVIEWED |  |
| audio/tools/warm_async_check.gd | UNREVIEWED |  |
| audio/tools/warm_check.gd | UNREVIEWED |  |
| audio/tools/web_policy_check.gd | UNREVIEWED |  |
| audio/tools/world_check.gd | UNREVIEWED |  |
| net/tools/delay_check.gd | CI + gate |  |
| net/tools/desync_check.gd | CI + gate |  |
| net/tools/enet_check.gd | CI + gate |  |
| net/tools/lan_check.gd | CI |  |
| net/tools/rollback_check.gd | CI + gate |  |
| net/tools/spectator_check.gd | CI + gate |  |
| net/tools/swing_check.gd | CI |  |
| net/tools/transport_check.gd | CI + gate |  |
| net/tools/two_pc_check.gd | CI |  |
| net/tools/word_check.gd | CI |  |
| render/anim/tools/anim_check.gd | GATE |  |
| render/anim/tools/bake_check.gd | UNREVIEWED |  |
| render/anim/tools/socket_check.gd | UNREVIEWED |  |
| render/camera/tests/chase_rush_check.gd | CI |  |
| render/camera/tests/cross_ko_check.gd | UNREVIEWED |  |
| render/camera/tests/flight_shots_check.gd | UNREVIEWED |  |
| render/camera/tests/launch_shots_check.gd | UNREVIEWED |  |
| render/camera/tests/peak_retry_check.gd | UNREVIEWED |  |
| render/camera/tests/peak_shot_check.gd | UNREVIEWED |  |
| render/camera/tests/split_share_check.gd | UNREVIEWED |  |
| render/camera/tests/split_vision_check.gd | UNREVIEWED |  |
| render/camera/tests/swing_fight_check.gd | UNREVIEWED |  |
| render/camera/tests/swing_places_check.gd | UNREVIEWED |  |
| render/camera/tests/swing_read_check.gd | UNREVIEWED |  |
| render/camera/tests/swing_real_check.gd | UNREVIEWED |  |
| render/camera/tests/swing_shot_check.gd | UNREVIEWED |  |
| render/tools/after_check.gd | GATE |  |
| render/tools/bark_check.gd | UNREVIEWED |  |
| render/tools/city_check.gd | UNREVIEWED |  |
| render/tools/cover_water_check.gd | CI |  |
| render/tools/cue_check.gd | GATE |  |
| render/tools/cull_check.gd | UNREVIEWED |  |
| render/tools/depth_check.gd | GATE |  |
| render/tools/flash_check.gd | GATE |  |
| render/tools/flash_reg_check.gd | GATE |  |
| render/tools/flight_check.gd | GATE |  |
| render/tools/ground_check.gd | GATE |  |
| render/tools/hud_words_check.gd | GATE |  |
| render/tools/lake_water_check.gd | CI |  |
| render/tools/lane_check.gd | GATE |  |
| render/tools/open_check.gd | GATE |  |
| render/tools/outline_check.gd | UNREVIEWED |  |
| render/tools/pane_check.gd | GATE |  |
| render/tools/patch_check.gd | GATE |  |
| render/tools/props_check.gd | CI + gate |  |
| render/tools/shape_check.gd | GATE |  |
| render/tools/sky_check.gd | GATE |  |
| render/tools/stage_check.gd | GATE |  |
| render/tools/sweep_check.gd | CI + gate |  |
| render/tools/tile_check.gd | UNREVIEWED |  |
| render/vfx/tools/effects_check.gd | UNREVIEWED |  |
| render/vfx/tools/hash_check.gd | UNREVIEWED |  |
| sim/core/tools/ceil_check.gd | UNREVIEWED |  |
| sim/core/tools/coop_check.gd | UNREVIEWED |  |
| sim/core/tools/cross_check.gd | CI |  |
| sim/core/tools/cross_end_check.gd | CI |  |
| sim/core/tools/field_static_check.gd | CI |  |
| sim/core/tools/fights_check.gd | UNREVIEWED |  |
| sim/core/tools/fork_check.gd | CI |  |
| sim/core/tools/frame_check.gd | CI |  |
| sim/core/tools/kick_check.gd | CI |  |
| sim/core/tools/loop_check.gd | UNREVIEWED |  |
| sim/core/tools/memo_check.gd | CI |  |
| sim/core/tools/places_check.gd | CI + gate |  |
| sim/core/tools/power_check.gd | CI |  |
| sim/core/tools/rec_check.gd | CI |  |
| sim/core/tools/replay_xproc_check.gd | CI + gate |  |
| sim/core/tools/two_states_check.gd | CI + gate |  |
| sim/director/tools/a_press_check.gd | UNREVIEWED |  |
| sim/director/tools/arc_check.gd | UNREVIEWED |  |
| sim/director/tools/arrive_check.gd | UNREVIEWED |  |
| sim/director/tools/bark_reads_check.gd | CI |  |
| sim/director/tools/beam_ai_check.gd | UNREVIEWED |  |
| sim/director/tools/beam_front_check.gd | UNREVIEWED |  |
| sim/director/tools/beam_move_check.gd | UNREVIEWED |  |
| sim/director/tools/carry_round_check.gd | UNREVIEWED |  |
| sim/director/tools/chase_tap_check.gd | CI |  |
| sim/director/tools/city_push_check.gd | UNREVIEWED |  |
| sim/director/tools/driver_check.gd | UNREVIEWED |  |
| sim/director/tools/ending_check.gd | UNREVIEWED |  |
| sim/director/tools/ending_team_check.gd | UNREVIEWED |  |
| sim/director/tools/flick_keep_check.gd | UNREVIEWED |  |
| sim/director/tools/flight_strike_check.gd | UNREVIEWED |  |
| sim/director/tools/floorlift_check.gd | CI + gate |  |
| sim/director/tools/follow_check.gd | UNREVIEWED |  |
| sim/director/tools/full_send_check.gd | UNREVIEWED |  |
| sim/director/tools/knock_wall_check.gd | UNREVIEWED |  |
| sim/director/tools/launch_cost_check.gd | UNREVIEWED |  |
| sim/director/tools/launch_cuts_check.gd | UNREVIEWED |  |
| sim/director/tools/loader_check.gd | UNREVIEWED |  |
| sim/director/tools/location_check.gd | UNREVIEWED |  |
| sim/director/tools/morning_fixes_check.gd | UNREVIEWED |  |
| sim/director/tools/outside_check.gd | UNREVIEWED |  |
| sim/director/tools/pace_check.gd | UNREVIEWED |  |
| sim/director/tools/phrase_check.gd | UNREVIEWED |  |
| sim/director/tools/plane_check.gd | CI |  |
| sim/director/tools/press_answers_check.gd | UNREVIEWED |  |
| sim/director/tools/press_decides_check.gd | CI |  |
| sim/director/tools/push_mode_check.gd | UNREVIEWED |  |
| sim/director/tools/reads_check.gd | UNREVIEWED |  |
| sim/director/tools/refusal_reasons_check.gd | UNREVIEWED |  |
| sim/director/tools/relief_check.gd | UNREVIEWED |  |
| sim/director/tools/sigvariants_check.gd | GATE |  |
| sim/director/tools/stance_check.gd | UNREVIEWED |  |
| sim/director/tools/stick_check.gd | UNREVIEWED |  |
| sim/director/tools/stick_lunge_check.gd | UNREVIEWED |  |
| sim/director/tools/strike_stages_check.gd | UNREVIEWED |  |
| sim/director/tools/sure_reach_check.gd | UNREVIEWED |  |
| sim/director/tools/swing_check.gd | UNREVIEWED |  |
| sim/director/tools/swing_legal_check.gd | UNREVIEWED |  |
| sim/director/tools/walk_check.gd | UNREVIEWED |  |
| sim/input/test/agency_input_test.gd | GATE |  |
| sim/input/test/aim_test.gd | GATE |  |
| sim/input/test/b_no_beam_layouts_test.gd | GATE |  |
| sim/input/test/b_no_beam_test.gd | GATE |  |
| sim/input/test/beam_aim_test.gd | GATE |  |
| sim/input/test/brake_grapple_test.gd | GATE |  |
| sim/input/test/brake_ready_test.gd | GATE |  |
| sim/input/test/charge_lost_test.gd | GATE |  |
| sim/input/test/charge_test.gd | GATE |  |
| sim/input/test/chord_pick_test.gd | GATE |  |
| sim/input/test/dash_handover_test.gd | GATE |  |
| sim/input/test/dodge_held_test.gd | GATE |  |
| sim/input/test/flight_strike_b_test.gd | GATE |  |
| sim/input/test/full_send_haptic_test.gd | GATE |  |
| sim/input/test/haptics_test.gd | GATE |  |
| sim/input/test/hold_toggle_test.gd | GATE |  |
| sim/input/test/hub_test.gd | GATE |  |
| sim/input/test/impact_haptics_test.gd | GATE |  |
| sim/input/test/inert_knock_test.gd | GATE |  |
| sim/input/test/join_test.gd | GATE |  |
| sim/input/test/layout_test.gd | GATE |  |
| sim/input/test/left_hand_test.gd | GATE |  |
| sim/input/test/mode_test.gd | GATE |  |
| sim/input/test/pad_first_press_test.gd | GATE |  |
| sim/input/test/params_cache_test.gd | GATE |  |
| sim/input/test/press_read_test.gd | GATE |  |
| sim/input/test/push_stick_test.gd | GATE |  |
| sim/input/test/quick_read_test.gd | GATE |  |
| sim/input/test/refusal_cue_test.gd | GATE |  |
| sim/input/test/refusals_test.gd | GATE |  |
| sim/input/test/remap_test.gd | GATE |  |
| sim/input/test/stage_cue_test.gd | GATE |  |
| sim/input/test/stage_haptics_test.gd | GATE |  |
| sim/input/test/stall_keep_test.gd | GATE |  |
| sim/input/test/stance_test.gd | GATE |  |
| sim/input/test/stick_feel_test.gd | GATE |  |
| sim/input/test/strike_gate_test.gd | GATE |  |
| sim/input/test/strike_hub_test.gd | GATE |  |
| sim/input/test/strike_read_test.gd | GATE |  |
| sim/input/test/struggle_test.gd | GATE |  |
| sim/input/test/t1_latency_test.gd | GATE |  |
| sim/input/test/take_back_claw_test.gd | GATE |  |
| sim/input/test/touch_full_test.gd | GATE |  |
| sim/input/test/touch_glue_test.gd | GATE |  |
| sim/input/test/touch_test.gd | GATE |  |
| sim/world/tools/after_check.gd | CI + gate |  |
| sim/world/tools/arena_check.gd | CI + gate |  |
| sim/world/tools/b_check.gd | CI + gate |  |
| sim/world/tools/beam_grid_check.gd | CI |  |
| sim/world/tools/blastcheck.gd | CI + gate |  |
| sim/world/tools/blockcheck.gd | CI + gate |  |
| sim/world/tools/brunt_check.gd | CI + gate |  |
| sim/world/tools/burial_check.gd | CI + gate |  |
| sim/world/tools/bystanders_check.gd | CI |  |
| sim/world/tools/calm_read_check.gd | CI |  |
| sim/world/tools/campaign_check.gd | CI + gate |  |
| sim/world/tools/climate_check.gd | CI + gate |  |
| sim/world/tools/collateral_check.gd | CI + gate |  |
| sim/world/tools/control_check.gd | CI + gate |  |
| sim/world/tools/craters_check.gd | CI |  |
| sim/world/tools/deepencheck.gd | CI + gate |  |
| sim/world/tools/demostart_check.gd | CI + gate |  |
| sim/world/tools/density_check.gd | CI + gate |  |
| sim/world/tools/depthreads_check.gd | CI + gate |  |
| sim/world/tools/directcheck.gd | CI + gate |  |
| sim/world/tools/epoch_check.gd | CI + gate |  |
| sim/world/tools/everywhere_check.gd | CI |  |
| sim/world/tools/far_check.gd | CI + gate |  |
| sim/world/tools/far_people_check.gd | CI |  |
| sim/world/tools/farmap_check.gd | CI + gate |  |
| sim/world/tools/farsites_check.gd | CI + gate |  |
| sim/world/tools/field_cache_check.gd | CI |  |
| sim/world/tools/field_check.gd | CI |  |
| sim/world/tools/field_crack_check.gd | CI |  |
| sim/world/tools/field_crater_check.gd | CI |  |
| sim/world/tools/field_load_check.gd | CI |  |
| sim/world/tools/field_lot_check.gd | CI |  |
| sim/world/tools/field_plan_check.gd | CI |  |
| sim/world/tools/field_records_check.gd | CI |  |
| sim/world/tools/field_scorch_check.gd | CI |  |
| sim/world/tools/field_trench_check.gd | CI |  |
| sim/world/tools/field_water_check.gd | CI |  |
| sim/world/tools/fill_check.gd | CI + gate |  |
| sim/world/tools/fire_check.gd | CI + gate |  |
| sim/world/tools/floor_check.gd | CI + gate |  |
| sim/world/tools/gen2_state_check.gd | CI + gate |  |
| sim/world/tools/ground_check.gd | CI + gate |  |
| sim/world/tools/ground_props_check.gd | CI |  |
| sim/world/tools/host_check.gd | CI + gate |  |
| sim/world/tools/interior_check.gd | CI + gate |  |
| sim/world/tools/isect_check.gd | CI + gate |  |
| sim/world/tools/lakes_check.gd | CI + gate |  |
| sim/world/tools/land_check.gd | CI + gate |  |
| sim/world/tools/landmark_spare_check.gd | CI |  |
| sim/world/tools/lane_check.gd | CI + gate |  |
| sim/world/tools/lot_reach_check.gd | CI |  |
| sim/world/tools/meteor_crater_check.gd | CI |  |
| sim/world/tools/minecheck.gd | CI + gate |  |
| sim/world/tools/node_warm_check.gd | CI |  |
| sim/world/tools/noise_check.gd | CI + gate |  |
| sim/world/tools/places_cache_check.gd | CI |  |
| sim/world/tools/planet_cache_check.gd | CI |  |
| sim/world/tools/planet_check.gd | CI + gate |  |
| sim/world/tools/planet_world_check.gd | CI + gate |  |
| sim/world/tools/power_world_check.gd | CI |  |
| sim/world/tools/props_check.gd | CI + gate |  |
| sim/world/tools/props_wet_check.gd | CI + gate |  |
| sim/world/tools/relax_check.gd | CI |  |
| sim/world/tools/repeat_check.gd | CI + gate |  |
| sim/world/tools/ringpick_check.gd | CI + gate |  |
| sim/world/tools/rivers_check.gd | CI + gate |  |
| sim/world/tools/sea_rules_check.gd | CI + gate |  |
| sim/world/tools/sites_check.gd | CI + gate |  |
| sim/world/tools/skate_check.gd | CI + gate |  |
| sim/world/tools/stagecheck.gd | CI + gate |  |
| sim/world/tools/step_check.gd | CI |  |
| sim/world/tools/store_check.gd | CI |  |
| sim/world/tools/street_axis_check.gd | CI |  |
| sim/world/tools/struggle_dir_check.gd | CI |  |
| sim/world/tools/struggle_meet_check.gd | CI |  |
| sim/world/tools/surface_check.gd | CI + gate |  |
| sim/world/tools/surface_follow_check.gd | CI |  |
| sim/world/tools/switchon_check.gd | CI + gate |  |
| sim/world/tools/through_check.gd | CI |  |
| sim/world/tools/wall_check.gd | CI + gate |  |
| sim/world/tools/wall_hold_check.gd | CI |  |
| sim/world/tools/water_read_check.gd | CI |  |
| sim/world/tools/water_warm_check.gd | CI |  |
| sim/world/tools/wrecks_check.gd | CI + gate |  |
| tools/l10n/overflow_check.gd | UNREVIEWED |  |
| ui/tools/difficulty_check.gd | UNREVIEWED |  |
| ui/tools/frame_cost_check.gd | UNREVIEWED |  |
| ui/tools/hud_check.gd | GATE |  |
| ui/tools/load_check.gd | UNREVIEWED |  |
| ui/tools/pseudo_switch_check.gd | UNREVIEWED |  |
| ui/tools/read_ahead_check.gd | UNREVIEWED |  |
| ui/tools/text_size_check.gd | UNREVIEWED |  |
