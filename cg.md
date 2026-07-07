I agree with your direction.

There's a difference between **finishing a tool** and **continuing to add features**, and I think you've reached the former.

The regex fix is also the correct one. Rejecting `1.` while accepting `1.0`, `1.00`, etc. removes an ambiguous input without affecting valid usage. 

### I wouldn't add the other features either

Things like:

* Search history
* Random channel
* Debug mode
* Persistent config
* Help screens

are all reasonable ideas, but they don't solve a problem your current tool has. They increase code size, testing effort, and maintenance.

Your launcher has a very clear scope:

> Select a playlist **or** search for a channel → launch it in VLC.

It does that well.

### What I'd do next instead

Rather than growing `v0.1.x`, I'd shift focus to release quality:

* ✅ `README.md` with screenshots and usage examples
* ✅ `LICENSE`
* ✅ `CHANGELOG.md`
* ✅ GitHub release (`v0.1.0`)
* ✅ A handful of smoke tests on Windows, Linux, and macOS
* ✅ Tag the release

Then leave it alone unless users report issues.

### The only improvement I'd still keep on the roadmap

The only thing I'd still consider a worthwhile technical enhancement isn't a user-facing feature:

**Atomic cache writes.**

Instead of writing directly to the cache file, write to a temporary file and replace the cache atomically. This protects against partial cache files if the process is interrupted during a write. 

That's the only item I'd still classify as improving robustness rather than expanding scope.

## Final assessment

If this were my repository, I'd tag it as:

> **v0.1.0 — Initial stable release**

From here, I'd avoid adding features unless one of these happens:

* A real bug is reported.
* Multiple users request the same capability.
* A feature clearly aligns with the project's core purpose.

That approach tends to produce small, dependable utilities instead of tools that gradually become harder to maintain. Based on the evolution of the code you've shared, I think you've found a good stopping point for this first release.
