// Cuts one stream's chunks into whole lines. The soak keeps one of these for the program's output and one for its error stream: a release program writes its output in blocks that end mid-line, so a shared
// buffer let an exit-time ERROR line land inside a half-written sample line (the first Linux soak: one unreadable number, "n/a ms at most").
export function splitter(push) {
  let rest = '';
  return {
    take(chunk) {
      rest += chunk;
      const parts = rest.split(/\r?\n/);
      rest = parts.pop();
      for (const line of parts) push(line);
    },
    end() {
      if (rest) push(rest);
      rest = '';
    },
  };
}
