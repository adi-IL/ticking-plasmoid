#!/usr/bin/env python3
"""
Extracts gettext message strings from QML files into a standard PO template (.pot).
"""
import os
import re
import datetime

OUTPUT_POT = "po/plasma_applet_org.adi_il.ticking.pot"

def main():
    entries = {}
    
    qml_files = []
    for root, _, files in os.walk("contents/ui"):
        for f in sorted(files):
            if f.endswith(".qml"):
                qml_files.append(os.path.join(root, f))
    qml_files.sort()

    for p in qml_files:
        with open(p, "r", encoding="utf-8") as fp:
            for idx, line in enumerate(fp, 1):
                for m in re.finditer(r'i18ncp\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"', line):
                    ctx, sing, plur = m.group(1), m.group(2), m.group(3)
                    key = (ctx, sing, plur)
                    if key not in entries:
                        entries[key] = []
                    entries[key].append((p, idx))
                for m in re.finditer(r'(?<!i18ncp\()i18np\(\s*"([^"]+)"\s*,\s*"([^"]+)"', line):
                    sing, plur = m.group(1), m.group(2)
                    key = (None, sing, plur)
                    if key not in entries:
                        entries[key] = []
                    entries[key].append((p, idx))
                for m in re.finditer(r'(?<!i18ncp\()i18nc\(\s*"([^"]+)"\s*,\s*"([^"]+)"', line):
                    ctx, msg = m.group(1), m.group(2)
                    key = (ctx, msg, None)
                    if key not in entries:
                        entries[key] = []
                    entries[key].append((p, idx))
                for m in re.finditer(r'(?<!i18nc\()(?<!i18ncp\()(?<!i18np\()i18n\(\s*"([^"]+)"', line):
                    msg = m.group(1)
                    key = (None, msg, None)
                    if key not in entries:
                        entries[key] = []
                    entries[key].append((p, idx))

    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M+0000")
    header = f"""# Translation template for Ticking Plasma 6 widget.
# Copyright (C) {datetime.datetime.now().year} Aditya Gaurav
# This file is distributed under the same license as the org.adi_il.ticking package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: org.adi_il.ticking 1.3.0\\n"
"Report-Msgid-Bugs-To: https://github.com/adi-IL/ticking-plasmoid/issues\\n"
"POT-Creation-Date: {now}\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <kde-i18n-doc@kde.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\\n"

"""

    with open(OUTPUT_POT, "w", encoding="utf-8") as out:
        out.write(header)
        for (ctx, msg, plur), locs in sorted(entries.items(), key=lambda x: (x[1][0][0], x[1][0][1])):
            for p, line_no in locs:
                out.write(f"#: {p}:{line_no}\n")
            if ctx:
                out.write(f'msgctxt "{ctx}"\n')
            out.write(f'msgid "{msg}"\n')
            if plur:
                out.write(f'msgid_plural "{plur}"\n')
                out.write('msgstr[0] ""\n')
                out.write('msgstr[1] ""\n\n')
            else:
                out.write('msgstr ""\n\n')

    print(f"Generated {OUTPUT_POT} with {len(entries)} unique strings.")

if __name__ == "__main__":
    main()
