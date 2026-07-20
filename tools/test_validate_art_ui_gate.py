from __future__ import annotations

import json
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

from validate_art_ui_gate import (
    _require_art_process_rules,
    _require_image_quality_profile,
    _require_manual_editor_navigation,
    _require_manual_clean_background_audit,
    _require_manual_layer_contract,
    _require_manual_placement_rules,
    _require_manual_runtime_surface_lineage,
    _require_manual_stage_payload_preview,
    _require_no_agent_drawn_owner_proof,
    _require_no_fallback_contract_values,
    _require_reference_lock_rules,
    _require_repeated_region_group_policy,
    _require_screenshot_capture_policy,
    _require_screenshot_dimensions,
    _require_source_extraction_rules,
    _require_ssot_registry_rules,
    _require_visual_composition_rules,
)


class ManualPlacementRepeatedRegionPolicyTest(unittest.TestCase):
    def test_art_ui_contract_rejects_fallback_and_default_alias_values(self) -> None:
        failures: list[str] = []
        contract = {
            "image_quality_profile": {
                "ui_source_assets": {
                    "fallback_button_shell": {
                        "path": "Assets/UI/button.png",
                    },
                    "title_button_shell": {
                        "default_path": "Assets/UI/button.png",
                    },
                }
            },
            "manual_placement": {
                "surfaces": {
                    "Title": {
                        "fallback_editor_config": "docs/art_ui_manual_placement/title.json",
                    }
                }
            },
            "visual_composition_rules": {
                "surfaces": {
                    "Title": {
                        "fallback_metric": [0, 0, 10, 10],
                    }
                }
            },
        }

        _require_no_fallback_contract_values(contract, failures)

        self.assertTrue(any("fallback_button_shell" in failure for failure in failures), failures)
        self.assertTrue(any("default_path" in failure for failure in failures), failures)
        self.assertTrue(any("fallback_editor_config" in failure for failure in failures), failures)
        self.assertTrue(any("fallback_metric" in failure for failure in failures), failures)

    def test_agent_drawn_owner_proof_directory_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            proof_dir = root / "docs" / "screenshots" / "live_debug" / "owner_compare"
            proof_dir.mkdir(parents=True)
            (proof_dir / "owner_skill_yellow_regions.png").write_bytes(b"fake")
            failures: list[str] = []

            _require_no_agent_drawn_owner_proof(root, {}, failures)

            self.assertTrue(any("agent-drawn owner proof" in failure for failure in failures), failures)

    def test_rect_semantic_boundary_requires_control_and_visual_roles(self) -> None:
        failures: list[str] = []
        contract = {
            "visual_composition_rules": {
                "surfaces": {
                    "Upgrade overlay": {
                        "viewport_size": [480, 270],
                        "surface_rect": [0, 0, 340, 188],
                        "safe_padding": 4,
                        "rect_semantic_boundary": {
                            "required": True,
                            "roles": {
                                "control_owner_rect": {
                                    "source": "theme metric",
                                }
                            },
                        },
                    }
                }
            }
        }

        _require_visual_composition_rules(contract, {}, failures)

        self.assertTrue(any("missing role visual_shell_rect" in failure for failure in failures), failures)
        self.assertTrue(any("control_owner_rect missing coordinate_space" in failure for failure in failures), failures)

    def test_source_extraction_rejects_auto_outline_author(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "source.png").write_bytes(b"placeholder")
            (root / "alpha.png").write_bytes(b"placeholder")
            (root / "editor.html").write_text(
                "Owner Polygon owner_manual_polygon No grid Download JSON",
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "source_extraction": {
                    "required": True,
                    "families": {
                        "actors": {
                            "status": "OWNER_POLYGON_OUTLINE_PENDING",
                            "outline_author": "agent_auto_hull",
                            "extraction_allowed": True,
                            "source_sheet": "source.png",
                            "alpha_sheet": "alpha.png",
                            "editor_html": "editor.html",
                            "owner_outline_json": "owner.json",
                            "asset_keys": ["player_ship"],
                        }
                    },
                }
            }
            texts = {
                "style_bible": "owner_manual_polygon OWNER_POLYGON_OUTLINE_PENDING No auto-hull No grid slicing",
            }

            _require_source_extraction_rules(root, contract, texts, failures)

        self.assertTrue(any("outline_author must be owner_manual_polygon" in failure for failure in failures), failures)
        self.assertTrue(any("extraction_allowed must be false" in failure for failure in failures), failures)

    def test_source_extraction_requires_owner_polygon_json_after_approval(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "source.png").write_bytes(b"placeholder")
            (root / "alpha.png").write_bytes(b"placeholder")
            (root / "editor.html").write_text(
                "Owner Polygon owner_manual_polygon No grid Download JSON",
                encoding="utf-8",
            )
            (root / "owner.json").write_text(
                json.dumps(
                    {
                        "outline_author": "owner_manual_polygon",
                        "assets": {
                            "player_ship": {
                                "outline": [[0.1, 0.1], [0.2, 0.1], [0.2, 0.2]],
                                "computed_rect": {"x": 0.1, "y": 0.1, "w": 0.1, "h": 0.1},
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "source_extraction": {
                    "required": True,
                    "families": {
                        "actors": {
                            "status": "OWNER_POLYGON_OUTLINE_APPROVED",
                            "outline_author": "owner_manual_polygon",
                            "extraction_allowed": True,
                            "source_sheet": "source.png",
                            "alpha_sheet": "alpha.png",
                            "editor_html": "editor.html",
                            "owner_outline_json": "owner.json",
                            "asset_keys": ["player_ship"],
                        }
                    },
                }
            }
            texts = {
                "style_bible": "owner_manual_polygon OWNER_POLYGON_OUTLINE_PENDING No auto-hull No grid slicing",
            }

            _require_source_extraction_rules(root, contract, texts, failures)

        self.assertEqual([], failures)

    def test_art_pipeline_reset_blocks_manual_placement_claims(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_RESET",
                "master_theme_status": "MASTER_THEME_PENDING",
                "source_asset_status": "ART_SOURCE_NOT_READY",
                "old_art_status": "OLD_ART_REJECTED",
                "manual_placement_allowed": False,
            },
            "manual_placement": {
                "required": True,
                "surfaces": {
                    "Level HUD": {
                        "status": "READY_FOR_OWNER_ADJUSTMENT",
                    }
                },
            },
        }
        texts = {
            "style_bible": "ART_PIPELINE_RESET MASTER_THEME_PENDING ART_SOURCE_NOT_READY OLD_ART_REJECTED",
        }
        screenshot_rows = {
            "Level HUD": ["Level HUD", "", "", "READY_FOR_OWNER_ADJUSTMENT"],
        }

        _require_art_process_rules(Path.cwd(), contract, texts, screenshot_rows, failures)

        self.assertTrue(any("manual_placement.required must be false" in failure for failure in failures), failures)
        self.assertTrue(any("manual_placement.surfaces must be empty" in failure for failure in failures), failures)
        self.assertTrue(any("manual-placement status while manual placement is disabled" in failure for failure in failures), failures)

    def test_disabled_manual_placement_blocks_status_fallbacks_in_generated_editors(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            editor_dir = root / "docs" / "art_ui_manual_placement"
            editor_dir.mkdir(parents=True)
            (editor_dir / "index.html").write_text("MANUAL_PLACEMENT_DISABLED", encoding="utf-8")
            (editor_dir / "skill_region_editor_config.json").write_text(
                json.dumps({"surface": "Skill", "status": "DRAFT_SEED_ONLY", "regions": {}}),
                encoding="utf-8",
            )
            (editor_dir / "skill_region_editor.html").write_text(
                'status: config.status || "READY_FOR_OWNER_ADJUSTMENT"',
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "art_process": {
                    "status": "ART_PIPELINE_ACTIVE",
                    "master_theme_status": "MASTER_THEME_APPROVED",
                    "source_asset_status": "SOURCE_ASSET_APPROVED",
                    "old_art_status": "OLD_ART_REJECTED",
                    "manual_placement_allowed": False,
                },
                "manual_placement": {"required": False, "surfaces": {}},
            }
            texts = {
                "style_bible": "ART_PIPELINE_ACTIVE MASTER_THEME_APPROVED SOURCE_ASSET_APPROVED OLD_ART_REJECTED",
            }

            _require_art_process_rules(root, contract, texts, {}, failures)

        self.assertTrue(any("manual placement editor must not invent READY_FOR_OWNER_ADJUSTMENT" in failure for failure in failures), failures)

    def test_manual_editor_requires_multiselect_controls(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            editor = root / "editor.html"
            editor.write_text(
                'Menu href="index.html" Image - mobile_ultra placement proof Text or slot content '
                'Yellow frame coordinates Payload references live here layerContract sampleAsset selectedKey',
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_manual_editor_navigation("Upgrade overlay", editor, {"home_href": "index.html"}, failures)

        self.assertTrue(any("missing multi-select control: selectedKeys" in failure for failure in failures), failures)
        self.assertTrue(any("missing multi-select control: ctrlKey" in failure for failure in failures), failures)
        self.assertTrue(any("missing multi-select control: isSelected" in failure for failure in failures), failures)
        self.assertTrue(any("missing multi-select control: clearSelection" in failure for failure in failures), failures)
        self.assertTrue(any("missing multi-select control: proportionalGroupScaleFactor" in failure for failure in failures), failures)

    def test_art_ui_gate_template_starts_manual_placement_disabled(self) -> None:
        template_path = Path("docs/templates/art_ui_gate/art_ui_gate_contract.template.json")
        template = json.loads(template_path.read_text(encoding="utf-8"))

        art_process = template.get("art_process", {})
        manual = template.get("manual_placement", {})

        self.assertEqual(False, art_process.get("manual_placement_allowed"))
        self.assertEqual("ART_PIPELINE_RESET", art_process.get("status"))
        self.assertEqual(False, manual.get("required"))
        self.assertEqual("DRAFT_SEED_ONLY", manual.get("draft_seed_status"))
        self.assertEqual({}, manual.get("surfaces"))

    def test_owner_proof_policy_must_be_explicit_in_art_ui_contract(self) -> None:
        failures: list[str] = []

        _require_no_agent_drawn_owner_proof(Path.cwd(), {"art_process": {}}, failures)

        self.assertTrue(any("owner_proof_policy missing" in failure for failure in failures), failures)

    def test_art_pipeline_reset_requires_unapproved_theme_and_source(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_RESET",
                "master_theme_status": "MASTER_THEME_APPROVED",
                "source_asset_status": "SOURCE_ASSET_APPROVED",
                "old_art_status": "OLD_ART_PROTOTYPE_ONLY",
                "manual_placement_allowed": True,
            }
        }
        texts = {
            "style_bible": "ART_PIPELINE_RESET MASTER_THEME_APPROVED SOURCE_ASSET_APPROVED OLD_ART_PROTOTYPE_ONLY",
        }

        _require_art_process_rules(Path.cwd(), contract, texts, {}, failures)

        self.assertTrue(any("MASTER_THEME_PENDING" in failure for failure in failures), failures)
        self.assertTrue(any("ART_SOURCE_NOT_READY" in failure for failure in failures), failures)
        self.assertTrue(any("OLD_ART_REJECTED" in failure for failure in failures), failures)
        self.assertTrue(any("manual_placement_allowed = false" in failure for failure in failures), failures)

    def test_source_approval_requires_reference_lock(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_ACTIVE",
                "master_theme_status": "MASTER_THEME_APPROVED",
                "source_asset_status": "SOURCE_ASSET_APPROVED",
                "old_art_status": "OLD_ART_REJECTED",
                "manual_placement_allowed": False,
            },
            "reference_lock": {
                "reference_sheet_status": "REFERENCE_SHEET_PENDING",
                "generation_spec_status": "GENERATION_SPEC_PENDING",
                "reference_sheet": "docs/art_reference_sheet.md",
                "generation_spec": "docs/art_generation_spec.md",
                "min_references": 10,
                "max_references": 30,
                "required_buckets": ["Vietnamese form language"],
            },
        }

        _require_reference_lock_rules(Path.cwd(), contract, {}, failures)

        self.assertTrue(any("SOURCE_ASSET_APPROVED requires REFERENCE_SHEET_LOCKED" in failure for failure in failures), failures)
        self.assertTrue(any("SOURCE_ASSET_APPROVED requires GENERATION_SPEC_LOCKED" in failure for failure in failures), failures)

    def test_owner_polygon_editor_must_use_alpha_sheet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "source.png").write_bytes(b"placeholder")
            (root / "alpha.png").write_bytes(b"placeholder")
            (root / "editor.html").write_text(
                "Owner Polygon owner_manual_polygon No grid Download JSON",
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "source_extraction": {
                    "required": True,
                    "families": {
                        "actors": {
                            "status": "OWNER_POLYGON_OUTLINE_PENDING",
                            "outline_author": "owner_manual_polygon",
                            "extraction_allowed": False,
                            "source_sheet": "source.png",
                            "editor_sheet": "source.png",
                            "alpha_sheet": "alpha.png",
                            "editor_html": "editor.html",
                            "owner_outline_json": "owner.json",
                            "asset_keys": ["player_ship"],
                        }
                    },
                }
            }
            texts = {
                "style_bible": "owner_manual_polygon OWNER_POLYGON_OUTLINE_PENDING No auto-hull No grid slicing",
            }

            _require_source_extraction_rules(root, contract, texts, failures)

        self.assertTrue(any("editor_sheet must equal alpha_sheet" in failure for failure in failures), failures)

    def test_owner_polygon_pending_requires_alpha_sheet_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "source.png").write_bytes(b"placeholder")
            (root / "editor.html").write_text(
                "Owner Polygon owner_manual_polygon No grid Download JSON",
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "source_extraction": {
                    "required": True,
                    "families": {
                        "actors": {
                            "status": "OWNER_POLYGON_OUTLINE_PENDING",
                            "outline_author": "owner_manual_polygon",
                            "extraction_allowed": False,
                            "source_sheet": "source.png",
                            "editor_sheet": "source.png",
                            "alpha_sheet": "alpha.png",
                            "editor_html": "editor.html",
                            "owner_outline_json": "owner.json",
                            "asset_keys": ["player_ship"],
                        }
                    },
                }
            }
            texts = {
                "style_bible": "owner_manual_polygon OWNER_POLYGON_OUTLINE_PENDING No auto-hull No grid slicing",
            }

            _require_source_extraction_rules(root, contract, texts, failures)

        self.assertTrue(any("alpha_sheet missing path" in failure for failure in failures), failures)

    def test_gameplay_source_asset_quality_requires_qc_and_min_density(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_png(root / "actor.png", 12, 12)
            (root / "actor_qc.json").write_text(
                json.dumps(
                    {
                        "assets": {
                            "player_ship": {
                                "output": "actor.png",
                                "alpha_ok": True,
                                "edge_ok": True,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "image_quality_profile": {
                    "profile": "mobile_ultra",
                    "runtime_ui_source_scale": 6,
                    "ui_reference_viewport": [480, 270],
                    "min_editor_background_size": [1920, 1080],
                    "ui_source_assets": {
                        "logo_mark": {
                            "path": "actor.png",
                            "owner_size": [1, 1],
                            "source_scale": 6,
                            "size_policy": "minimum",
                            "resize_mode": "cover_crop_exact",
                        }
                    },
                    "gameplay_source_assets": {
                        "player_ship": {
                            "path": "actor.png",
                            "visual_size": [12, 12],
                            "source_scale": 6,
                            "qc": "actor_qc.json",
                            "alpha_required": True,
                        }
                    },
                }
            }

            _require_image_quality_profile(root, contract, failures)

        self.assertTrue(any("below visual 12x12 * scale 6" in failure for failure in failures), failures)

    def test_gameplay_source_asset_qc_mismatch_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_png(root / "actor.png", 12, 12)
            (root / "actor_qc.json").write_text(
                json.dumps(
                    {
                        "assets": {
                            "player_ship": {
                                "output": "wrong.png",
                                "alpha_ok": True,
                                "edge_ok": True,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "image_quality_profile": {
                    "profile": "mobile_ultra",
                    "runtime_ui_source_scale": 6,
                    "ui_reference_viewport": [480, 270],
                    "min_editor_background_size": [1920, 1080],
                    "ui_source_assets": {
                        "logo_mark": {
                            "path": "actor.png",
                            "owner_size": [1, 1],
                            "source_scale": 6,
                            "size_policy": "minimum",
                            "resize_mode": "cover_crop_exact",
                        }
                    },
                    "gameplay_source_assets": {
                        "player_ship": {
                            "path": "actor.png",
                            "visual_size": [1, 1],
                            "source_scale": 6,
                            "qc": "actor_qc.json",
                            "alpha_required": True,
                        }
                    },
                }
            }

            _require_image_quality_profile(root, contract, failures)

        self.assertTrue(any("qc output wrong.png must match path actor.png" in failure for failure in failures), failures)

    def test_alpha_source_asset_accepts_icon_qc(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_png(root / "icon.png", 180, 180)
            (root / "icon_qc.json").write_text(
                json.dumps(
                    {
                        "assets": {
                            "upgrade_signal_focus_icon": {
                                "output": "icon.png",
                                "alpha_ok": True,
                                "edge_ok": True,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "image_quality_profile": {
                    "profile": "mobile_ultra",
                    "runtime_ui_source_scale": 6,
                    "ui_reference_viewport": [480, 270],
                    "min_editor_background_size": [1920, 1080],
                    "ui_source_assets": {
                        "logo_mark": {
                            "path": "icon.png",
                            "owner_size": [1, 1],
                            "source_scale": 6,
                            "size_policy": "minimum",
                            "resize_mode": "cover_crop_exact",
                        }
                    },
                    "alpha_source_assets": {
                        "upgrade_signal_focus_icon": {
                            "path": "icon.png",
                            "visual_size": [28, 28],
                            "source_scale": 6,
                            "qc": "icon_qc.json",
                            "alpha_required": True,
                        }
                    },
                }
            }

            _require_image_quality_profile(root, contract, failures)

        self.assertEqual([], failures)

    def test_locked_reference_sheet_requires_rows_and_buckets(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs"
            docs.mkdir()
            (docs / "art_reference_sheet.md").write_text(
                "\n".join(
                    [
                        "# Art Reference Sheet",
                        "",
                        "| Reference | Bucket | Learn This | Do Not Copy | Source Use |",
                        "|---|---|---|---|---|",
                        "| https://example.com/ref-01 | Vietnamese form language | bronze rhythm | exact protected artwork | silhouette only |",
                    ]
                ),
                encoding="utf-8",
            )
            (docs / "art_generation_spec.md").write_text(
                "# Art Generation Spec\n\nVietnam Tech Fantasy Hybrid\n\nruntime job\nasset family\n9Router\ncx/gpt-5.5-image\n",
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "art_process": {
                    "source_asset_status": "ART_SOURCE_NOT_READY",
                },
                "reference_lock": {
                    "reference_sheet_status": "REFERENCE_SHEET_LOCKED",
                    "generation_spec_status": "GENERATION_SPEC_LOCKED",
                    "reference_sheet": "docs/art_reference_sheet.md",
                    "generation_spec": "docs/art_generation_spec.md",
                    "min_references": 10,
                    "max_references": 30,
                    "required_buckets": [
                        "Vietnamese form language",
                        "Vietnamese material language",
                    ],
                },
            }

            _require_reference_lock_rules(root, contract, {}, failures)

        self.assertTrue(any("reference count 1 below min 10" in failure for failure in failures), failures)
        self.assertTrue(any("missing required bucket: Vietnamese material language" in failure for failure in failures), failures)

    def test_runtime_fit_requires_owner_placement_approval(self) -> None:
        failures: list[str] = []
        contract = {
            "runtime_fit_rows": {
                "Upgrade overlay": ["RUNTIME_FIT_PASS"],
            },
            "manual_placement": {
                "required": True,
                "surfaces": {
                    "Upgrade overlay": {
                        "status": "READY_FOR_OWNER_ADJUSTMENT",
                        "applies_to": ["panel_title"],
                    }
                },
            },
        }
        screenshot_rows = {
            "Upgrade overlay": ["Upgrade overlay", "", "", "RUNTIME_FIT_PASS"],
        }

        _require_manual_placement_rules(Path.cwd(), contract, screenshot_rows, failures)

        self.assertTrue(
            any("must be OWNER_PLACEMENT_APPROVED before RUNTIME_FIT_PASS" in failure for failure in failures),
            failures,
        )

    def test_blank_screenshot_proof_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            screenshot = root / "blank.png"
            _write_png(screenshot, 12, 12)
            failures: list[str] = []
            contract = {
                "expected_screenshots": {
                    "blank.png": [12, 12],
                },
                "screenshot_capture_policy": {
                    "approved_methods": ["godot_scene_capture_runtime_stretch", "foreground_window_capture"],
                    "forbidden_methods": ["PrintWindow"],
                    "requires_visual_inspection": True,
                    "requires_nonblank_pixel_audit": True,
                    "min_sampled_unique_colors": 16,
                    "min_luma_stddev": 2.0,
                    "min_luma_mean": 1.0,
                },
            }
            texts = {
                "screenshots": "Approved capture methods: godot_scene_capture_runtime_stretch foreground_window_capture. Forbidden: PrintWindow.",
            }

            policy = _require_screenshot_capture_policy(contract, texts, failures)
            _require_screenshot_dimensions(root, contract, policy, failures)

        self.assertTrue(any("looks blank" in failure for failure in failures), failures)

    def test_indexed_duplicate_regions_require_repeated_group(self) -> None:
        failures: list[str] = []
        config = {
            "regions": {
                "card_1_title": {
                    "slot_kind": "text",
                    "sample_text": "Skill A",
                    "x": 0.1,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                },
                "card_2_title": {
                    "slot_kind": "text",
                    "sample_text": "Skill B",
                    "x": 0.4,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                },
            }
        }

        _require_repeated_region_group_policy("Upgrade overlay", config, failures)

        self.assertTrue(
            any("without repeated_region_groups" in failure for failure in failures),
            failures,
        )

    def test_template_group_derives_concrete_instances(self) -> None:
        failures: list[str] = []
        config = {
            "regions": {
                "card_title_template": {
                    "slot_kind": "text",
                    "sample_text": "Skill Name Lv 1",
                    "x": 0.1,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                }
            },
            "repeated_region_groups": {
                "upgrade_cards": {
                    "rule": "drag_once_apply_to_all_instances",
                    "templates": {"title": "card_title_template"},
                    "instances": [
                        {
                            "id": "card_1",
                            "offset": [0.0, 0.0],
                            "exports": {"title": "card_1_title"},
                        },
                        {
                            "id": "card_2",
                            "offset": [0.25, 0.0],
                            "exports": {"title": "card_2_title"},
                        },
                    ],
                }
            },
        }

        _require_repeated_region_group_policy("Upgrade overlay", config, failures)

        self.assertEqual([], failures)

    def test_clean_background_audit_is_required(self) -> None:
        failures: list[str] = []

        _require_manual_clean_background_audit(Path.cwd(), "Upgrade overlay", {}, self._editor_config(), failures)

        self.assertTrue(any("clean_background_audit" in failure for failure in failures), failures)

    def test_clean_background_and_placeable_asset_sets_cannot_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            asset_dir = root / "Assets" / "UI"
            asset_dir.mkdir(parents=True)
            _write_png(asset_dir / "panel.png", 16, 16)
            config = self._editor_config()
            config.update(
                {
                    "__source_path": "docs/art_ui_manual_placement/config.json",
                    "surface_asset_keys": ["panel"],
                    "clean_background_asset_keys": ["panel"],
                    "placeable_surface_asset_keys": ["panel"],
                    "runtime_asset_paths": {"panel": "../../Assets/UI/panel.png"},
                }
            )
            failures: list[str] = []

            _require_manual_runtime_surface_lineage(root, "Upgrade overlay", config, failures)

            self.assertTrue(any("cannot be both clean-background and placeable" in failure for failure in failures), failures)

    def test_manual_editor_config_requires_runtime_surface_lineage(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs" / "art_ui_manual_placement"
            screenshots = root / "docs" / "screenshots"
            docs.mkdir(parents=True)
            screenshots.mkdir(parents=True)
            _write_png(screenshots / "upgrade_clean.png", 1280, 720)
            config = self._editor_config()
            config.update(
                {
                    "status": "OWNER_PLACEMENT_APPROVED",
                    "home_href": "index.html",
                    "layer_contract": {
                        "background": {"contains_runtime_payload": False},
                        "content_panel": {"drawn_on_stage": True},
                        "stage_overlay": {"draws_payload": True, "payload_preview_is_baked": False},
                    },
                    "stage_preview_enabled": True,
                    "clean_background_payload_slot_kinds_removed": ["text", "icon"],
                    "stage_aspect": [16, 9],
                }
            )
            (docs / "config.json").write_text(json.dumps(config), encoding="utf-8")
            (docs / "editor.html").write_text(
                'Menu href="index.html" Image - mobile_ultra placement proof Text or slot content '
                'Yellow frame coordinates Payload references live here layerContract sampleAsset '
                'regionPayloadPreview getStagePreviewAsset stage_preview_enabled '
                'payload preview is a separate DOM layer',
                encoding="utf-8",
            )
            (docs / "export.json").write_text(json.dumps(dict(config)), encoding="utf-8")
            (docs / "audit.json").write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "background_payload_policy": "clean_shell_frame_only",
                        "capture_method": "hide runtime payload nodes",
                        "verification_basis": "capture_pipeline_hidden_payload_nodes",
                        "checked_backgrounds": {
                            "desktop": {
                                "path": "../screenshots/upgrade_clean.png",
                                "contains_runtime_text": False,
                                "contains_runtime_icon": False,
                                "contains_runtime_image": False,
                                "contains_runtime_control": False,
                                "removed_slot_kinds": ["text", "icon"],
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            (root / "docs" / "icons").mkdir()
            _write_png(root / "docs" / "icons" / "icon.png", 32, 32)
            failures: list[str] = []
            contract = {
                "runtime_fit_rows": {"Upgrade overlay": ["RUNTIME_FIT_PASS"]},
                "visual_composition_rules": {
                    "surfaces": {
                        "Upgrade overlay": {
                            "text_safe_zones": {"panel_title": [0, 0, 10, 10]},
                            "slot_rects": {"card_icon_template": [0, 0, 10, 10]},
                        }
                    }
                },
                "manual_placement": {
                    "required": True,
                    "draft_seed_status": "DRAFT_SEED_ONLY",
                    "seed_regions_are_non_exportable": True,
                    "owner_final_only": True,
                    "copy_to_runtime_requires": "OWNER_PLACEMENT_APPROVED",
                    "surfaces": {
                        "Upgrade overlay": {
                            "status": "OWNER_PLACEMENT_APPROVED",
                            "applies_to": ["panel_title", "card_icon_template"],
                            "editor_config": "docs/art_ui_manual_placement/config.json",
                            "editor_html": "docs/art_ui_manual_placement/editor.html",
                            "export_json": "docs/art_ui_manual_placement/export.json",
                            "clean_background_audit": "docs/art_ui_manual_placement/audit.json",
                            "min_background_size": [1280, 720],
                        }
                    },
                },
            }

            _require_manual_placement_rules(
                root,
                contract,
                {"Upgrade overlay": ["Upgrade overlay", "", "", "RUNTIME_FIT_PASS"]},
                failures,
            )

        self.assertTrue(any("surface_asset_keys" in failure for failure in failures), failures)
        self.assertTrue(any("runtime_asset_paths" in failure for failure in failures), failures)
        self.assertTrue(any("background_runtime_basis" in failure for failure in failures), failures)

    def test_icon_slot_requires_stage_payload_preview(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs" / "art_ui_manual_placement"
            docs.mkdir(parents=True)
            editor_html = docs / "editor.html"
            editor_html.write_text(
                "Menu Image - mobile_ultra placement proof Text or slot content "
                "Yellow frame coordinates Payload references live here layerContract sampleAsset",
                encoding="utf-8",
            )
            config = self._editor_config()
            config.update(
                {
                    "layer_contract": {
                        "background": {"contains_runtime_payload": False},
                        "content_panel": {"drawn_on_stage": False},
                        "stage_overlay": {"draws_payload": False},
                    },
                    "stage_preview_enabled": False,
                }
            )
            config["regions"]["card_icon_template"]["stage_preview_enabled"] = False
            failures: list[str] = []

            _require_manual_layer_contract("Upgrade overlay", config, failures)
            _require_manual_stage_payload_preview("Upgrade overlay", config, editor_html, failures)

        self.assertTrue(any("stage_preview_enabled" in failure for failure in failures), failures)
        self.assertTrue(any("missing stage payload preview" in failure for failure in failures), failures)

    def test_clean_background_audit_blocks_baked_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "audit.json").write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "background_payload_policy": "clean_shell_frame_only",
                        "capture_method": "hide runtime labels and icon nodes before capture",
                        "verification_basis": "capture_pipeline_hidden_payload_nodes",
                        "checked_backgrounds": {
                            "desktop": {
                                "path": "../screenshots/upgrade_clean.png",
                                "contains_runtime_text": True,
                                "contains_runtime_icon": False,
                                "contains_runtime_image": False,
                                "contains_runtime_control": False,
                                "removed_slot_kinds": ["text", "icon"],
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_manual_clean_background_audit(
                root,
                "Upgrade overlay",
                {"clean_background_audit": "audit.json"},
                self._editor_config(),
                failures,
            )

        self.assertTrue(any("contains_runtime_text" in failure for failure in failures), failures)

    def test_clean_background_audit_accepts_clean_payload_proof(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "audit.json").write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "background_payload_policy": "clean_shell_frame_only",
                        "capture_method": "hide runtime labels and icon nodes before capture",
                        "verification_basis": "capture_pipeline_hidden_payload_nodes",
                        "checked_backgrounds": {
                            "desktop": {
                                "path": "../screenshots/upgrade_clean.png",
                                "contains_runtime_text": False,
                                "contains_runtime_icon": False,
                                "contains_runtime_image": False,
                                "contains_runtime_control": False,
                                "removed_slot_kinds": ["text", "icon"],
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_manual_clean_background_audit(
                root,
                "Upgrade overlay",
                {"clean_background_audit": "audit.json"},
                self._editor_config(),
                failures,
            )

        self.assertEqual([], failures)

    def test_ssot_registry_rejects_duplicate_function_canonicals(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs"
            docs.mkdir()
            (docs / "ssot_registry.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "policy": "one_function_one_canonical",
                        "functions": [
                            {
                                "function_id": "upgrade_overlay_placement",
                                "canonical_role": "owner_input_ssot",
                                "canonical_file": "docs/a.json",
                            },
                            {
                                "function_id": "upgrade_overlay_placement",
                                "canonical_role": "owner_input_ssot",
                                "canonical_file": "docs/b.json",
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )
            (docs / "a.json").write_text("{}", encoding="utf-8")
            (docs / "b.json").write_text("{}", encoding="utf-8")
            failures: list[str] = []

            _require_ssot_registry_rules(
                root,
                {"ssot_registry": {"path": "docs/ssot_registry.json"}},
                {"gate": "one_function_one_canonical"},
                failures,
            )

        self.assertTrue(any("duplicate function_id" in failure for failure in failures), failures)

    def test_ssot_registry_requires_generated_artifact_source_trace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs"
            docs.mkdir()
            (docs / "ssot_registry.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "policy": "one_function_one_canonical",
                        "functions": [
                            {
                                "function_id": "upgrade_overlay_placement",
                                "canonical_role": "owner_input_ssot",
                                "canonical_file": "docs/config.json",
                                "derived_files": [
                                    {
                                        "path": "docs/editor.html",
                                        "role": "generated_artifact",
                                        "source": "docs/config.json",
                                    }
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            (docs / "config.json").write_text("{}", encoding="utf-8")
            (docs / "editor.html").write_text("<html>no source trace</html>", encoding="utf-8")
            failures: list[str] = []

            _require_ssot_registry_rules(
                root,
                {"ssot_registry": {"path": "docs/ssot_registry.json"}},
                {"gate": "one_function_one_canonical"},
                failures,
            )

        self.assertTrue(any("generated artifact missing source trace" in failure for failure in failures), failures)

    def test_ssot_registry_accepts_canonical_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs"
            docs.mkdir()
            (docs / "config.json").write_text("{}", encoding="utf-8")
            (docs / "editor.html").write_text(
                '{"__source_path":"docs/config.json"}',
                encoding="utf-8",
            )
            (docs / "export.json").write_text(
                json.dumps({"source": "docs/config.json"}),
                encoding="utf-8",
            )
            (docs / "audit.json").write_text("{}", encoding="utf-8")
            (docs / "ssot_registry.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "policy": "one_function_one_canonical",
                        "functions": [
                            {
                                "function_id": "upgrade_overlay_placement",
                                "canonical_role": "owner_input_ssot",
                                "canonical_file": "docs/config.json",
                                "derived_files": [
                                    {
                                        "path": "docs/editor.html",
                                        "role": "generated_artifact",
                                        "source": "docs/config.json",
                                    },
                                    {
                                        "path": "docs/export.json",
                                        "role": "generated_artifact",
                                        "source": "docs/config.json",
                                    },
                                ],
                                "evidence_files": [
                                    {
                                        "path": "docs/audit.json",
                                        "role": "evidence",
                                    }
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_ssot_registry_rules(
                root,
                {"ssot_registry": {"path": "docs/ssot_registry.json"}},
                {"gate": "one_function_one_canonical"},
                failures,
            )

        self.assertEqual([], failures)

    def _editor_config(self) -> dict:
        return {
            "backgrounds": {"desktop": "../screenshots/upgrade_clean.png"},
            "regions": {
                "panel_title": {
                    "slot_kind": "text",
                    "sample_text": "SIGNAL SKILL",
                    "x": 0.1,
                    "y": 0.1,
                    "w": 0.2,
                    "h": 0.1,
                },
                "card_icon_template": {
                    "slot_kind": "icon",
                    "sample_text": "Icon",
                    "sample_asset": "../icons/icon.png",
                    "stage_preview_enabled": True,
                    "x": 0.1,
                    "y": 0.3,
                    "w": 0.1,
                    "h": 0.1,
                },
            },
        }


def _write_png(path: Path, width: int, height: int) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + b"\xff\xff\xff\xff" * width for _ in range(height))
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(raw))
    payload += chunk(b"IEND", b"")
    path.write_bytes(payload)

if __name__ == "__main__":
    unittest.main()
