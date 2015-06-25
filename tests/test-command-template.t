  $ hg log -T '{rev} {ifcontains("fourth", file_copies, "t", "f")}\n' -r .:7
  8 t
  7 f

Working-directory revision has special identifiers, though they are still
experimental:

  $ hg log -r 'wdir()' -T '{rev}:{node}\n'
  2147483647:ffffffffffffffffffffffffffffffffffffffff

Some keywords are invalid for working-directory revision, but they should
never cause crash:

  $ hg log -r 'wdir()' -T '{manifest}\n'
  
Add a commit with empty description, to ensure that the templates
below will omit the description line.

  $ echo c >> c
  $ hg add c
  $ hg commit -qm ' '

Default style is like normal output. Phases style should be the same
as default style, except for extra phase lines.
  $ hg log -T phases > phases.out
  $ diff -U 0 log.out phases.out | grep -v '^---\|^+++'
  @@ -2,0 +3 @@
  +phase:       draft
  @@ -6,0 +8 @@
  +phase:       draft
  @@ -11,0 +14 @@
  +phase:       draft
  @@ -17,0 +21 @@
  +phase:       draft
  @@ -24,0 +29 @@
  +phase:       draft
  @@ -31,0 +37 @@
  +phase:       draft
  @@ -36,0 +43 @@
  +phase:       draft
  @@ -41,0 +49 @@
  +phase:       draft
  @@ -46,0 +55 @@
  +phase:       draft
  @@ -51,0 +61 @@
  +phase:       draft
  $ hg log -v -T phases > phases.out
  $ diff -U 0 log.out phases.out | grep -v '^---\|^+++'
  @@ -2,0 +3 @@
  +phase:       draft
  @@ -7,0 +9 @@
  +phase:       draft
  @@ -15,0 +18 @@
  +phase:       draft
  @@ -24,0 +28 @@
  +phase:       draft
  @@ -33,0 +38 @@
  +phase:       draft
  @@ -43,0 +49 @@
  +phase:       draft
  @@ -50,0 +57 @@
  +phase:       draft
  @@ -58,0 +66 @@
  +phase:       draft
  @@ -66,0 +75 @@
  +phase:       draft
  @@ -77,0 +87 @@
  +phase:       draft

  $ hg log -q > log.out
  $ hg log -q --style default > style.out
  $ cmp log.out style.out || diff -u log.out style.out
  $ hg log -q -T phases > phases.out
  $ cmp log.out phases.out || diff -u log.out phases.out
  $ hg log --debug -T phases > phases.out
  $ cmp log.out phases.out || diff -u log.out phases.out

