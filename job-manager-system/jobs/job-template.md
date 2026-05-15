---
name: my-job
description: Description of what this job does
project_folder: ~/repos/personal-infra
schedule: hourly
enabled: false
branch: dev
tags: []
model: opencode/glm-5.1
agent: cron-manager
---

# Description

Brief description of the task.

## Instructions

Detailed instructions for opencode to execute:

Project execution directory: `project_folder` from frontmatter.

1. Step one
2. Step two
3. Step three

## Commands

Alternatively, define shell commands to execute directly (no AI cost).
**If this section exists, it runs instead of the AI prompt above.**

```bash
#!/bin/bash
echo "Hello from cron!"
```
