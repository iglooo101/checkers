#!/usr/bin/env python3
"""Moves issues on the project board and confirms the new status.

Usage: scripts/project/board_move.py <Todo | "In Progress" | Done> <issue> [<issue> ...]

Working rule: move an item to In Progress before starting it and to Done when it is complete
(close the issue too), then mirror the change in EXECUTION_PLAN.md (scripts/project/update_plan.py).
"""

import sys

from gh_client import OWNER, PROJECT_NUMBER, REPO_NAME, graphql, project


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    status, numbers = sys.argv[1], [int(n.lstrip("#")) for n in sys.argv[2:]]
    board = project()
    options = {o["name"]: o["id"] for o in board["field"]["options"]}
    if status not in options:
        raise SystemExit(f"Unknown status {status!r}; use one of {', '.join(options)}")

    for number in numbers:
        issue = graphql(f'query {{ repository(owner: "{OWNER}", name: "{REPO_NAME}") {{ '
                        f'issue(number: {number}) {{ title projectItems(first: 10) '
                        '{ nodes { id project { number } } } } } }')["repository"]["issue"]
        item = next((i["id"] for i in issue["projectItems"]["nodes"]
                     if i["project"]["number"] == PROJECT_NUMBER), None)
        if item is None:
            raise SystemExit(f"#{number} is not on the board")
        graphql(f'mutation {{ updateProjectV2ItemFieldValue(input: {{ projectId: "{board["id"]}", '
                f'itemId: "{item}", fieldId: "{board["field"]["id"]}", value: '
                f'{{ singleSelectOptionId: "{options[status]}" }} }}) {{ projectV2Item {{ id }} }} }}')
        check = graphql(f'query {{ node(id: "{item}") {{ ... on ProjectV2Item {{ '
                        'fieldValueByName(name: "Status") { '
                        '... on ProjectV2ItemFieldSingleSelectValue { name } } } } }')
        print(f"#{number} {issue['title']} -> {check['node']['fieldValueByName']['name']}")


if __name__ == "__main__":
    main()
