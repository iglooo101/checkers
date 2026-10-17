#!/usr/bin/env python3
"""Regenerates the data-driven sections of EXECUTION_PLAN.md from the project board.

Only the text between <!-- BEGIN GENERATED: name --> and <!-- END GENERATED: name --> changes
(sections: progress, in-progress, backlog), plus the date on the "Last updated" line. Everything
else in the file is hand-written and kept: next up, order, risks, change log.

Usage: scripts/project/update_plan.py [--check]
  --check  exit 1 if the generated sections are out of date, without writing the file.
"""

import datetime
import re
import sys

from gh_client import REPO_ROOT, board_items, issues

PLAN = REPO_ROOT / "EXECUTION_PLAN.md"
# Execution order of the epics; keep in step with "Order and dependencies" in EXECUTION_PLAN.md.
EPIC_ORDER = [1, 29, 57, 153, 95, 114, 132, 169]
CHECKBOX = {"Todo": " ", "In Progress": "~", "Done": "x"}


def replace_generated(text, name, body):
    """Replaces the body of one generated section, keeping its markers and everything else."""
    begin = f"<!-- BEGIN GENERATED: {name} -->"
    end = f"<!-- END GENERATED: {name} -->"
    start, stop = text.find(begin), text.find(end)
    if start < 0 or stop < start:
        raise ValueError(f"EXECUTION_PLAN.md has no generated section '{name}'")
    return text[:start + len(begin)] + "\n" + body.strip("\n") + "\n" + text[stop:]


def collect():
    items = board_items()
    epics = issues(EPIC_ORDER, "title milestone { title } subIssues(first: 50) { nodes { number } }")
    feature_numbers = [n["number"] for e in epics.values() for n in e["subIssues"]["nodes"]]
    features = issues(feature_numbers, "title body subIssues(first: 50) { nodes { number } }")
    task_numbers = [n["number"] for f in features.values() for n in f["subIssues"]["nodes"]]
    tasks = issues(task_numbers, "blockedBy(first: 20) { nodes { number } }")
    return items, epics, features, tasks


def render(items, epics, features, tasks):
    status = lambda n: items[n].get("status") or "Todo"  # noqa: E731
    done = lambda n: status(n) == "Done"  # noqa: E731
    title = lambda n: items[n]["content"]["title"]  # noqa: E731
    heading = lambda n: title(n).replace(":", "", 1)  # noqa: E731

    def requirements(feature):
        match = re.search(r"\*\*Requirements:\*\* (.+?) \(see", feature["body"] or "")
        return match[1] if match else ""

    tree = []
    for e in EPIC_ORDER:
        feats = []
        for node in epics[e]["subIssues"]["nodes"]:
            f = node["number"]
            ts = [(t["number"], sorted(b["number"] for b in tasks[t["number"]]["blockedBy"]["nodes"]
                                       if items.get(b["number"], {}).get("level") == "Task"))
                  for t in features[f]["subIssues"]["nodes"]]
            feats.append((f, ts))
        tree.append((e, feats))

    rows = ["| Order | Epic | Issue | Milestone | Priority | Features done | Tasks done | Status |",
            "|---|---|---|---|---|---|---|---|"]
    totals = [0, 0, 0, 0]
    for order, (e, feats) in enumerate(tree, 1):
        task_list = [t for _, ts in feats for t, _ in ts]
        fd, td = sum(done(f) for f, _ in feats), sum(done(t) for t in task_list)
        totals = [totals[0] + fd, totals[1] + len(feats), totals[2] + td, totals[3] + len(task_list)]
        rows.append(f"| {order} | {heading(e)} | #{e} | {epics[e]['milestone']['title']} | "
                    f"{items[e]['priority']} | {fd}/{len(feats)} | {td}/{len(task_list)} | "
                    f"{status(e)} |")
    rows.append(f"| | **Total** | | | | **{totals[0]}/{totals[1]}** | **{totals[2]}/{totals[3]}** | |")

    in_progress = sorted(n for n in items if status(n) == "In Progress")
    progress_list = "\n".join(f"- #{n} {title(n)}" for n in in_progress) or "Nothing in progress."

    backlog = []
    for e, feats in tree:
        task_list = [t for _, ts in feats for t, _ in ts]
        backlog += [f"### {heading(e)} (#{e}) · {epics[e]['milestone']['title']} · "
                    f"{items[e]['priority']} · {sum(done(t) for t in task_list)}/{len(task_list)} "
                    "tasks", ""]
        for f, ts in feats:
            refs = requirements(features[f])
            backlog += [f"**{heading(f)}** (#{f}){' · ' + refs if refs else ''}", ""]
            for t, blockers in ts:
                after = f" · after {', '.join(f'#{b}' for b in blockers)}" if blockers else ""
                backlog.append(f"- [{CHECKBOX[status(t)]}] #{t} {title(t)} · "
                               f"{items[t].get('size', '-')}{after}")
            backlog.append("")
    summary = (f"features {totals[0]}/{totals[1]}, tasks {totals[2]}/{totals[3]}, "
               f"in progress {len(in_progress)}")
    return {"progress": "\n".join(rows), "in-progress": progress_list,
            "backlog": "\n".join(backlog)}, summary


def main():
    check = "--check" in sys.argv[1:]
    text = PLAN.read_text()
    sections, summary = render(*collect())
    updated = text
    for name, body in sections.items():
        updated = replace_generated(updated, name, body)

    if check:
        if updated != text:
            raise SystemExit(f"EXECUTION_PLAN.md is out of date ({summary}); run update_plan.py")
        print(f"EXECUTION_PLAN.md is up to date ({summary})")
        return

    today = datetime.date.today().isoformat()
    updated = re.sub(r"^Last updated: \d{4}-\d{2}-\d{2}", f"Last updated: {today}", updated,
                     count=1, flags=re.M)
    PLAN.write_text(updated)
    print(f"EXECUTION_PLAN.md updated ({summary})")


if __name__ == "__main__":
    main()
