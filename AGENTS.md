# Codex Context Rules

Use Serena MCP as the primary code exploration mechanism.

Before reading source files:

1. Search for relevant symbols using Serena.
2. Find symbol references using Serena.
3. Retrieve only the required classes/functions.
4. Do not read complete files unless required.
5. Do not recursively scan the entire repository.
6. Do not inspect generated, build, export, cache, or .git directories.
7. Do not reread unchanged files.
8. Use git diff after modifications.
9. Prefer symbol-level edits over full-file rewrites.
10. Keep MCP responses concise.

For Godot:
- Prefer locating scenes and GDScript symbols before opening files.
- Follow dependencies only as needed.
- Inspect project.godot only when configuration/autoload information is required.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