Default style of working-directory revision should also be the same (but
date may change while running tests):

  $ hg log -r 'wdir()' | sed 's|^date:.*|date:|' > log.out
  $ hg log -r 'wdir()' --style default | sed 's|^date:.*|date:|' > style.out
  $ cmp log.out style.out || diff -u log.out style.out

  $ hg log -r 'wdir()' -v | sed 's|^date:.*|date:|' > log.out
  $ hg log -r 'wdir()' -v --style default | sed 's|^date:.*|date:|' > style.out
  $ cmp log.out style.out || diff -u log.out style.out

  $ hg log -r 'wdir()' -q > log.out
  $ hg log -r 'wdir()' -q --style default > style.out
  $ cmp log.out style.out || diff -u log.out style.out

  $ hg log -r 'wdir()' --debug | sed 's|^date:.*|date:|' > log.out
  $ hg log -r 'wdir()' --debug --style default \
  > | sed 's|^date:.*|date:|' > style.out
  $ cmp log.out style.out || diff -u log.out style.out
  $ hg --color=debug log -T phases > phases.out
  $ diff -U 0 log.out phases.out | grep -v '^---\|^+++'
  @@ -2,0 +3 @@
  +[log.phase|phase:       draft]
  @@ -6,0 +8 @@
  +[log.phase|phase:       draft]
  @@ -11,0 +14 @@
  +[log.phase|phase:       draft]
  @@ -17,0 +21 @@
  +[log.phase|phase:       draft]
  @@ -24,0 +29 @@
  +[log.phase|phase:       draft]
  @@ -31,0 +37 @@
  +[log.phase|phase:       draft]
  @@ -36,0 +43 @@
  +[log.phase|phase:       draft]
  @@ -41,0 +49 @@
  +[log.phase|phase:       draft]
  @@ -46,0 +55 @@
  +[log.phase|phase:       draft]
  @@ -51,0 +61 @@
  +[log.phase|phase:       draft]

  $ hg --color=debug -v log -T phases > phases.out
  $ diff -U 0 log.out phases.out | grep -v '^---\|^+++'
  @@ -2,0 +3 @@
  +[log.phase|phase:       draft]
  @@ -7,0 +9 @@
  +[log.phase|phase:       draft]
  @@ -15,0 +18 @@
  +[log.phase|phase:       draft]
  @@ -24,0 +28 @@
  +[log.phase|phase:       draft]
  @@ -33,0 +38 @@
  +[log.phase|phase:       draft]
  @@ -43,0 +49 @@
  +[log.phase|phase:       draft]
  @@ -50,0 +57 @@
  +[log.phase|phase:       draft]
  @@ -58,0 +66 @@
  +[log.phase|phase:       draft]
  @@ -66,0 +75 @@
  +[log.phase|phase:       draft]
  @@ -77,0 +87 @@
  +[log.phase|phase:       draft]

  $ hg --color=debug -q log > log.out
  $ hg --color=debug -q log --style default > style.out
  $ cmp log.out style.out || diff -u log.out style.out
  $ hg --color=debug -q log -T phases > phases.out
  $ cmp log.out phases.out || diff -u log.out phases.out

  $ hg --color=debug --debug log -T phases > phases.out
  $ cmp log.out phases.out || diff -u log.out phases.out
Remove commit with empty commit message, so as to not pollute further
tests.

  $ hg --config extensions.strip= strip -q .

honor --git but not format-breaking diffopts
  $ hg --config diff.noprefix=True log --git -vpr . -Tjson
  [
   {
    "rev": 8,
    "node": "95c24699272ef57d062b8bccc32c878bf841784a",
    "branch": "default",
    "phase": "draft",
    "user": "test",
    "date": [1577872860, 0],
    "desc": "third",
    "bookmarks": [],
    "tags": ["tip"],
    "parents": ["29114dbae42b9f078cf2714dbe3a86bba8ec7453"],
    "files": ["fourth", "second", "third"],
    "diff": "diff --git a/second b/fourth\nrename from second\nrename to fourth\ndiff --git a/third b/third\nnew file mode 100644\n--- /dev/null\n+++ b/third\n@@ -0,0 +1,1 @@\n+third\n"
   }
  ]

  (available styles: bisect, changelog, compact, default, phases, status, xml)
  available styles: bisect, changelog, compact, default, phases, status, xml
  $ hg init unstable-hash
  $ cd unstable-hash
  $ cd ..
  $ rm -rf unstable-hash

Add a dummy commit to make up for the instability of the above:

  $ echo a > a
  $ hg add a
  $ hg ci -m future

Upper/lower filters:

  $ hg log -r0 --template '{branch|upper}\n'
  DEFAULT
  $ hg log -r0 --template '{author|lower}\n'
  user name <user@hostname>
  $ hg log -r0 --template '{date|upper}\n'
  abort: template filter 'upper' is not compatible with keyword 'date'
  [255]

Add a commit that does all possible modifications at once

  $ echo modify >> third
  $ touch b
  $ hg add b
  $ hg mv fourth fifth
  $ hg rm a
  $ hg ci -m "Modify, add, remove, rename"

