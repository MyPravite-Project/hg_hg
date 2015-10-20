#require serve

  $ hg init test
  $ cd test

  $ echo foo>foo
  $ hg addremove
  adding foo
  $ hg commit -m 1

  $ hg verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  1 files, 1 changesets, 1 total revisions

  $ hg serve -p $HGPORT -d --pid-file=hg.pid
  $ cat hg.pid >> $DAEMON_PIDS
  $ cd ..

  $ hg clone --pull http://foo:bar@localhost:$HGPORT/ copy
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd copy
  $ hg verify
  checking changesets
  checking manifests
  crosschecking files in changesets and manifests
  checking files
  1 files, 1 changesets, 1 total revisions

  $ hg co
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cat foo
  foo

  $ hg manifest --debug
  2ed2a3912a0b24502043eae84ee4b279c18b90dd 644   foo

  $ hg pull
  pulling from http://foo@localhost:$HGPORT/
  searching for changes
  no changes found

  $ hg rollback --dry-run --verbose
  repository tip rolled back to revision -1 (undo pull: http://foo:***@localhost:$HGPORT/)

Test pull of non-existing 20 character revision specification, making sure plain ascii identifiers
not are encoded like a node:

  $ hg pull -r 'xxxxxxxxxxxxxxxxxxxy'
  pulling from http://foo@localhost:$HGPORT/
  abort: unknown revision 'xxxxxxxxxxxxxxxxxxxy'!
  [255]
  $ hg pull -r 'xxxxxxxxxxxxxxxxxx y'
  pulling from http://foo@localhost:$HGPORT/
  abort: unknown revision '7878787878787878787878787878787878782079'!
  [255]

Issue622: hg init && hg pull -u URL doesn't checkout default branch

  $ cd ..
  $ hg init empty
  $ cd empty
  $ hg pull -u ../test
  pulling from ../test
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

Test 'file:' uri handling:

  $ hg pull -q file://../test-does-not-exist
  abort: file:// URLs can only refer to localhost
  [255]

  $ hg pull -q file://../test
  abort: file:// URLs can only refer to localhost
  [255]

  $ hg pull -q file:../test  # no-msys

It's tricky to make file:// URLs working on every platform with
regular shell commands.

  $ URL=`$PYTHON -c "import os; print 'file://foobar' + ('/' + os.getcwd().replace(os.sep, '/')).replace('//', '/') + '/../test'"`
  $ hg pull -q "$URL"
  abort: file:// URLs can only refer to localhost
  [255]

  $ URL=`$PYTHON -c "import os; print 'file://localhost' + ('/' + os.getcwd().replace(os.sep, '/')).replace('//', '/') + '/../test'"`
  $ hg pull -q "$URL"

  $ cd ..
