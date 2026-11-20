"""Open the path at a tmux mouse or copy-mode cursor in the pane to its right."""

import json
import re
import subprocess
import sys
import unicodedata
from pathlib import Path
from urllib.parse import unquote, urlsplit


REFERENCE = re.compile(r"file://[^\s<>()`\"']+|[\w~@./+%=-]+(?::[0-9]+(?::[0-9]+)?)?")
LOCATION = re.compile(r":([0-9]+)(?::([0-9]+))?$")
FRAGMENT = re.compile(r"L?([0-9]+)(?:C([0-9]+)|-L[0-9]+)?$")


def cell_width(text):
    return sum(
        0 if unicodedata.combining(char) or unicodedata.category(char) in ("Cf", "Mn", "Me")
        else 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        for char in text
    )


def reference_at(text, x):
    # Don't reinterpret parts of web links as local filenames.
    if any(not m[0].startswith("file://") and cell_width(text[:m.start()]) <= x < cell_width(text[:m.end()])
           for m in re.finditer(r"[\w+.-]+://\S+", text)):
        return None
    for match in REFERENCE.finditer(text):
        token = match[0].rstrip(".,;")
        left = cell_width(text[:match.start()])
        if token and left <= x < left + cell_width(token):
            return token
    return None


def resolve(token, cwd):
    line = column = 0
    if token.startswith("file://"):
        url = urlsplit(token)
        if url.netloc.lower() not in ("", "localhost") or not url.path.startswith("/"):
            raise ValueError("Not a local file link.")
        path = Path(unquote(url.path))
        match = FRAGMENT.fullmatch(url.fragment)
    else:
        if "://" in token:
            raise ValueError("Not a local file link.")
        match = LOCATION.search(token)
        path = Path(token[:match.start()] if match else token).expanduser()
    if match:
        line = int(match[1])
        column = int(match[2] or 0)
    path = cwd / path
    if not (path.is_file() or path.is_dir()):
        raise ValueError("Path not found in the OpenCode pane's working directory.")
    return str(path.absolute()), line, column


def main(socket, pane, x, screen_line, hyperlink, mode=None):
    def tmux(*args):
        return subprocess.check_output(["tmux", "-S", socket, *args], text=True, timeout=3).rstrip("\n")

    try:
        origin = tmux("display-message", "-p", "-t", pane,
                      "#{pane_right}\t#{pane_top}\t#{pane_bottom}\t#{pane_current_path}")
        right, top, bottom, cwd = origin.split("\t", 3)
        token = hyperlink or reference_at(screen_line, int(x))
        if not token or (not hyperlink and "/" not in token and "." not in token and ":" not in token):
            return
        if "://" in token and not token.startswith("file://"):
            return
        path, line, column = resolve(token, Path(cwd))
        rows = tmux("list-panes", "-t", pane, "-F",
                    "#{pane_id}\t#{pane_left}\t#{pane_top}\t#{pane_bottom}\t#{pane_current_command}\t#{@nvim_socket}")
        targets = []
        for row in rows.splitlines():
            target, x_left, y_top, y_bottom, command, address = row.split("\t", 5)
            overlap = min(int(bottom), int(y_bottom)) - max(int(top), int(y_top)) + 1
            if target != pane and int(x_left) > int(right) and overlap > 0 and command == "nvim":
                targets.append((int(x_left), -overlap, target, address))
        targets.sort()
        if not targets or (len(targets) > 1 and targets[0][:2] == targets[1][:2]):
            raise ValueError("No unambiguous Neovim pane to the right.")
        _, _, target, address = targets[0]
        if not address or not Path(address).is_socket():
            raise ValueError("In the right Neovim pane, run :lua require('config.tmux_open').register()")

        args = json.dumps([path, min(line, 2147483647), min(column, 2147483647)], ensure_ascii=False)
        expression = f'''luaeval("require('config.tmux_open').open(unpack(_A))", {args})'''
        opened = subprocess.run(["nvim", "--server", address, "--remote-expr", expression],
                                text=True, capture_output=True, check=True, timeout=3).stdout.strip()
        if opened != "true":
            raise ValueError("Neovim could not display that buffer.")
        if mode == "copy-mode":
            tmux("send-keys", "-t", pane, "-X", "cancel")
        tmux("select-pane", "-t", target)
    except ValueError as error:
        tmux("display-message", "-t", pane, f"Open in Neovim: {error}")
    except (OSError, subprocess.SubprocessError):
        tmux("display-message", "-t", pane, "Open in Neovim: could not contact the pane or editor.")


if __name__ == "__main__":
    # The binding prefixes text arguments so that empty tmux formats survive shell expansion.
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4][1:], sys.argv[5][1:], *sys.argv[6:])