Check the status template

  $ cat <<EOF >> $HGRCPATH
  > [extensions]
  > color=
  > EOF

  $ hg log -T status -r 10
  changeset:   10:0f9759ec227a
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     Modify, add, remove, rename
  files:
  M third
  A b
  A fifth
  R a
  R fourth
  
  $ hg log -T status -C -r 10
  changeset:   10:0f9759ec227a
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     Modify, add, remove, rename
  files:
  M third
  A b
  A fifth
    fourth
  R a
  R fourth
  
  $ hg log -T status -C -r 10 -v
  changeset:   10:0f9759ec227a
  tag:         tip
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  description:
  Modify, add, remove, rename
  
  files:
  M third
  A b
  A fifth
    fourth
  R a
  R fourth
  
  $ hg log -T status -C -r 10 --debug
  changeset:   10:0f9759ec227a4859c2014a345cd8a859022b7c6c
  tag:         tip
  phase:       secret
  parent:      9:bf9dfba36635106d6a73ccc01e28b762da60e066
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    8:89dd546f2de0a9d6d664f58d86097eb97baba567
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  extra:       branch=default
  description:
  Modify, add, remove, rename
  
  files:
  M third
  A b
  A fifth
    fourth
  R a
  R fourth
  
  $ hg log -T status -C -r 10 --quiet
  10:0f9759ec227a
  $ hg --color=debug log -T status -r 10
  [log.changeset changeset.secret|changeset:   10:0f9759ec227a]
  [log.tag|tag:         tip]
  [log.user|user:        test]
  [log.date|date:        Thu Jan 01 00:00:00 1970 +0000]
  [log.summary|summary:     Modify, add, remove, rename]
  [ui.note log.files|files:]
  [status.modified|M third]
  [status.added|A b]
  [status.added|A fifth]
  [status.removed|R a]
  [status.removed|R fourth]
  
  $ hg --color=debug log -T status -C -r 10
  [log.changeset changeset.secret|changeset:   10:0f9759ec227a]
  [log.tag|tag:         tip]
  [log.user|user:        test]
  [log.date|date:        Thu Jan 01 00:00:00 1970 +0000]
  [log.summary|summary:     Modify, add, remove, rename]
  [ui.note log.files|files:]
  [status.modified|M third]
  [status.added|A b]
  [status.added|A fifth]
  [status.copied|  fourth]
  [status.removed|R a]
  [status.removed|R fourth]
  
  $ hg --color=debug log -T status -C -r 10 -v
  [log.changeset changeset.secret|changeset:   10:0f9759ec227a]
  [log.tag|tag:         tip]
  [log.user|user:        test]
  [log.date|date:        Thu Jan 01 00:00:00 1970 +0000]
  [ui.note log.description|description:]
  [ui.note log.description|Modify, add, remove, rename]
  
  [ui.note log.files|files:]
  [status.modified|M third]
  [status.added|A b]
  [status.added|A fifth]
  [status.copied|  fourth]
  [status.removed|R a]
  [status.removed|R fourth]
  
  $ hg --color=debug log -T status -C -r 10 --debug
  [log.changeset changeset.secret|changeset:   10:0f9759ec227a4859c2014a345cd8a859022b7c6c]
  [log.tag|tag:         tip]
  [log.phase|phase:       secret]
  [log.parent changeset.secret|parent:      9:bf9dfba36635106d6a73ccc01e28b762da60e066]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    8:89dd546f2de0a9d6d664f58d86097eb97baba567]
  [log.user|user:        test]
  [log.date|date:        Thu Jan 01 00:00:00 1970 +0000]
  [ui.debug log.extra|extra:       branch=default]
  [ui.note log.description|description:]
  [ui.note log.description|Modify, add, remove, rename]
  
  [ui.note log.files|files:]
  [status.modified|M third]
  [status.added|A b]
  [status.added|A fifth]
  [status.copied|  fourth]
  [status.removed|R a]
  [status.removed|R fourth]
  
  $ hg --color=debug log -T status -C -r 10 --quiet
  [log.node|10:0f9759ec227a]

