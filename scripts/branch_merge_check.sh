#!/usr/bin/env bash
set -euo pipefail

# Cenário padrão deste repositório:
# o código atual representa a main.
# Por isso, sem argumento, a base é a branch atual.
# Uso:
#   scripts/branch_merge_check.sh            # usa branch atual (main deste ambiente)
#   scripts/branch_merge_check.sh main       # usa branch chamada main (se existir)
#   scripts/branch_merge_check.sh <base>

base_branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

if ! git rev-parse --verify "$base_branch" >/dev/null 2>&1; then
  echo "❌ Base '$base_branch' não existe localmente."
  echo ""
  echo "Branches locais disponíveis:"
  git for-each-ref --format='  - %(refname:short)' refs/heads
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
echo "Base de comparação: $base_branch"
echo "Branch atual: $current_branch"
echo ""

branches=$(git for-each-ref --format='%(refname:short)' refs/heads)

if [[ "$(printf '%s\n' "$branches" | wc -l | tr -d ' ')" -le 1 ]]; then
  echo "Só existe 1 branch local no momento."
  echo "Nada para comparar/mesclar agora."
  exit 0
fi

for branch in $branches; do
  if [[ "$branch" == "$base_branch" ]]; then
    continue
  fi

  echo "========== $branch -> $base_branch =========="

  ahead_count=$(git rev-list --count "$base_branch..$branch")
  behind_count=$(git rev-list --count "$branch..$base_branch")
  echo "Ahead/Behind: +$ahead_count / -$behind_count"

  echo "Commits que entrariam no merge:"
  if [[ "$ahead_count" -eq 0 ]]; then
    echo "  (nenhum commit exclusivo)"
  else
    git log --oneline "$base_branch..$branch" | sed 's/^/  - /'
  fi

  if git merge-tree "$(git merge-base "$base_branch" "$branch")" "$base_branch" "$branch" | rg -q '^<<<<<<< '; then
    echo "Conflito textual provável: SIM"
  else
    echo "Conflito textual provável: NÃO"
  fi

  echo ""
done
