# Git Auto-Backup Script

Never lose uncommitted work again! A lightweight Bash script that automatically commits and pushes changes across multiple Git repositories.

Perfect for developers who juggle multiple projects and want peace of mind knowing their work is always backed up.

## Why Use This?

We've all been there:
- Working late on a project and forgetting to commit
- Switching between multiple repositories throughout the day
- Losing work due to system crashes or accidental deletions
- Wanting automated backups without complex CI/CD setup

This script runs quietly in the background (via cron) and ensures your work is always committed and pushed.

## Features

- **Smart Detection**: Finds changes in modified, staged, and untracked files
- **Auto-Commits**: Creates timestamped commits automatically  
- **Auto-Push**: Pushes to origin when available (graceful fallback if no remote)
- **Detailed Logging**: Beautiful logs with emojis and clear status messages
- **Log Rotation**: Keeps logs for 7 days, then archives automatically
- **Security**: Whitelist system - only processes approved repositories
- **Cron-Ready**: Designed for scheduled execution with proper exit codes
- **Nested Search**: Finds repositories in subdirectories if needed

## Real-World Example

```bash
2025-01-15 23:45:15 - === Processing: my-website ===
2025-01-15 23:45:16 - ✓ my-website: Commit created
2025-01-15 23:45:18 - ✓ my-website: Push successful
2025-01-15 23:45:18 - === Processing: api-server ===
2025-01-15 23:45:19 - ✓ api-server: No changes
```

Your work from today is now safely backed up on GitHub! 🎉

## Requirements

- **Linux/Unix**: Tested on Debian/Ubuntu (should work on most distros)
- **Git**: Installed and configured with your credentials
- **Bash**: Version 4.0+ recommended

## Installation

```bash
# Download the script
curl -O https://raw.githubusercontent.com/yourusername/git-auto-backup/main/git-auto.sh

# Make executable
chmod +x git-auto.sh

# Test it works
./git-auto.sh
```

## Configuration

### Basic Setup

Edit these variables at the top of the script:

```bash
BASE_DIR="$HOME/Projects"                    # Where your repos live
LOG="$HOME/Scripts/git-auto.log"            # Log file location  
ALLOWED_REPOS=(${ALLOWED_REPOS:-"repo1 repo2"})  # Which repos to process
```

### Environment Variable Override

No need to edit the script - use environment variables:

```bash
# Process specific projects
ALLOWED_REPOS="website api mobile-app" ./git-auto.sh

# Use different base directory
BASE_DIR="$HOME/Code" ./git-auto.sh

# Custom log location
LOG="/var/log/git-backup.log" ./git-auto.sh
```

### Directory Structure

```
$HOME/Projects/
├── website/           # ✓ Will be processed (if in ALLOWED_REPOS)
├── api-server/        # ✓ Will be processed (if in ALLOWED_REPOS)
├── old-project/       # ✗ Ignored (not in whitelist)
└── docs/
    └── my-notes/      # ✓ Found by nested search if needed
```

## Usage

### Manual Run
```bash
./git-auto.sh
```

### Automated with Cron

The magic happens when you schedule it:

```bash
# Edit crontab
crontab -e

# Run every 2 hours during work day (9 AM - 6 PM)
0 9,11,13,15,17 * * 1-5 /path/to/git-auto.sh

# Or run every night at midnight
0 0 * * * /path/to/git-auto.sh

# For debugging, redirect output
0 0 * * * /path/to/git-auto.sh >> /tmp/cron-debug.log 2>&1
```

**Pro tip**: Start with hourly runs during development, then reduce frequency once you trust it.

## What It Does Step-by-Step

1. **Scans** your `BASE_DIR` for repositories
2. **Checks** if each repo is in your `ALLOWED_REPOS` whitelist
3. **Detects** any changes (modified, staged, or untracked files)
4. **Stages** all changes with `git add .`
5. **Commits** with timestamp: `Auto-backup: 2025-01-15 23:45:15`
6. **Pushes** to origin (if configured)
7. **Logs** everything with clear status indicators

## Log Output Examples

```bash
# Successful backup
✓ website: Commit created
✓ website: Push successful

# No changes needed  
✓ api-server: No changes

# Repo without remote
✓ local-project: Commit OK, no remote configured

# Push failed (network issue)
⚠ mobile-app: Commit OK, but push failed

# Repository not in whitelist
SKIP: old-project is not in the allowed list
```

## Troubleshooting

### "Repository not processed"
- Check that the folder name is in `ALLOWED_REPOS` array
- Verify it's actually a Git repository (`ls -la` should show `.git/`)

### "Push failed" warnings
- **Common cause**: Network issues or authentication problems
- **Good news**: Your work is still committed locally!
- **Fix**: Check your SSH keys or Git credentials
- **Test**: Try `git push` manually in that repository

### "No repositories found"
- Check that `BASE_DIR` exists and contains Git repositories
- The script will search subdirectories automatically
- Verify permissions on the directories

### Cron not working
```bash
# Check if cron is running
systemctl status cron

# View cron logs
grep CRON /var/log/syslog

# Test with full paths in crontab
0 0 * * * /usr/bin/bash /full/path/to/git-auto.sh

# Check environment variables are available
0 0 * * * cd /home/user && ./git-auto.sh
```

## Security & Safety

- ✅ **Read-only on existing repos**: Never creates or deletes repositories
- ✅ **Uses existing credentials**: Leverages your configured SSH keys/tokens  
- ✅ **Whitelist protection**: Only touches approved repositories
- ✅ **Local commits first**: Always commits locally, even if push fails
- ✅ **No sensitive data**: Logs only contain timestamps and repo names

## Advanced Configuration

### Multiple Base Directories
```bash
# Create a wrapper script
#!/bin/bash
BASE_DIR="$HOME/Work" ALLOWED_REPOS="project1 project2" ./git-auto.sh
BASE_DIR="$HOME/Personal" ALLOWED_REPOS="blog dotfiles" ./git-auto.sh
```

### Different Commit Messages
Edit the script to customize the commit message format:
```bash
# Current format: "Auto-backup: 2025-01-15 23:45:15"
# You could change to:
local COMMIT_MSG="🤖 Daily backup $(date '+%Y-%m-%d %H:%M')"
```

### Email Notifications
The script has an `EMAIL` variable ready for future notifications:
```bash
# Add this function and call it when errors occur
send_notification() {
    if [ -n "$EMAIL" ]; then
        echo "Git backup completed with $ERRORS errors" | mail -s "Git Backup Report" "$EMAIL"
    fi
}
```

## Exit Codes

- **0**: All good! No errors occurred
- **1**: Some repositories had issues (check the logs)

Perfect for monitoring tools or additional automation.

## Contributing

Found a bug or have an improvement? 

1. Fork this repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Test thoroughly with your repositories
4. Submit a pull request

## License

MIT License - Use it, modify it, share it!

---

**Note**: This is designed for development/personal projects. For production code, use proper CI/CD pipelines with code review processes.