Check the bisect template

  $ hg bisect -g 1
  $ hg bisect -b 3 --noupdate
  Testing changeset 2:97054abb4ab8 (2 changesets remaining, ~1 tests)
  $ hg log -T bisect -r 0:4
  changeset:   0:1e4e1b8f71e0
  bisect:      good (implicit)
  user:        User Name <user@hostname>
  date:        Mon Jan 12 13:46:40 1970 +0000
  summary:     line 1
  
  changeset:   1:b608e9d1a3f0
  bisect:      good
  user:        A. N. Other <other@place>
  date:        Tue Jan 13 17:33:20 1970 +0000
  summary:     other 1
  
  changeset:   2:97054abb4ab8
  bisect:      untested
  user:        other@place
  date:        Wed Jan 14 21:20:00 1970 +0000
  summary:     no person
  
  changeset:   3:10e46f2dcbf4
  bisect:      bad
  user:        person
  date:        Fri Jan 16 01:06:40 1970 +0000
  summary:     no user, no domain
  
  changeset:   4:bbe44766e73d
  bisect:      bad (implicit)
  branch:      foo
  user:        person
  date:        Sat Jan 17 04:53:20 1970 +0000
  summary:     new branch
  
  $ hg log --debug -T bisect -r 0:4
  changeset:   0:1e4e1b8f71e05681d422154f5421e385fec3454f
  bisect:      good (implicit)
  phase:       public
  parent:      -1:0000000000000000000000000000000000000000
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    0:a0c8bcbbb45c63b90b70ad007bf38961f64f2af0
  user:        User Name <user@hostname>
  date:        Mon Jan 12 13:46:40 1970 +0000
  files+:      a
  extra:       branch=default
  description:
  line 1
  line 2
  
  
  changeset:   1:b608e9d1a3f0273ccf70fb85fd6866b3482bf965
  bisect:      good
  phase:       public
  parent:      0:1e4e1b8f71e05681d422154f5421e385fec3454f
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    1:4e8d705b1e53e3f9375e0e60dc7b525d8211fe55
  user:        A. N. Other <other@place>
  date:        Tue Jan 13 17:33:20 1970 +0000
  files+:      b
  extra:       branch=default
  description:
  other 1
  other 2
  
  other 3
  
  
  changeset:   2:97054abb4ab824450e9164180baf491ae0078465
  bisect:      untested
  phase:       public
  parent:      1:b608e9d1a3f0273ccf70fb85fd6866b3482bf965
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    2:6e0e82995c35d0d57a52aca8da4e56139e06b4b1
  user:        other@place
  date:        Wed Jan 14 21:20:00 1970 +0000
  files+:      c
  extra:       branch=default
  description:
  no person
  
  
  changeset:   3:10e46f2dcbf4823578cf180f33ecf0b957964c47
  bisect:      bad
  phase:       public
  parent:      2:97054abb4ab824450e9164180baf491ae0078465
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    3:cb5a1327723bada42f117e4c55a303246eaf9ccc
  user:        person
  date:        Fri Jan 16 01:06:40 1970 +0000
  files:       c
  extra:       branch=default
  description:
  no user, no domain
  
  
  changeset:   4:bbe44766e73d5f11ed2177f1838de10c53ef3e74
  bisect:      bad (implicit)
  branch:      foo
  phase:       draft
  parent:      3:10e46f2dcbf4823578cf180f33ecf0b957964c47
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    3:cb5a1327723bada42f117e4c55a303246eaf9ccc
  user:        person
  date:        Sat Jan 17 04:53:20 1970 +0000
  extra:       branch=foo
  description:
  new branch
  
  
  $ hg log -v -T bisect -r 0:4
  changeset:   0:1e4e1b8f71e0
  bisect:      good (implicit)
  user:        User Name <user@hostname>
  date:        Mon Jan 12 13:46:40 1970 +0000
  files:       a
  description:
  line 1
  line 2
  
  
  changeset:   1:b608e9d1a3f0
  bisect:      good
  user:        A. N. Other <other@place>
  date:        Tue Jan 13 17:33:20 1970 +0000
  files:       b
  description:
  other 1
  other 2
  
  other 3
  
  
  changeset:   2:97054abb4ab8
  bisect:      untested
  user:        other@place
  date:        Wed Jan 14 21:20:00 1970 +0000
  files:       c
  description:
  no person
  
  
  changeset:   3:10e46f2dcbf4
  bisect:      bad
  user:        person
  date:        Fri Jan 16 01:06:40 1970 +0000
  files:       c
  description:
  no user, no domain
  
  
  changeset:   4:bbe44766e73d
  bisect:      bad (implicit)
  branch:      foo
  user:        person
  date:        Sat Jan 17 04:53:20 1970 +0000
  description:
  new branch
  
  
  $ hg --color=debug log -T bisect -r 0:4
  [log.changeset changeset.public|changeset:   0:1e4e1b8f71e0]
  [log.bisect bisect.good|bisect:      good (implicit)]
  [log.user|user:        User Name <user@hostname>]
  [log.date|date:        Mon Jan 12 13:46:40 1970 +0000]
  [log.summary|summary:     line 1]
  
  [log.changeset changeset.public|changeset:   1:b608e9d1a3f0]
  [log.bisect bisect.good|bisect:      good]
  [log.user|user:        A. N. Other <other@place>]
  [log.date|date:        Tue Jan 13 17:33:20 1970 +0000]
  [log.summary|summary:     other 1]
  
  [log.changeset changeset.public|changeset:   2:97054abb4ab8]
  [log.bisect bisect.untested|bisect:      untested]
  [log.user|user:        other@place]
  [log.date|date:        Wed Jan 14 21:20:00 1970 +0000]
  [log.summary|summary:     no person]
  
  [log.changeset changeset.public|changeset:   3:10e46f2dcbf4]
  [log.bisect bisect.bad|bisect:      bad]
  [log.user|user:        person]
  [log.date|date:        Fri Jan 16 01:06:40 1970 +0000]
  [log.summary|summary:     no user, no domain]
  
  [log.changeset changeset.draft|changeset:   4:bbe44766e73d]
  [log.bisect bisect.bad|bisect:      bad (implicit)]
  [log.branch|branch:      foo]
  [log.user|user:        person]
  [log.date|date:        Sat Jan 17 04:53:20 1970 +0000]
  [log.summary|summary:     new branch]
  
  $ hg --color=debug log --debug -T bisect -r 0:4
  [log.changeset changeset.public|changeset:   0:1e4e1b8f71e05681d422154f5421e385fec3454f]
  [log.bisect bisect.good|bisect:      good (implicit)]
  [log.phase|phase:       public]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    0:a0c8bcbbb45c63b90b70ad007bf38961f64f2af0]
  [log.user|user:        User Name <user@hostname>]
  [log.date|date:        Mon Jan 12 13:46:40 1970 +0000]
  [ui.debug log.files|files+:      a]
  [ui.debug log.extra|extra:       branch=default]
  [ui.note log.description|description:]
  [ui.note log.description|line 1
  line 2]
  
  
  [log.changeset changeset.public|changeset:   1:b608e9d1a3f0273ccf70fb85fd6866b3482bf965]
  [log.bisect bisect.good|bisect:      good]
  [log.phase|phase:       public]
  [log.parent changeset.public|parent:      0:1e4e1b8f71e05681d422154f5421e385fec3454f]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    1:4e8d705b1e53e3f9375e0e60dc7b525d8211fe55]
  [log.user|user:        A. N. Other <other@place>]
  [log.date|date:        Tue Jan 13 17:33:20 1970 +0000]
  [ui.debug log.files|files+:      b]
  [ui.debug log.extra|extra:       branch=default]
  [ui.note log.description|description:]
  [ui.note log.description|other 1
  other 2
  
  other 3]
  
  
  [log.changeset changeset.public|changeset:   2:97054abb4ab824450e9164180baf491ae0078465]
  [log.bisect bisect.untested|bisect:      untested]
  [log.phase|phase:       public]
  [log.parent changeset.public|parent:      1:b608e9d1a3f0273ccf70fb85fd6866b3482bf965]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    2:6e0e82995c35d0d57a52aca8da4e56139e06b4b1]
  [log.user|user:        other@place]
  [log.date|date:        Wed Jan 14 21:20:00 1970 +0000]
  [ui.debug log.files|files+:      c]
  [ui.debug log.extra|extra:       branch=default]
  [ui.note log.description|description:]
  [ui.note log.description|no person]
  
  
  [log.changeset changeset.public|changeset:   3:10e46f2dcbf4823578cf180f33ecf0b957964c47]
  [log.bisect bisect.bad|bisect:      bad]
  [log.phase|phase:       public]
  [log.parent changeset.public|parent:      2:97054abb4ab824450e9164180baf491ae0078465]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    3:cb5a1327723bada42f117e4c55a303246eaf9ccc]
  [log.user|user:        person]
  [log.date|date:        Fri Jan 16 01:06:40 1970 +0000]
  [ui.debug log.files|files:       c]
  [ui.debug log.extra|extra:       branch=default]
  [ui.note log.description|description:]
  [ui.note log.description|no user, no domain]
  
  
  [log.changeset changeset.draft|changeset:   4:bbe44766e73d5f11ed2177f1838de10c53ef3e74]
  [log.bisect bisect.bad|bisect:      bad (implicit)]
  [log.branch|branch:      foo]
  [log.phase|phase:       draft]
  [log.parent changeset.public|parent:      3:10e46f2dcbf4823578cf180f33ecf0b957964c47]
  [log.parent changeset.public|parent:      -1:0000000000000000000000000000000000000000]
  [ui.debug log.manifest|manifest:    3:cb5a1327723bada42f117e4c55a303246eaf9ccc]
  [log.user|user:        person]
  [log.date|date:        Sat Jan 17 04:53:20 1970 +0000]
  [ui.debug log.extra|extra:       branch=foo]
  [ui.note log.description|description:]
  [ui.note log.description|new branch]
  
  
  $ hg --color=debug log -v -T bisect -r 0:4
  [log.changeset changeset.public|changeset:   0:1e4e1b8f71e0]
  [log.bisect bisect.good|bisect:      good (implicit)]
  [log.user|user:        User Name <user@hostname>]
  [log.date|date:        Mon Jan 12 13:46:40 1970 +0000]
  [ui.note log.files|files:       a]
  [ui.note log.description|description:]
  [ui.note log.description|line 1
  line 2]
  
  
  [log.changeset changeset.public|changeset:   1:b608e9d1a3f0]
  [log.bisect bisect.good|bisect:      good]
  [log.user|user:        A. N. Other <other@place>]
  [log.date|date:        Tue Jan 13 17:33:20 1970 +0000]
  [ui.note log.files|files:       b]
  [ui.note log.description|description:]
  [ui.note log.description|other 1
  other 2
  
  other 3]
  
  
  [log.changeset changeset.public|changeset:   2:97054abb4ab8]
  [log.bisect bisect.untested|bisect:      untested]
  [log.user|user:        other@place]
  [log.date|date:        Wed Jan 14 21:20:00 1970 +0000]
  [ui.note log.files|files:       c]
  [ui.note log.description|description:]
  [ui.note log.description|no person]
  
  
  [log.changeset changeset.public|changeset:   3:10e46f2dcbf4]
  [log.bisect bisect.bad|bisect:      bad]
  [log.user|user:        person]
  [log.date|date:        Fri Jan 16 01:06:40 1970 +0000]
  [ui.note log.files|files:       c]
  [ui.note log.description|description:]
  [ui.note log.description|no user, no domain]
  
  
  [log.changeset changeset.draft|changeset:   4:bbe44766e73d]
  [log.bisect bisect.bad|bisect:      bad (implicit)]
  [log.branch|branch:      foo]
  [log.user|user:        person]
  [log.date|date:        Sat Jan 17 04:53:20 1970 +0000]
  [ui.note log.description|description:]
  [ui.note log.description|new branch]
  
  
  $ hg bisect --reset

  $ hg log -T '{date'
  hg: parse error at 1: unterminated template expansion
  [255]

