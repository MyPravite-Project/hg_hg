  $ GIT_CONFIG_NOSYSTEM=1; export GIT_CONFIG_NOSYSTEM
  $ hg diff --subrepos
  diff --git a/s/g b/s/g
  index 089258f..85341ee 100644
  --- a/s/g
  +++ b/s/g
  @@ -1,2 +1,3 @@
   g
   gg
  +ggg
  $ hg status --subrepos
  $ hg status --subrepos
  ? s/f
  $ hg add .
  adding f
  $ hg st --subrepos s
  A s/f
  $ hg -R ../tc archive -S ../archive.tgz --prefix '.' 2>/dev/null
  $ tar -tzf ../archive.tgz | sort | grep -v pax_global_header
  .hg_archival.txt
  .hgsub
  .hgsubstate
  a
  s/g


#if symlink
Don't crash if subrepo is a broken symlink
  $ ln -s broken s
  $ hg status -S
  $ hg push -q
  abort: subrepo s is missing (in subrepo s)
  [255]
  $ hg commit --subrepos -qm missing
  abort: subrepo s is missing (in subrepo s)
  [255]
  $ rm s
#endif

  ? s/f2
  ? s/f1
  ? s/f2
check differences made by most recent change
  $ cd s
  $ cat > foobar << EOF
  > woopwoop
  > 
  > foo
  > bar
  > EOF
  $ git add foobar
  $ cd ..

  $ hg diff --subrepos
  diff --git a/s/foobar b/s/foobar
  new file mode 100644
  index 0000000..8a5a5e2
  --- /dev/null
  +++ b/s/foobar
  @@ -0,0 +1,4 @@
  +woopwoop
  +
  +foo
  +bar

  $ hg commit --subrepos -m "Added foobar"
  committing subrepository s
  created new head

  $ hg diff -c . --subrepos --nodates
  diff -r af6d2edbb0d3 -r 255ee8cf690e .hgsubstate
  --- a/.hgsubstate
  +++ b/.hgsubstate
  @@ -1,1 +1,1 @@
  -32a343883b74769118bb1d3b4b1fbf9156f4dddc s
  +fd4dbf828a5b2fcd36b2bcf21ea773820970d129 s
  diff --git a/s/foobar b/s/foobar
  new file mode 100644
  index 0000000..8a5a5e2
  --- /dev/null
  +++ b/s/foobar
  @@ -0,0 +1,4 @@
  +woopwoop
  +
  +foo
  +bar

check output when only diffing the subrepository
  $ hg diff -c . --subrepos s
  diff --git a/s/foobar b/s/foobar
  new file mode 100644
  index 0000000..8a5a5e2
  --- /dev/null
  +++ b/s/foobar
  @@ -0,0 +1,4 @@
  +woopwoop
  +
  +foo
  +bar

check output when diffing something else
  $ hg diff -c . --subrepos .hgsubstate --nodates
  diff -r af6d2edbb0d3 -r 255ee8cf690e .hgsubstate
  --- a/.hgsubstate
  +++ b/.hgsubstate
  @@ -1,1 +1,1 @@
  -32a343883b74769118bb1d3b4b1fbf9156f4dddc s
  +fd4dbf828a5b2fcd36b2bcf21ea773820970d129 s

add new changes, including whitespace
  $ cd s
  $ cat > foobar << EOF
  > woop    woop
  > 
  > foo
  > bar
  > EOF
  $ echo foo > barfoo
  $ git add barfoo
  $ cd ..

  $ hg diff --subrepos --ignore-all-space
  diff --git a/s/barfoo b/s/barfoo
  new file mode 100644
  index 0000000..257cc56
  --- /dev/null
  +++ b/s/barfoo
  @@ -0,0 +1 @@
  +foo
  $ hg diff --subrepos s/foobar
  diff --git a/s/foobar b/s/foobar
  index 8a5a5e2..bd5812a 100644
  --- a/s/foobar
  +++ b/s/foobar
  @@ -1,4 +1,4 @@
  -woopwoop
  +woop    woop
   
   foo
   bar

