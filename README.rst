clnup
=====

``clnup`` is a directory cleanup tool written in `Zig <https://ziglang.org/>`_.
It reads pattern-based cleanup rules from a ``.clnup`` file and deletes matching files or directories by default.
A dry-run mode is available to preview which items would be deleted.

Features
--------

- Default action: **delete** files and directories matched by rules.
- **Dry-run mode** (``-d``) prints matches without deleting them.
- Supports simple globbing (``*``, ``?``).
- Handles negated rules (``!pattern``), directory-only matches, and anchored patterns.
- Recursively traverses directories with the ``-r`` option.
- Safe-by-design: prints rules and paths before deleting (unless quiet).

Usage
-----

.. code-block:: bash

   clnup [options] [path]

The optional *path* argument defaults to the current directory (``.``).

Options
-------

- ``-r``
  Recurse into subdirectories. Non-recursive by default.

- ``-f <file>``
  Specify a rules file path. Defaults to ``.clnup``.

- ``-q``
  Quiet mode — suppress all normal output.

- ``-v``
  Verbose mode — print rule evaluation details and actions.

- ``-d``
  Dry run. Only print matched paths; do not delete files or directories.

Examples
--------

.. code-block:: bash

   # Dry-run: list what would be deleted
   clnup -r -d

   # Delete recursively using the default .clnup file
   clnup -r

   # Use a global cleanup file
   clnup -f $HOME/.clnup -r

   # Run quietly but still perform deletions
   clnup -q -r

   # Verbose dry-run on a nested directory
   clnup -r -v -d ../build/tmp/a/b

The .clnup Specification
------------------------

Each line in a ``.clnup`` file defines a **rule**.

Rules determine which files are removed (or matched in dry-run mode).

Syntax
~~~~~~

.. code-block::

   [!] [/]<pattern>[/]

Meaning:

- ``!`` — Negate a rule (keep instead of delete).
- ``/`` — Anchor a pattern to the top-level cleanup root.
- Trailing ``/`` — Match directories only.
- Lines starting with ``#`` — Comments, ignored.
- Blank lines are skipped.

Rules are applied in order; the **last matching rule wins**.

Matching Semantics
~~~~~~~~~~~~~~~~~~

``clnup`` supports glob wildcards:

- ``*`` matches zero or more characters.
- ``?`` matches exactly one character.

Example
~~~~~~~

.. code-block:: text

   # Remove build directories and temporary files
   build/
   *.log
   *~

   # Keep cache directories
   !/build/cache/

Evaluation Rules
----------------

1. Directories are traversed recursively if ``-r`` is provided.
2. Each file or directory is compared against all rules in order.
3. The most recent match decides:
   - Delete (default)
   - Keep (if negated rule matched)
4. When running in dry-run mode (``-d``), matched paths are printed instead of deleted.

Verbose Output
--------------

With ``-v``, ``clnup`` provides additional diagnostics:

.. code-block:: text

   [delete] build/logs
   [skip]   build/cache/
   [dry-run] build/tmp

Quiet Mode
----------

With ``-q``, output is suppressed except for errors—useful in scripts or cron jobs.

Examples
--------

.. code-block:: bash

   # non-recursive dry-run
   clnup -d

   # fully recursive delete
   clnup -r

   # use alternate rules file
   clnup -f ~/.config/cleanup.rules -r -v

Implementation
--------------

- Written in Zig using ``std.fs`` APIs.
- Uses a simple recursive walker with ``deleteTree`` for directories.
- Implements its own minimal ``fnmatch`` for ``*`` and ``?`` patterns.
- Argument parsing supports short POSIX-style flags.

Building
--------

.. code-block:: bash

   zig build-exe clnup.zig -O ReleaseSafe

or run directly with Zig:

.. code-block:: bash

   zig run clnup.zig -- -r -d


License
-------

MIT License (or your preferred license).
No external dependencies beyond Zig standard library.