Error in nested template:

  $ hg log -T '{"date'
  hg: parse error at 2: unterminated string
  [255]

  $ hg log -T '{"foo{date|=}"}'
  hg: parse error at 11: syntax error
  [255]

Pass generator object created by template function to filter

  $ hg log -l 1 --template '{if(author, author)|user}\n'
  test

  $ hg log -r 8 -T "{diff('FOURTH'|lower)}"
  diff -r 29114dbae42b -r 95c24699272e fourth
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/fourth	Wed Jan 01 10:01:00 2020 +0000
  @@ -0,0 +1,1 @@
  +second

Test invalid date:

  $ hg log -R latesttag -T '{date(rev)}\n'
  hg: parse error: date expects a date information
  [255]

Test integer literal:

  $ hg log -Ra -r0 -T '{(0)}\n'
  0
  $ hg log -Ra -r0 -T '{(123)}\n'
  123
  $ hg log -Ra -r0 -T '{(-4)}\n'
  -4
  $ hg log -Ra -r0 -T '{(-)}\n'
  hg: parse error at 2: integer literal without digits
  [255]
  $ hg log -Ra -r0 -T '{(-a)}\n'
  hg: parse error at 2: integer literal without digits
  [255]

top-level integer literal is interpreted as symbol (i.e. variable name):

  $ hg log -Ra -r0 -T '{1}\n'
  
  $ hg log -Ra -r0 -T '{if("t", "{1}")}\n'
  
  $ hg log -Ra -r0 -T '{1|stringify}\n'
  

