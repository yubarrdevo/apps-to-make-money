#!/bin/bash
cd /home/yuri/apps-to-make-money || exit 1
git add -A
if ! git diff --cached --quiet; then
  MSG="chore: auto-sync $(date '+%Y-%m-%d %H:%M SP')"
  git commit -m "$MSG" \
    --author="Automation <automation@ativadata.com>"
  git push origin main
  echo "$(date): pushed - $MSG" >> /tmp/git-autopush.log
fi
