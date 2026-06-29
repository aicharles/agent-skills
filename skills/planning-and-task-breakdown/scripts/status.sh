#!/usr/bin/env bash
# status.sh — route the planning-and-task-breakdown skill without polluting context.
#
# Reads a Linear project (or one issue) via the GraphQL API and prints compact
# JSON: the project status plus its parent issues as {id, identifier, title,
# status, blockedBy}. No descriptions, no comments — just enough to route and
# pick the next parent. Requires LINEAR_API_KEY in the environment.
#
# Usage:
#   status.sh project <project-id-or-slug>   # project status + parent issues
#   status.sh issue   <issue-identifier>     # one issue's status + blockers
#
# A "parent" here is a top-level issue in the project (no parent of its own).
# Sub-issues are excluded — this is the slice view, not the full tree.

set -euo pipefail

API="https://api.linear.app/graphql"
[ -n "${LINEAR_API_KEY:-}" ] || { echo '{"error":"LINEAR_API_KEY not set"}'; exit 1; }

gql() {
  curl -fsS "$API" \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$1"
}

mode="${1:-}"
arg="${2:-}"
[ -n "$mode" ] && [ -n "$arg" ] || { echo '{"error":"usage: status.sh project|issue <id>"}'; exit 1; }

case "$mode" in
  project)
    # Page through top-level issues in batches. The nested relation data trips
    # Linear's query-complexity limit above ~50 issues per page, so we page.
    after="null"
    name="" pstate="" pid=""
    parents="[]"
    while :; do
      q=$(jq -n --arg id "$arg" --argjson after "$after" '{
        query: "query($id:String!,$after:String){ project(id:$id){ id name state issues(first:50,after:$after,filter:{parent:{null:true}}){ pageInfo{ hasNextPage endCursor } nodes{ id identifier title state{name type} inverseRelations{ nodes{ type issue{ identifier } } } } } } }",
        variables: { id: $id, after: $after }
      }')
      page=$(gql "$q")
      err=$(jq -r '.errors[0].message // empty' <<<"$page")
      [ -z "$err" ] || { jq -nc --arg e "$err" '{error:$e}'; exit 1; }
      pid=$(jq -r '.data.project.id' <<<"$page")
      name=$(jq -r '.data.project.name' <<<"$page")
      pstate=$(jq -r '.data.project.state' <<<"$page")
      batch=$(jq -c '[ .data.project.issues.nodes[] | {
        id, identifier, title,
        status: .state.name,
        statusType: .state.type,
        blockedBy: [ .inverseRelations.nodes[] | select(.type=="blocks") | .issue.identifier ]
      } ]' <<<"$page")
      parents=$(jq -nc --argjson a "$parents" --argjson b "$batch" '$a + $b')
      [ "$(jq -r '.data.project.issues.pageInfo.hasNextPage' <<<"$page")" = "true" ] || break
      after=$(jq -c '.data.project.issues.pageInfo.endCursor' <<<"$page")
    done
    jq -nc --arg id "$pid" --arg name "$name" --arg status "$pstate" --argjson parents "$parents" \
      '{ project: { id:$id, name:$name, status:$status }, parents:$parents }'
    ;;
  issue)
    q=$(jq -n --arg id "$arg" '{
      query: "query($id:String!){ issue(id:$id){ id identifier title state{name type} parent{ identifier } inverseRelations{ nodes{ type issue{ identifier } } } children{ nodes{ identifier title state{name} } } } }",
      variables: { id: $id }
    }')
    gql "$q" | jq -c '
      .data.issue as $i
      | {
          id: $i.id,
          identifier: $i.identifier,
          title: $i.title,
          status: $i.state.name,
          statusType: $i.state.type,
          parent: ($i.parent.identifier // null),
          blockedBy: [ $i.inverseRelations.nodes[] | select(.type=="blocks") | .issue.identifier ],
          children: [ $i.children.nodes[] | { identifier, title, status: .state.name } ]
        }'
    ;;
  *)
    echo '{"error":"usage: status.sh project|issue <id>"}'; exit 1 ;;
esac
