"""GitHub access for the project scripts, through the gh CLI.

The token comes from GH_TOKEN or, when that is unset, from ../secrets/github.txt next to the
repository (HANDOFF.md, working rules). It is passed to gh through the environment only and is
never printed or written anywhere.
"""

import json
import os
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OWNER = "iglooo101"
REPO_NAME = "checkers"
PROJECT_NUMBER = 1
TOKEN_FILE = REPO_ROOT.parent / "secrets" / "github.txt"


def _gh_binary():
    return os.environ.get("GH_BIN") or shutil.which("gh") or str(Path.home() / ".local/bin/gh")


def _environment():
    env = dict(os.environ)
    if not env.get("GH_TOKEN") and TOKEN_FILE.exists():
        env["GH_TOKEN"] = TOKEN_FILE.read_text().strip()
    return env


def gh(*args):
    """Runs gh with the given arguments and returns its JSON output, or None when empty."""
    result = subprocess.run([_gh_binary(), *args], capture_output=True, text=True,
                            env=_environment())
    if result.returncode != 0:
        raise SystemExit(f"gh {' '.join(args[:2])} failed: {result.stderr.strip()}")
    return json.loads(result.stdout) if result.stdout.strip() else None


def graphql(query):
    return gh("api", "graphql", "-f", f"query={query}")["data"]


def issues(numbers, fields):
    """Fetches the given GraphQL fields for many issues, in batches, keyed by issue number."""
    found = {}
    numbers = list(dict.fromkeys(numbers))
    for start in range(0, len(numbers), 40):
        batch = numbers[start:start + 40]
        aliases = " ".join(f"i{n}: issue(number: {n}) {{ number {fields} }}" for n in batch)
        data = graphql(f'query {{ repository(owner: "{OWNER}", name: "{REPO_NAME}") '
                       f'{{ {aliases} }} }}')["repository"]
        for n in batch:
            found[n] = data[f"i{n}"]
    return found


def project():
    """Returns the project ID and its Status field with option IDs."""
    data = graphql(f'query {{ user(login: "{OWNER}") {{ projectV2(number: {PROJECT_NUMBER}) {{ id '
                   'field(name: "Status") { ... on ProjectV2SingleSelectField '
                   '{ id options { id name } } } } } }')
    return data["user"]["projectV2"]


def board_items():
    """Returns the board's issue items keyed by issue number (status, level, epic, size...)."""
    listing = gh("project", "item-list", str(PROJECT_NUMBER), "--owner", OWNER,
                 "--limit", "1000", "--format", "json")
    return {item["content"]["number"]: item for item in listing["items"] if item.get("level")}
