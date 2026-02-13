# AGENTS.md


# Agent and AI information

## MANDATORY FIRST STEPS - DO THIS IMMEDIATELY

🚨 **CRITICAL: YOU MUST DO THIS AT THE START OF EVERY CHAT SESSION** 🚨

DO NOT skip these steps. DO NOT treat them as optional. DO NOT proceed with any
task until you have completed ALL of these commands in order:


### Step 1: REQUIRED

```bash
mulle-bashfunctions flags
mulle-bashfunctions toc
```

### Step 3: REQUIRED - List available commands

```bash
mulle-sde commands
```


## MANDATORY BEFORE WRITING ANY CODE

🚨 **YOU MUST RUN THIS COMMAND BEFORE WRITING OR MODIFYING ANY CODE** 🚨

```bash
value="$(mulle-sde env get PROJECT_DIALECT)"
value="${value:-$(mulle-sde env get PROJECT_LANGUAGE)}"
mulle-sde howto show --keyword styleguide --keyword "${value}"
```

This gets the style information for the project. It is NOT optional.
