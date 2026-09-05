#!/usr/bin/env python3
"""
Static safeguards for Ticking (Plasma 6 plasmoid).

Runs without a Plasma desktop. Exit 0 only when every check passes.
Designed for GitHub Actions and local pre-push / pre-release use.
"""
from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
warnings: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def check_required_paths() -> None:
    required = [
        "metadata.json",
        "contents/config/config.qml",
        "contents/config/main.xml",
        "contents/ui/main.qml",
        "contents/ui/FullRepresentation.qml",
        "contents/ui/CompactRepresentation.qml",
        "contents/ui/configGeneral.qml",
        "contents/ui/components/ClockView.qml",
        "contents/ui/components/CountdownView.qml",
        "contents/ui/components/StopwatchView.qml",
        "contents/ui/components/SegmentedNav.qml",
        "contents/ui/components/QuoteBar.qml",
        "contents/ui/components/QuoteLibrary.js",
        "LICENSE",
        "scripts/package.sh",
    ]
    for rel in required:
        if not (ROOT / rel).is_file():
            fail(f"missing required file: {rel}")


def check_metadata() -> dict | None:
    path = ROOT / "metadata.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"metadata.json is not valid JSON: {exc}")
        return None

    if data.get("KPackageStructure") != "Plasma/Applet":
        fail('metadata.json KPackageStructure must be "Plasma/Applet"')

    plugin = data.get("KPlugin") or {}
    for key in ("Id", "Name", "Version", "License", "Authors"):
        if key not in plugin:
            fail(f"metadata.json missing KPlugin.{key}")

    plugin_id = plugin.get("Id", "")
    if plugin_id != "org.adi_il.ticking":
        fail(f'unexpected plugin Id "{plugin_id}" (expected org.adi_il.ticking)')

    version = str(plugin.get("Version", ""))
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        fail(f'version "{version}" is not semver X.Y.Z')

    api = data.get("X-Plasma-API-Minimum-Version")
    if not api or not str(api).startswith("6"):
        fail(f"X-Plasma-API-Minimum-Version must be 6.x (got {api!r})")

    license_val = str(plugin.get("License", ""))
    if "GPL-3.0" not in license_val:
        warn(f"License is {license_val!r}; expected GPL-3.0-or-later style")

    return data


def check_main_xml() -> None:
    path = ROOT / "contents/config/main.xml"
    try:
        tree = ET.parse(path)
    except ET.ParseError as exc:
        fail(f"main.xml is not well-formed XML: {exc}")
        return

    root = tree.getroot()
    # KCFG entries live under group/entry
    entries = {
        el.attrib.get("name"): el.attrib.get("type")
        for el in root.iter()
        if el.tag.endswith("entry") and el.attrib.get("name")
    }
    expected = {
        "targetTimestamp": "String",
        "startTimestamp": "String",
        "customTitle": "String",
        "themeMode": "String",
        "showMilliseconds": "Bool",
        "translucency": "Double",
        "activeTab": "Int",
        "hourFormat24": "Bool",
        "accentColor": "String",
        "showProgress": "Bool",
        "showPanelBadge": "Bool",
        "showQuoteBar": "Bool",
        "quoteIntervalMinutes": "Int",
        "quoteArchetype": "String",
        "quotePersonalFocus": "String",
        "quoteApiKey": "String",
        "cachedQuoteText": "String",
        "cachedQuoteAuthor": "String",
    }
    for name, typ in expected.items():
        if name not in entries:
            fail(f"main.xml missing config entry: {name}")
        elif entries[name] != typ:
            fail(f"main.xml entry {name}: type {entries[name]!r} != {typ!r}")

    if "baselineMode" in entries:
        fail("main.xml still declares removed baselineMode entry")

    # Defaults for horizon dates should be civil YYYY-MM-DD
    for name in ("targetTimestamp", "startTimestamp"):
        for el in root.iter():
            if el.tag.endswith("entry") and el.attrib.get("name") == name:
                default = None
                for child in el:
                    if child.tag.endswith("default") and child.text:
                        default = child.text.strip()
                if default and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", default):
                    fail(f"{name} default should be YYYY-MM-DD (got {default!r})")


def check_qml_font_double_assign() -> None:
    """font: wholeObject then font.subprop is illegal in QML."""
    qml_root = ROOT / "contents"
    pair_re = re.compile(r"^\s*font\s*:")
    sub_re = re.compile(r"^\s*font\.")
    for path in sorted(qml_root.rglob("*.qml")):
        lines = path.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines):
            if not pair_re.match(line):
                continue
            for j in range(i + 1, min(i + 8, len(lines))):
                nxt = lines[j]
                if not nxt.strip() or nxt.strip().startswith("//"):
                    continue
                if sub_re.match(nxt):
                    rel = path.relative_to(ROOT)
                    fail(
                        f"{rel}:{i + 1}: whole-font assign followed by "
                        f"font.* at line {j + 1} (QML rejects double assign)"
                    )
                break