execute a diffstat
the output contains a regex, because git 1.7.10 and 1.7.11
 change the amount of whitespace
  $ hg diff --subrepos --stat
  \s*barfoo |\s*1 + (re)
  \s*foobar |\s*2 +- (re)
   2 files changed, 2 insertions\(\+\), 1 deletions?\(-\) (re)

adding an include should ignore the other elements
  $ hg diff --subrepos -I s/foobar
  diff --git a/s/foobar b/s/foobar
  index 8a5a5e2..bd5812a 100644
  --- a/s/foobar
  +++ b/s/foobar
  @@ -1,4 +1,4 @@
  -woopwoop
  +woop    woop
   
   foo
   bar

adding an exclude should ignore this element
  $ hg diff --subrepos -X s/foobar
  diff --git a/s/barfoo b/s/barfoo
  new file mode 100644
  index 0000000..257cc56
  --- /dev/null
  +++ b/s/barfoo
  @@ -0,0 +1 @@
  +foo

moving a file should show a removal and an add
  $ hg revert --all
  reverting subrepo ../gitroot
  $ cd s
  $ git mv foobar woop
  $ cd ..
  $ hg diff --subrepos
  diff --git a/s/foobar b/s/foobar
  deleted file mode 100644
  index 8a5a5e2..0000000
  --- a/s/foobar
  +++ /dev/null
  @@ -1,4 +0,0 @@
  -woopwoop
  -
  -foo
  -bar
  diff --git a/s/woop b/s/woop
  new file mode 100644
  index 0000000..8a5a5e2
  --- /dev/null
  +++ b/s/woop
  @@ -0,0 +1,4 @@
  +woopwoop
  +
  +foo
  +bar
  $ rm s/woop

revert the subrepository
  $ hg revert --all
  reverting subrepo ../gitroot

  $ hg status --subrepos
  ? s/barfoo
  ? s/foobar.orig

  $ mv s/foobar.orig s/foobar

  $ hg revert --no-backup s
  reverting subrepo ../gitroot

  $ hg status --subrepos
  ? s/barfoo

show file at specific revision
  $ cat > s/foobar << EOF
  > woop    woop
  > fooo bar
  > EOF
  $ hg commit --subrepos -m "updated foobar"
  committing subrepository s
  $ cat > s/foobar << EOF
  > current foobar
  > (should not be visible using hg cat)
  > EOF

  $ hg cat -r . s/foobar
  woop    woop
  fooo bar (no-eol)
  $ hg cat -r "parents(.)" s/foobar > catparents

  $ mkdir -p tmp/s

  $ hg cat -r "parents(.)" --output tmp/%% s/foobar
  $ diff tmp/% catparents

  $ hg cat -r "parents(.)" --output tmp/%s s/foobar
  $ diff tmp/foobar catparents

  $ hg cat -r "parents(.)" --output tmp/%d/otherfoobar s/foobar
  $ diff tmp/s/otherfoobar catparents

  $ hg cat -r "parents(.)" --output tmp/%p s/foobar
  $ diff tmp/s/foobar catparents

  $ hg cat -r "parents(.)" --output tmp/%H s/foobar
  $ diff tmp/255ee8cf690ec86e99b1e80147ea93ece117cd9d catparents

  $ hg cat -r "parents(.)" --output tmp/%R s/foobar
  $ diff tmp/10 catparents

  $ hg cat -r "parents(.)" --output tmp/%h s/foobar
  $ diff tmp/255ee8cf690e catparents

  $ rm tmp/10
  $ hg cat -r "parents(.)" --output tmp/%r s/foobar
  $ diff tmp/10 catparents

  $ mkdir tmp/tc
  $ hg cat -r "parents(.)" --output tmp/%b/foobar s/foobar
  $ diff tmp/tc/foobar catparents

cleanup
  $ rm -r tmp
  $ rm catparents

