#!/usr/bin/env bash
# US4 FR-018: the store texts fit App Store Connect (specs/008-release-1-0/contracts/store-listing.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$SCRIPTS/tests/listing-fixtures"
LISTING="$SCRIPTS/../release/store-listing.md"
failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

# Checks a listing file: one "## <Field>" heading per field of the contract, its text below,
# HTML comments not counted. Prints one line per problem, each starting with its field, and
# exits 1 if there is any.
check_listing() {
  python3 -I - "$1" <<'EOF'
import re
import sys

FIELDS = [
    "Name", "Subtitle", "Promotional text", "Description", "Keywords", "Support URL",
    "Privacy policy URL", "Category", "Age rating", "Price and availability", "Copyright",
    "App Review notes", "Privacy label", "What to Test", "Version",
]
OPTIONAL = {"Promotional text"}
CHARACTERS = {"Subtitle": 30, "Promotional text": 170, "Description": 4000, "What to Test": 4000}
BYTES = {"Keywords": 100, "App Review notes": 4000}
URLS = {"Support URL", "Privacy policy URL"}

try:
    source = open(sys.argv[1], encoding="utf-8").read()
except OSError as error:
    print(f"listing: cannot read {sys.argv[1]}: {error.strerror}")
    sys.exit(1)

problems = []
sections = {}
current = None
for line in re.sub(r"<!--.*?-->", "", source, flags=re.S).split("\n"):
    heading = re.match(r"## (.+?)\s*$", line)
    if heading:
        current = heading.group(1)
        if current in sections:
            problems.append(f"{current}: appears twice")
        sections[current] = []
    elif current is not None:
        sections[current].append(line.rstrip())

# A field's text as it is pasted: lines joined, blank runs left by comments collapsed.
texts = {
    field: re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip("\n")
    for field, lines in sections.items()
}

for field in texts:
    if field not in FIELDS:
        problems.append(f"{field}: not a field of the contract")
for field in FIELDS:
    if field not in texts:
        problems.append(f"{field}: missing")
    elif not texts[field] and field not in OPTIONAL:
        problems.append(f"{field}: empty")

name = texts.get("Name")
if name is not None and not 2 <= len(name) <= 30:
    problems.append(f"Name: {len(name)} characters, not 2 to 30")
for field, limit in CHARACTERS.items():
    if field in texts and len(texts[field]) > limit:
        problems.append(f"{field}: {len(texts[field])} characters, more than {limit}")
for field, limit in BYTES.items():
    size = len(texts.get(field, "").encode("utf-8"))
    if size > limit:
        problems.append(f"{field}: {size} bytes, more than {limit}")
if texts.get("Keywords"):
    for keyword in texts["Keywords"].split(","):
        if len(keyword.strip()) <= 2:
            problems.append(f"Keywords: \"{keyword.strip()}\" has two characters or fewer")
for field in URLS:
    url = texts.get(field)
    if url and not re.fullmatch(r"https://\S+", url):
        problems.append(f"{field}: \"{url}\" is not a full https:// URL")

for problem in problems:
    print(problem)
sys.exit(1 if problems else 0)
EOF
}

# Expects the check to fail on a fixture and to name the field.
expect_failure() {
  local fixture="$1" field="$2" output
  if output="$(check_listing "$FIXTURES/$fixture")"; then
    fail "$fixture should fail the check"
  elif [[ "$output" != *"$field:"* ]]; then
    fail "the failure for $fixture should name $field; it printed: $output"
  fi
}

if ! output="$(check_listing "$FIXTURES/good.md")"; then
  fail "good.md should pass the check; it printed: $output"
fi
expect_failure long-name.md "Name"
expect_failure long-keywords.md "Keywords"
expect_failure short-keyword.md "Keywords"
expect_failure missing-subtitle.md "Subtitle"
expect_failure http-url.md "Support URL"

if ! output="$(check_listing "$LISTING")"; then
  fail "release/store-listing.md should pass the check; it printed: $output"
fi

exit $((failures > 0))
