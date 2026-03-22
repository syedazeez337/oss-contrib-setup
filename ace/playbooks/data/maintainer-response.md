# Maintainer Response Strategy

## Strategies & Insights
- [s1] helpful=3 harmful=0 :: Respond to review comments within 24 hours — maintainers lose context and momentum after that
- [s2] helpful=3 harmful=0 :: Never argue about style preferences — just do it their way and move on. Save your opinions for your own projects.
- [s3] helpful=2 harmful=0 :: If a requested change is large or unclear, ask one specific clarifying question before implementing — do not guess
- [s4] helpful=2 harmful=0 :: If a PR stalls 2 weeks after your last update with no response — ping once with a short polite comment. If no response after another week, close it and move on.
- [s5] helpful=1 harmful=0 :: Mark each review comment as resolved after addressing it — makes it easier for maintainers to re-review
- [s6] helpful=2 harmful=0 :: When you push fixes for review comments, add a short comment summarizing what changed — saves the reviewer time. Example: "Addressed: added bounds check per G115 feedback, updated test to cover the overflow case"

## Common Mistakes
- [m1] helpful=0 harmful=2 :: Letting a PR sit unresponded for >3 days — maintainers move on to other work
- [m2] helpful=0 harmful=2 :: Pushing a force-push after review starts without warning — breaks reviewer context. Warn first or use a new commit.
- [m3] helpful=0 harmful=1 :: Asking maintainers to review immediately after pushing — give them 24-48 hours
- [m4] helpful=0 harmful=1 :: Responding to every individual comment separately instead of batching responses — increases noise for maintainers
