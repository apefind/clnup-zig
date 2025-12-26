clnup
=====

``clnup`` is a file cleanup utility written in `Zig <https://ziglang.org/>`_.
It reads a ``.clnup`` configuration file containing simple path-matching rules,
then recursively walks the current working directory to apply actions such
as printing, deleting, or touching matched files.

This tool is useful for scripted cleanups, build directories, or project maintenance tasks where
fine-grained pattern control is needed.

Features
--------

- Reads cleanup rules from a ``.clnup`` file.
- Supports simple glob-style patterns (``*`` and ``?``).
- Pattern modifiers for negation, directory-only, and anchoring.
- Runtime-selectable actions:

  - ``print``: Display matching paths (dry-run mode).
  - ``delete``: Recursively delete matching files or directories.
  - ``touch``: Ensure matching files exist.

- Works entirely within the current working directory—safe by design.

Usage
-----

.. code-block:: bash

   clnup -file <path/to/.clnup> [-action=print|delete|touch] [-dry-run]

Options
~~~~~~~

- ``-file``: Path to the cleanup rules file (default: ``.clnup``).
- ``-action``: Operation to perform:

  - ``print`` — show matching paths only.
  - ``delete`` — remove matching paths.
  - ``touch`` — ensure file exists (creates if missing).

- ``-dry-run``: Shortcut for performing a print-only run.

Example
~~~~~~~

.. code-block:: bash

   # Print matches without deleting
   clnup -file .clnup -dry-run

   # Actually delete matched files
   clnup -file .clnup -action delete

   # Create missing files matching rules
   clnup -file .clnup -action touch

The .clnup Specification
------------------------

Each line in the ``.clnup`` file defines a **rule**.
Rules are evaluated from top to bottom.

Each rule may specify:

- ``!`` — Negate the rule (keep instead of delete).
- ``/`` — Anchor the pattern to the repository root.
- Trailing ``/`` — Match directories only.
- ``#`` — Denote a comment line.

Blank lines and lines starting with ``#`` are ignored.

Patterns support simple globbing:

- ``*`` — matches zero or more characters.
- ``?`` — matches exactly one character.

Rules Syntax
~~~~~~~~~~~~

.. code-block::

   [!] [/]<pattern>[/]

Examples:

.. code-block:: text

   # Ignore all files ending in .log
   *.log

   # Only match directories named build/
   build/

   # Match anchored path "out/tmp"
   /out/tmp

   # Keep one directory intact
   !/out/cache/

Rule Evaluation
---------------

Rules are applied sequentially as the directory tree is traversed:

1. Each rule is checked in order.
2. If a file or directory matches:
   - The most recent matching rule determines whether it is *kept* or *deleted*.
   - ``!`` negates a deletion rule (forces keep).
3. Directory-only rules (ending with ``/``) apply only to directories.

The last matching rule wins.

Implementation Overview
-----------------------

- Written in Zig, using ``std.fs`` for filesystem access.
- Allocates dynamically for rule parsing via ``GeneralPurposeAllocator``.
- Uses a simple recursive directory walker.
- Simple glob matching implemented manually (``fnmatch`` equivalent for ``*`` and ``?``).
- Supports function-pointer-dispatched handlers for ``print``, ``delete``, ``touch``.

Example .clnup File
-------------------

.. code-block:: text

   # Delete all build outputs
   build/

   # Delete all log files
   *.log

   # But keep the persistent cache
   !/build/cache/

   # Delete temporary files anywhere
   *~


Building
--------

.. code-block:: bash

   zig build-exe clnup.zig -O ReleaseSafe

   # or run directly with zig
   zig run clnup.zig -- -file .clnup -dry-run

License
-------

MIT License (or specify your own).
This project is open source and uses no external dependencies.
