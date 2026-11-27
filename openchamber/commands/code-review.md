---
description: Run a code review based on a open pull request.
subagent: false
---

Code review on open Pull Requests:
- Use github 'dipievilbot' account.
- Get the oldest open PR on GitHub without your comments (with "Reviewed by OpenCode" in body comment) or any 'chatgpt-codex-connector' comment;
- If no PR is foud, stop immediatelly;
- Check if related task on Board is on 'Review' list. If not, skip it;
- Do the code review on changes related to the PR changes;
- Add inline diff in case of simple changes suggestions;
- In case of any issue or inconsistence found, create a comment for each one using the pattern:

```markdown
# ⚠️Automated code review

**{collor bullet priority level} - {title problem found}**

{Describe the detailed problem found}

**Solution:**
{Describe the possible solution or code change suggestion}

🤖 Reviewed by OpenCode
```
- In case no problem or issue found, create a comment with following content:

```
No issues found.

🤖 Reviewed by OpenCode
```

- For any issues not related to the scope, create a card on `Backlog` with a proper tilte and short description along with the prhase `Issue found during code review of PR {PR Number and link}. Need refinement.`;
- After finished the task, warn me on Telegram with following pattern:

```
Code review done! 

Pull Request #{pull request id} for project `{project-name}`. 

Check on {pull-request-url}.
```