unless explicit symbol is expected:

  $ hg log -Ra -r0 -T '{desc|1}\n'
  hg: parse error: expected a symbol, got 'integer'
  [255]
  $ hg log -Ra -r0 -T '{1()}\n'
  hg: parse error: expected a symbol, got 'integer'
  [255]

Test string literal:

  $ hg log -Ra -r0 -T '{"string with no template fragment"}\n'
  string with no template fragment
  $ hg log -Ra -r0 -T '{"template: {rev}"}\n'
  template: 0
  $ hg log -Ra -r0 -T '{r"rawstring: {rev}"}\n'
  rawstring: {rev}

because map operation requires template, raw string can't be used

  $ hg log -Ra -r0 -T '{files % r"rawstring"}\n'
  hg: parse error: expected template specifier
  [255]

  $ hg log -R latesttag -r 0 \
  > --config ui.logtemplate='>\n<>\\n<{if(rev, "[>\n<>\\n<]")}>\n<>\\n<\n'
  >
  <>\n<[>
  <>\n<]>
  <>\n<

  $ hg log -R latesttag -r 0 -T esc \
  > --config templates.esc='>\n<>\\n<{if(rev, "[>\n<>\\n<]")}>\n<>\\n<\n'
  >
  <>\n<[>
  <>\n<]>
  <>\n<

  $ cat <<'EOF' > esctmpl
  > changeset = '>\n<>\\n<{if(rev, "[>\n<>\\n<]")}>\n<>\\n<\n'
  > EOF
  $ hg log -R latesttag -r 0 --style ./esctmpl
  >
  <>\n<[>
  <>\n<]>
  <>\n<

