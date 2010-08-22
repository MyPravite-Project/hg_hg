  $ echo "invalid" > $HGRCPATH
  $ hg version 2>&1 | sed -e "s|$HGRCPATH|\$HGRCPATH|"
  hg: parse error at $HGRCPATH:1: invalid
  $ echo "" > $HGRCPATH

issue1199: escaping

  $ hg init "foo%bar"
  $ hg clone "foo%bar" foobar
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ p=`pwd`
  $ cd foobar
  $ cat .hg/hgrc | sed -e "s:$p:...:"
  [paths]
  default = .../foo%bar
  $ hg paths | sed -e "s:$p:...:"
  default = .../foo%bar
  $ hg showconfig | sed -e "s:$p:...:"
  bundle.mainreporoot=.../foobar
  paths.default=.../foo%bar
  $ cd ..

issue1829: wrong indentation

  $ echo '[foo]' > $HGRCPATH
  $ echo '  x = y' >> $HGRCPATH
  $ hg version 2>&1 | sed -e "s|$HGRCPATH|\$HGRCPATH|"
  hg: parse error at $HGRCPATH:2:   x = y

  $ python -c "print '[foo]\nbar = a\n b\n c \n  de\n fg \nbaz = bif cb \n'" \
  > > $HGRCPATH
  $ hg showconfig foo
  foo.bar=a\nb\nc\nde\nfg
  foo.baz=bif cb

  $ FAKEPATH=/path/to/nowhere
  $ export FAKEPATH
  $ echo '%include $FAKEPATH/no-such-file' > $HGRCPATH
  $ hg version 2>&1 | sed -e "s|$HGRCPATH|\$HGRCPATH|"
  hg: parse error at $HGRCPATH:1: cannot include /path/to/nowhere/no-such-file (No such file or directory)
  $ unset FAKEPATH

username expansion

  $ olduser=$HGUSER
  $ unset HGUSER

  $ FAKEUSER='John Doe'
  $ export FAKEUSER
  $ echo '[ui]' > $HGRCPATH
  $ echo 'username = $FAKEUSER' >> $HGRCPATH

  $ hg init usertest
  $ cd usertest
  $ touch bar
  $ hg commit --addremove --quiet -m "added bar"
  $ hg log --template "{author}\n"
  John Doe
  $ cd ..

  $ hg showconfig | sed -e "s:$p:...:"
  ui.username=$FAKEUSER

  $ unset FAKEUSER
  $ HGUSER=$olduser
  $ export HGUSER

HGPLAIN

  $ cd ..
  $ p=`pwd`
  $ echo "[ui]" > $HGRCPATH
  $ echo "debug=true" >> $HGRCPATH
  $ echo "fallbackencoding=ASCII" >> $HGRCPATH
  $ echo "quiet=true" >> $HGRCPATH
  $ echo "slash=true" >> $HGRCPATH
  $ echo "traceback=true" >> $HGRCPATH
  $ echo "verbose=true" >> $HGRCPATH
  $ echo "style=~/.hgstyle" >> $HGRCPATH
  $ echo "logtemplate={node}" >> $HGRCPATH
  $ echo "[defaults]" >> $HGRCPATH
  $ echo "identify=-n" >> $HGRCPATH
  $ echo "[alias]" >> $HGRCPATH
  $ echo "log=log -g" >> $HGRCPATH

customized hgrc

  $ hg showconfig | sed -e "s:$p:...:"
  read config from: .../.hgrc
  .../.hgrc:13: alias.log=log -g
  .../.hgrc:11: defaults.identify=-n
  .../.hgrc:2: ui.debug=true
  .../.hgrc:3: ui.fallbackencoding=ASCII
  .../.hgrc:4: ui.quiet=true
  .../.hgrc:5: ui.slash=true
  .../.hgrc:6: ui.traceback=true
  .../.hgrc:7: ui.verbose=true
  .../.hgrc:8: ui.style=~/.hgstyle
  .../.hgrc:9: ui.logtemplate={node}

plain hgrc

  $ HGPLAIN=; export HGPLAIN
  $ hg showconfig --config ui.traceback=True --debug | sed -e "s:$p:...:"
  read config from: .../.hgrc
  none: ui.traceback=True
  none: ui.verbose=False
  none: ui.debug=True
  none: ui.quiet=False