def check_qml_action_priority() -> None:
    """PlasmaCore.Action.priority uses LowPriority/NormalPriority/HighPriority."""
    bad = re.compile(
        r"PlasmaCore\.Action\.(LowPriorityAction|NormalPriorityAction|"
        r"HighPriorityAction|DefaultPriorityAction)"
    )
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        text = path.read_text(encoding="utf-8")
        for i, line in enumerate(text.splitlines(), 1):
            if bad.search(line):
                rel = path.relative_to(ROOT)
                fail(
                    f"{rel}:{i}: invalid Action priority name "
                    f"(use LowPriority / NormalPriority / HighPriority)"
                )


def check_qml_object_literal_blocks() -> None:
    """
    Flag `readonly property var foo: ({` blocks that embed `var ` or `return `
    which QML rejects inside object literals.
    Heuristic: within 40 lines after `({` opening a property, before matching `})`.
    """
    prop_open = re.compile(
        r"readonly\s+property\s+var\s+\w+\s*:\s*\(\s*\{"
        r"|property\s+var\s+\w+\s*:\s*\(\s*\{"
    )
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        lines = path.read_text(encoding="utf-8").splitlines()
        i = 0
        while i < len(lines):
            if not prop_open.search(lines[i]):
                i += 1
                continue
            depth = 0
            started = False
            for j in range(i, min(i + 80, len(lines))):
                depth += lines[j].count("{") - lines[j].count("}")
                if "{" in lines[j]:
                    started = True
                if started and depth <= 0:
                    block = "\n".join(lines[i : j + 1])
                    if re.search(r"\bvar\s+\w+\s*=", block) or re.search(
                        r"\breturn\s+", block
                    ):
                        rel = path.relative_to(ROOT)
                        fail(
                            f"{rel}:{i + 1}: object-literal property binding "
                            f"contains var/return (lift to a normal property)"
                        )
                    break
            i += 1


def check_no_em_dash_in_ui_strings() -> None:
    """Keep user-facing QML free of U+2014 em dash (style + copy consistency)."""
    em = "\u2014"
    for path in sorted((ROOT / "contents").rglob("*.qml")):
        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if em in line:
                rel = path.relative_to(ROOT)
                fail(f"{rel}:{i}: em dash (U+2014) in QML; use comma or period")


def check_imports_and_ids() -> None:
    main = (ROOT / "contents/ui/main.qml").read_text(encoding="utf-8")
    if "PlasmoidItem" not in main:
        fail("main.qml must declare PlasmoidItem root")
    if "org.kde.plasma.plasmoid" not in main:
        fail("main.qml missing org.kde.plasma.plasmoid import")

    config = (ROOT / "contents/config/config.qml").read_text(encoding="utf-8")
    if "configGeneral.qml" not in config:
        fail("config.qml must point at configGeneral.qml")


def check_package_script() -> None:
    script = ROOT / "scripts/package.sh"
    if not script.is_file():
        fail("scripts/package.sh missing")
        return
    text = script.read_text(encoding="utf-8")
    if "metadata.json" not in text or "contents" not in text:
        fail("package.sh does not stage metadata.json + contents")
    if not script.stat().st_mode & 0o111:
        warn("scripts/package.sh is not executable (CI will chmod +x)")


def check_secrets_leak() -> None:
    patterns = [
        re.compile(r"AKIA[0-9A-Z]{16}"),
        re.compile(r"ghp_[A-Za-z0-9]{20,}"),
        re.compile(r"gho_[A-Za-z0-9]{20,}"),
        re.compile(r"-----BEGIN (RSA |OPENSSH )?PRIVATE KEY-----"),
    ]
    skip_dirs = {".git", "node_modules", ".venv", "venv"}
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in skip_dirs for part in path.parts):
            continue
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".zip", ".plasmoid", ".svg"}:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for pat in patterns:
            if pat.search(text):
                fail(f"possible secret material in {path.relative_to(ROOT)}")


def check_readme_version_mention(meta: dict | None) -> None:
    if not meta:
        return
    version = meta["KPlugin"]["Version"]
    readme = ROOT / "README.md"
    if not readme.is_file():
        fail("README.md missing")
        return
    text = readme.read_text(encoding="utf-8")
    if version not in text:
        warn(f"README.md does not mention version {version}")


def main() -> int:
    print(f"ci-check: root={ROOT}")
    check_required_paths()
    meta = check_metadata()
    check_main_xml()
    check_qml_font_double_assign()
    check_qml_action_priority()
    check_qml_object_literal_blocks()
    check_no_em_dash_in_ui_strings()
    check_imports_and_ids()
    check_package_script()
    check_secrets_leak()
    check_readme_version_mention(meta)

    for w in warnings:
        print(f"WARNING: {w}")
    if errors:
        print(f"\nFAILED ({len(errors)} error(s)):")
        for e in errors:
            print(f"  - {e}")
        return 1

    print(f"OK ({len(warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