Test string escaping of quotes:

  $ hg log -Ra -r0 -T '{"\""}\n'
  "
  $ hg log -Ra -r0 -T '{"\\\""}\n'
  \"
  $ hg log -Ra -r0 -T '{r"\""}\n'
  \"
  $ hg log -Ra -r0 -T '{r"\\\""}\n'
  \\\"


  $ hg log -Ra -r0 -T '{"\""}\n'
  "
  $ hg log -Ra -r0 -T '{"\\\""}\n'
  \"
  $ hg log -Ra -r0 -T '{r"\""}\n'
  \"
  $ hg log -Ra -r0 -T '{r"\\\""}\n'
  \\\"

Test exception in quoted template. single backslash before quotation mark is
stripped before parsing:

  $ cat <<'EOF' > escquotetmpl
  > changeset = "\" \\" \\\" \\\\" {files % \"{file}\"}\n"
  > EOF
  $ cd latesttag
  $ hg log -r 2 --style ../escquotetmpl
  " \" \" \\" head1

  $ hg log -r 2 -T esc --config templates.esc='"{\"valid\"}\n"'
  valid
  $ hg log -r 2 -T esc --config templates.esc="'"'{\'"'"'valid\'"'"'}\n'"'"
  valid

Test compatibility with 2.9.2-3.4 of escaped quoted strings in nested
_evalifliteral() templates (issue4733):

  $ hg log -r 2 -T '{if(rev, "\"{rev}")}\n'
  "2
  $ hg log -r 2 -T '{if(rev, "{if(rev, \"\\\"{rev}\")}")}\n'
  "2
  $ hg log -r 2 -T '{if(rev, "{if(rev, \"{if(rev, \\\"\\\\\\\"{rev}\\\")}\")}")}\n'
  "2

  $ hg log -r 2 -T '{if(rev, "\\\"")}\n'
  \"
  $ hg log -r 2 -T '{if(rev, "{if(rev, \"\\\\\\\"\")}")}\n'
  \"
  $ hg log -r 2 -T '{if(rev, "{if(rev, \"{if(rev, \\\"\\\\\\\\\\\\\\\"\\\")}\")}")}\n'
  \"

  $ hg log -r 2 -T '{if(rev, r"\\\"")}\n'
  \\\"
  $ hg log -r 2 -T '{if(rev, "{if(rev, r\"\\\\\\\"\")}")}\n'
  \\\"
  $ hg log -r 2 -T '{if(rev, "{if(rev, \"{if(rev, r\\\"\\\\\\\\\\\\\\\"\\\")}\")}")}\n'
  \\\"

