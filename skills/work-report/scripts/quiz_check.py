#!/usr/bin/env python3
"""Mechanical readability check for work-report deliverables.

Usage: python3 quiz_check.py <path> [<path> ...]
  *.html — pre-merge quiz: checks the 변경 요약 block and every QUESTIONS entry
  *      — report markdown: checks the '### 요약' section

Enforces the countable subset of the readability standard:
  - every sentence has at most 25 어절 (whitespace-separated words)
  - every quiz option has at most 40 characters

Prints violations and exits 1; exits 0 when clean.
"""
import re
import sys

MAX_EOJEOL = 25
MAX_OPTION_CHARS = 40

# ponytail: regex over the template's fixed QUESTIONS shape and a rough
# [.?!]+space sentence split; a real JS/Korean parser only if the template
# shape changes or quoted-sentence merging becomes a recurring miss.


def sentences(text):
    for s in re.split(r"(?<=[.?!])\s+", text.strip()):
        s = s.strip()
        if s:
            yield s


def eojeol_count(sentence):
    return len([t for t in sentence.split() if any(c.isalnum() for c in t)])


def unescape_js(s):
    return s.replace('\\"', '"').replace("\\\\", "\\")


def check_prose(text, where, violations):
    for s in sentences(text):
        n = eojeol_count(s)
        if n > MAX_EOJEOL:
            violations.append(f'{where}: sentence has {n} 어절 (max {MAX_EOJEOL}): "{s}"')


def check_html(src, violations):
    m = re.search(r'<div class="summary">(.*?)</div>', src, re.S)
    if m:
        text = re.sub(r"<!--.*?-->", " ", m.group(1), flags=re.S)
        text = re.sub(r"<[^>]+>", " ", text)
        check_prose(re.sub(r"\s+", " ", text), "변경 요약", violations)
    else:
        violations.append('summary block (<div class="summary">) not found')
    m = re.search(r"const QUESTIONS = \[(.*?)\];", src, re.S)
    if not m:
        violations.append("QUESTIONS array not found")
        return
    body = m.group(1)
    for i, q in enumerate(re.finditer(r'\bq\s*:\s*"((?:[^"\\]|\\.)*)"', body), 1):
        check_prose(unescape_js(q.group(1)), f"Q{i} question", violations)
    for i, opts in enumerate(re.finditer(r"\boptions\s*:\s*\[(.*?)\]", body, re.S), 1):
        for o in re.finditer(r'"((?:[^"\\]|\\.)*)"', opts.group(1)):
            text = unescape_js(o.group(1))
            if len(text) > MAX_OPTION_CHARS:
                violations.append(
                    f'Q{i} option has {len(text)} chars (max {MAX_OPTION_CHARS}): "{text}"'
                )
    for i, ex in enumerate(re.finditer(r'\bexplain\s*:\s*"((?:[^"\\]|\\.)*)"', body), 1):
        check_prose(unescape_js(ex.group(1)), f"Q{i} explain", violations)


def check_md(src, violations):
    m = re.search(r"^### 요약\s*$(.*?)(?=^#{1,6} |\Z)", src, re.S | re.M)
    if not m:
        violations.append("'### 요약' section not found")
        return
    check_prose(re.sub(r"\s+", " ", m.group(1)), "요약", violations)


def main(argv):
    if not argv:
        print("usage: quiz_check.py <quiz.html|report.md> [...]", file=sys.stderr)
        return 2
    violations = []
    for path in argv:
        with open(path, encoding="utf-8") as f:
            src = f.read()
        found = []
        if path.endswith(".html"):
            check_html(src, found)
        else:
            check_md(src, found)
        violations.extend(f"{path}: {v}" for v in found)
    if violations:
        for v in violations:
            print(v)
        print(f"{len(violations)} violation(s)")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