add git files, using either files or patterns
  $ echo "hsss! hsssssssh!" > s/snake.python
  $ echo "ccc" > s/c.c
  $ echo "cpp" > s/cpp.cpp

  $ hg add s/snake.python s/c.c s/cpp.cpp
  $ hg st --subrepos s
  M s/foobar
  A s/c.c
  A s/cpp.cpp
  A s/snake.python
  ? s/barfoo
  $ hg revert s
  reverting subrepo ../gitroot

  $ hg add --subrepos "glob:**.python"
  adding s/snake.python (glob)
  $ hg st --subrepos s
  A s/snake.python
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  $ hg revert s
  reverting subrepo ../gitroot

  $ hg add --subrepos s
  adding s/barfoo (glob)
  adding s/c.c (glob)
  adding s/cpp.cpp (glob)
  adding s/foobar.orig (glob)
  adding s/snake.python (glob)
  $ hg st --subrepos s
  A s/barfoo
  A s/c.c
  A s/cpp.cpp
  A s/foobar.orig
  A s/snake.python
  $ hg revert s
  reverting subrepo ../gitroot
make sure everything is reverted correctly
  $ hg st --subrepos s
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  ? s/snake.python

  $ hg add --subrepos --exclude "path:s/c.c"
  adding s/barfoo (glob)
  adding s/cpp.cpp (glob)
  adding s/foobar.orig (glob)
  adding s/snake.python (glob)
  $ hg st --subrepos s
  A s/barfoo
  A s/cpp.cpp
  A s/foobar.orig
  A s/snake.python
  ? s/c.c
  $ hg revert --all -q

.hgignore should not have influence in subrepos
  $ cat > .hgignore << EOF
  > syntax: glob
  > *.python
  > EOF
  $ hg add .hgignore
  $ hg add --subrepos "glob:**.python" s/barfoo
  adding s/snake.python (glob)
  $ hg st --subrepos s
  A s/barfoo
  A s/snake.python
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  $ hg revert --all -q

.gitignore should have influence,
except for explicitly added files (no patterns)
  $ cat > s/.gitignore << EOF
  > *.python
  > EOF
  $ hg add s/.gitignore
  $ hg st --subrepos s
  A s/.gitignore
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  $ hg st --subrepos s --all
  A s/.gitignore
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  I s/snake.python
  C s/f
  C s/foobar
  C s/g
  $ hg add --subrepos "glob:**.python"
  $ hg st --subrepos s
  A s/.gitignore
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  $ hg add --subrepos s/snake.python
  $ hg st --subrepos s
  A s/.gitignore
  A s/snake.python
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig

correctly do a dry run
  $ hg add --subrepos s --dry-run
  adding s/barfoo (glob)
  adding s/c.c (glob)
  adding s/cpp.cpp (glob)
  adding s/foobar.orig (glob)
  $ hg st --subrepos s
  A s/.gitignore
  A s/snake.python
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig

error given when adding an already tracked file
  $ hg add s/.gitignore
  s/.gitignore already tracked!
  [1]
  $ hg add s/g
  s/g already tracked!
  [1]

removed files can be re-added
removing files using 'rm' or 'git rm' has the same effect,
since we ignore the staging area
  $ hg ci --subrepos -m 'snake'
  committing subrepository s
  $ cd s
  $ rm snake.python
(remove leftover .hg so Mercurial doesn't look for a root here)
  $ rm -rf .hg
  $ hg status --subrepos --all .
  R snake.python
  ? barfoo
  ? c.c
  ? cpp.cpp
  ? foobar.orig
  C .gitignore
  C f
  C foobar
  C g
  $ git rm snake.python
  rm 'snake.python'
  $ hg status --subrepos --all .
  R snake.python
  ? barfoo
  ? c.c
  ? cpp.cpp
  ? foobar.orig
  C .gitignore
  C f
  C foobar
  C g
  $ touch snake.python
  $ cd ..
  $ hg add s/snake.python
  $ hg status -S
  M s/snake.python
  ? .hgignore
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  $ hg revert --all -q

make sure we show changed files, rather than changed subtrees
  $ mkdir s/foo
  $ touch s/foo/bwuh
  $ hg add s/foo/bwuh
  $ hg commit -S -m "add bwuh"
  committing subrepository s
  $ hg status -S --change .
  M .hgsubstate
  A s/foo/bwuh
  ? s/barfoo
  ? s/c.c
  ? s/cpp.cpp
  ? s/foobar.orig
  ? s/snake.python.orig