escaped single quotes and errors:

  $ hg log -r 2 -T "{if(rev, '{if(rev, \'foo\')}')}"'\n'
  foo
  $ hg log -r 2 -T "{if(rev, '{if(rev, r\'foo\')}')}"'\n'
  foo
  $ hg log -r 2 -T '{if(rev, "{if(rev, \")}")}\n'
  hg: parse error at 21: unterminated string
  [255]
  $ hg log -r 2 -T '{if(rev, \"\\"")}\n'
  hg: parse error at 11: syntax error
  [255]
  $ hg log -r 2 -T '{if(rev, r\"\\"")}\n'
  hg: parse error at 12: syntax error
  [255]

  $ cd ..

Test leading backslashes:

  $ cd latesttag
  $ hg log -r 2 -T '\{rev} {files % "\{file}"}\n'
  {rev} {file}
  $ hg log -r 2 -T '\\{rev} {files % "\\{file}"}\n'
  \2 \head1
  $ hg log -r 2 -T '\\\{rev} {files % "\\\{file}"}\n'
  \{rev} \{file}
  $ cd ..

Test leading backslashes in "if" expression (issue4714):

  $ cd latesttag
  $ hg log -r 2 -T '{if("1", "\{rev}")} {if("1", r"\{rev}")}\n'
  {rev} \{rev}
  $ hg log -r 2 -T '{if("1", "\\{rev}")} {if("1", r"\\{rev}")}\n'
  \2 \\{rev}
  $ hg log -r 2 -T '{if("1", "\\\{rev}")} {if("1", r"\\\{rev}")}\n'
  \{rev} \\\{rev}
  $ cd ..

Test quotes in nested expression are evaluated just like a $(command)
substitution in POSIX shells:

  $ hg log -R a -r 8 -T '{"{"{rev}:{node|short}"}"}\n'
  8:95c24699272e
  $ hg log -R a -r 8 -T '{"{"\{{rev}} \"{node|short}\""}"}\n'
  {8} "95c24699272e"

Test get function:

  $ hg log -r 0 --template '{get(extras, "branch")}\n'
  default
  $ hg log -r 0 --template '{get(files, "should_fail")}\n'
  hg: parse error: get() expects a dict as first argument
  [255]

Test template string in pad function

  $ hg log -r 0 -T '{pad("\{{rev}}", 10)} {author|user}\n'
  {0}        test

  $ hg log -r 0 -T '{pad(r"\{rev}", 10)} {author|user}\n'
  \{rev}     test

  $ hg log --template '{revset("TIP"|lower)}\n' -l1
  2

Test active bookmark templating
  $ hg log --template "{rev} {bookmarks % '{bookmark}{ifeq(bookmark, active, \"*\")} '}\n"
  $ hg log --template "{rev} {activebookmark}\n"
  $ hg log --template "{rev} {activebookmark}\n"
  $ hg book -r1 baz
  $ hg log --template "{rev} {join(bookmarks, ' ')}\n"
  2 bar foo
  1 baz
  0 
  $ hg log --template "{rev} {ifcontains('foo', bookmarks, 't', 'f')}\n"
  2 t
  1 f
  0 f
  @  foo Modify, add, remove, rename
  |
  o  foo future
  |
  o
  @  add,
  |
  o
  @  M
  |
  o  future

Test word for integer literal

  $ hg log -R a --template "{word(2, desc)}\n" -r0
  line

Test word for invalid numbers

  $ hg log -Gv -R a --template "{word('a', desc)}"
  hg: parse error: word expects an integer index
  [255]

Test indent and not adding to empty lines

  $ hg log -T "-----\n{indent(desc, '>> ', ' > ')}\n" -r 0:1 -R a
  -----
   > line 1
  >> line 2
  -----
   > other 1
  >> other 2
  
  >> other 3

Test with non-strings like dates

  $ hg log -T "{indent(date, '   ')}\n" -r 2:3 -R a
     1200000.00
     1300000.00