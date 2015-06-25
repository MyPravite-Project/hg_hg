import collections
import cStringIO, email, os, errno, re, posixpath, copy
import pathutil

    if parents:
        p1 = parents.pop(0)
    else:
        p1 = None

    if parents:
        p2 = parents.pop(0)
    else:
        p2 = None

        islink = mode & 0o20000
        isexec = mode & 0o100
            isexec = self.opener.lstat(fname).st_mode & 0o100 != 0
        except OSError as e:
        except IOError as e:
        for fuzzlen in xrange(self.ui.configint("patch", "fuzz", 2) + 1):
class header(object):
    """patch header
    """
    diffgit_re = re.compile('diff --git a/(.*) b/(.*)$')
    diff_re = re.compile('diff -r .* (.*)$')
    allhunks_re = re.compile('(?:index|deleted file) ')
    pretty_re = re.compile('(?:new file|deleted file) ')
    special_re = re.compile('(?:index|deleted|copy|rename) ')
    newfile_re = re.compile('(?:new file)')

    def __init__(self, header):
        self.header = header
        self.hunks = []

    def binary(self):
        return any(h.startswith('index ') for h in self.header)

    def pretty(self, fp):
        for h in self.header:
            if h.startswith('index '):
                fp.write(_('this modifies a binary file (all or nothing)\n'))
                break
            if self.pretty_re.match(h):
                fp.write(h)
                if self.binary():
                    fp.write(_('this is a binary file\n'))
                break
            if h.startswith('---'):
                fp.write(_('%d hunks, %d lines changed\n') %
                         (len(self.hunks),
                          sum([max(h.added, h.removed) for h in self.hunks])))
                break
            fp.write(h)

    def write(self, fp):
        fp.write(''.join(self.header))

    def allhunks(self):
        return any(self.allhunks_re.match(h) for h in self.header)

    def files(self):
        match = self.diffgit_re.match(self.header[0])
        if match:
            fromfile, tofile = match.groups()
            if fromfile == tofile:
                return [fromfile]
            return [fromfile, tofile]
        else:
            return self.diff_re.match(self.header[0]).groups()

    def filename(self):
        return self.files()[-1]

    def __repr__(self):
        return '<header %s>' % (' '.join(map(repr, self.files())))

    def isnewfile(self):
        return any(self.newfile_re.match(h) for h in self.header)

    def special(self):
        # Special files are shown only at the header level and not at the hunk
        # level for example a file that has been deleted is a special file.
        # The user cannot change the content of the operation, in the case of
        # the deleted file he has to take the deletion or not take it, he
        # cannot take some of it.
        # Newly added files are special if they are empty, they are not special
        # if they have some content as we want to be able to change it
        nocontent = len(self.header) == 2
        emptynewfile = self.isnewfile() and nocontent
        return emptynewfile or \
                any(self.special_re.match(h) for h in self.header)

class recordhunk(object):
    """patch hunk

    XXX shouldn't we merge this with the other hunk class?
    """
    maxcontext = 3

    def __init__(self, header, fromline, toline, proc, before, hunk, after):
        def trimcontext(number, lines):
            delta = len(lines) - self.maxcontext
            if False and delta > 0:
                return number + delta, lines[:self.maxcontext]
            return number, lines

        self.header = header
        self.fromline, self.before = trimcontext(fromline, before)
        self.toline, self.after = trimcontext(toline, after)
        self.proc = proc
        self.hunk = hunk
        self.added, self.removed = self.countchanges(self.hunk)

    def __eq__(self, v):
        if not isinstance(v, recordhunk):
            return False

        return ((v.hunk == self.hunk) and
                (v.proc == self.proc) and
                (self.fromline == v.fromline) and
                (self.header.files() == v.header.files()))

    def __hash__(self):
        return hash((tuple(self.hunk),
            tuple(self.header.files()),
            self.fromline,
            self.proc))

    def countchanges(self, hunk):
        """hunk -> (n+,n-)"""
        add = len([h for h in hunk if h[0] == '+'])
        rem = len([h for h in hunk if h[0] == '-'])
        return add, rem

    def write(self, fp):
        delta = len(self.before) + len(self.after)
        if self.after and self.after[-1] == '\\ No newline at end of file\n':
            delta -= 1
        fromlen = delta + self.removed
        tolen = delta + self.added
        fp.write('@@ -%d,%d +%d,%d @@%s\n' %
                 (self.fromline, fromlen, self.toline, tolen,
                  self.proc and (' ' + self.proc)))
        fp.write(''.join(self.before + self.hunk + self.after))

    pretty = write

    def filename(self):
        return self.header.filename()

    def __repr__(self):
        return '<hunk %r@%d>' % (self.filename(), self.fromline)

def filterpatch(ui, headers, operation=None):
    """Interactively filter patch chunks into applied-only chunks"""
    if operation is None:
        operation = _('record')

    def prompt(skipfile, skipall, query, chunk):
        """prompt query, and process base inputs

        - y/n for the rest of file
        - y/n for the rest
        - ? (help)
        - q (quit)

        Return True/False and possibly updated skipfile and skipall.
        """
        newpatches = None
        if skipall is not None:
            return skipall, skipfile, skipall, newpatches
        if skipfile is not None:
            return skipfile, skipfile, skipall, newpatches
        while True:
            resps = _('[Ynesfdaq?]'
                      '$$ &Yes, record this change'
                      '$$ &No, skip this change'
                      '$$ &Edit this change manually'
                      '$$ &Skip remaining changes to this file'
                      '$$ Record remaining changes to this &file'
                      '$$ &Done, skip remaining changes and files'
                      '$$ Record &all changes to all remaining files'
                      '$$ &Quit, recording no changes'
                      '$$ &? (display help)')
            r = ui.promptchoice("%s %s" % (query, resps))
            ui.write("\n")
            if r == 8: # ?
                for c, t in ui.extractchoices(resps)[1]:
                    ui.write('%s - %s\n' % (c, t.lower()))
                continue
            elif r == 0: # yes
                ret = True
            elif r == 1: # no
                ret = False
            elif r == 2: # Edit patch
                if chunk is None:
                    ui.write(_('cannot edit patch for whole file'))
                    ui.write("\n")
                    continue
                if chunk.header.binary():
                    ui.write(_('cannot edit patch for binary file'))
                    ui.write("\n")
                    continue
                # Patch comment based on the Git one (based on comment at end of
                # http://mercurial.selenic.com/wiki/RecordExtension)
                phelp = '---' + _("""
To remove '-' lines, make them ' ' lines (context).
To remove '+' lines, delete them.
Lines starting with # will be removed from the patch.

If the patch applies cleanly, the edited hunk will immediately be
added to the record list. If it does not apply cleanly, a rejects
file will be generated: you can use that when you try again. If
all lines of the hunk are removed, then the edit is aborted and
the hunk is left unchanged.
""")
                (patchfd, patchfn) = tempfile.mkstemp(prefix="hg-editor-",
                        suffix=".diff", text=True)
                ncpatchfp = None
                try:
                    # Write the initial patch
                    f = os.fdopen(patchfd, "w")
                    chunk.header.write(f)
                    chunk.write(f)
                    f.write('\n'.join(['# ' + i for i in phelp.splitlines()]))
                    f.close()
                    # Start the editor and wait for it to complete
                    editor = ui.geteditor()
                    ret = ui.system("%s \"%s\"" % (editor, patchfn),
                                    environ={'HGUSER': ui.username()})
                    if ret != 0:
                        ui.warn(_("editor exited with exit code %d\n") % ret)
                        continue
                    # Remove comment lines
                    patchfp = open(patchfn)
                    ncpatchfp = cStringIO.StringIO()
                    for line in patchfp:
                        if not line.startswith('#'):
                            ncpatchfp.write(line)
                    patchfp.close()
                    ncpatchfp.seek(0)
                    newpatches = parsepatch(ncpatchfp)
                finally:
                    os.unlink(patchfn)
                    del ncpatchfp
                # Signal that the chunk shouldn't be applied as-is, but
                # provide the new patch to be used instead.
                ret = False
            elif r == 3: # Skip
                ret = skipfile = False
            elif r == 4: # file (Record remaining)
                ret = skipfile = True
            elif r == 5: # done, skip remaining
                ret = skipall = False
            elif r == 6: # all
                ret = skipall = True
            elif r == 7: # quit
                raise util.Abort(_('user quit'))
            return ret, skipfile, skipall, newpatches

    seen = set()
    applied = {}        # 'filename' -> [] of chunks
    skipfile, skipall = None, None
    pos, total = 1, sum(len(h.hunks) for h in headers)
    for h in headers:
        pos += len(h.hunks)
        skipfile = None
        fixoffset = 0
        hdr = ''.join(h.header)
        if hdr in seen:
            continue
        seen.add(hdr)
        if skipall is None:
            h.pretty(ui)
        msg = (_('examine changes to %s?') %
               _(' and ').join("'%s'" % f for f in h.files()))
        r, skipfile, skipall, np = prompt(skipfile, skipall, msg, None)
        if not r:
            continue
        applied[h.filename()] = [h]
        if h.allhunks():
            applied[h.filename()] += h.hunks
            continue
        for i, chunk in enumerate(h.hunks):
            if skipfile is None and skipall is None:
                chunk.pretty(ui)
            if total == 1:
                msg = _("record this change to '%s'?") % chunk.filename()
            else:
                idx = pos - len(h.hunks) + i
                msg = _("record change %d/%d to '%s'?") % (idx, total,
                                                           chunk.filename())
            r, skipfile, skipall, newpatches = prompt(skipfile,
                    skipall, msg, chunk)
            if r:
                if fixoffset:
                    chunk = copy.copy(chunk)
                    chunk.toline += fixoffset
                applied[chunk.filename()].append(chunk)
            elif newpatches is not None:
                for newpatch in newpatches:
                    for newhunk in newpatch.hunks:
                        if fixoffset:
                            newhunk.toline += fixoffset
                        applied[newhunk.filename()].append(newhunk)
            else:
                fixoffset += chunk.removed - chunk.added
    return sum([h for h in applied.itervalues()
               if h[0].special() or len(h) > 1], [])
            except ValueError as e:
def reversehunks(hunks):
    '''reverse the signs in the hunks given as argument

    This function operates on hunks coming out of patch.filterpatch, that is
    a list of the form: [header1, hunk1, hunk2, header2...]. Example usage:

    >>> rawpatch = """diff --git a/folder1/g b/folder1/g
    ... --- a/folder1/g
    ... +++ b/folder1/g
    ... @@ -1,7 +1,7 @@
    ... +firstline
    ...  c
    ...  1
    ...  2
    ... + 3
    ... -4
    ...  5
    ...  d
    ... +lastline"""
    >>> hunks = parsepatch(rawpatch)
    >>> hunkscomingfromfilterpatch = []
    >>> for h in hunks:
    ...     hunkscomingfromfilterpatch.append(h)
    ...     hunkscomingfromfilterpatch.extend(h.hunks)

    >>> reversedhunks = reversehunks(hunkscomingfromfilterpatch)
    >>> fp = cStringIO.StringIO()
    >>> for c in reversedhunks:
    ...      c.write(fp)
    >>> fp.seek(0)
    >>> reversedpatch = fp.read()
    >>> print reversedpatch
    diff --git a/folder1/g b/folder1/g
    --- a/folder1/g
    +++ b/folder1/g
    @@ -1,4 +1,3 @@
    -firstline
     c
     1
     2
    @@ -1,6 +2,6 @@
     c
     1
     2
    - 3
    +4
     5
     d
    @@ -5,3 +6,2 @@
     5
     d
    -lastline

    '''

    import crecord as crecordmod
    newhunks = []
    for c in hunks:
        if isinstance(c, crecordmod.uihunk):
            # curses hunks encapsulate the record hunk in _hunk
            c = c._hunk
        if isinstance(c, recordhunk):
            for j, line in enumerate(c.hunk):
                if line.startswith("-"):
                    c.hunk[j] = "+" + c.hunk[j][1:]
                elif line.startswith("+"):
                    c.hunk[j] = "-" + c.hunk[j][1:]
            c.added, c.removed = c.removed, c.added
        newhunks.append(c)
    return newhunks

def parsepatch(originalchunks):
    """patch -> [] of headers -> [] of hunks """
    class parser(object):
        """patch parsing state machine"""
        def __init__(self):
            self.fromline = 0
            self.toline = 0
            self.proc = ''
            self.header = None
            self.context = []
            self.before = []
            self.hunk = []
            self.headers = []

        def addrange(self, limits):
            fromstart, fromend, tostart, toend, proc = limits
            self.fromline = int(fromstart)
            self.toline = int(tostart)
            self.proc = proc

        def addcontext(self, context):
            if self.hunk:
                h = recordhunk(self.header, self.fromline, self.toline,
                        self.proc, self.before, self.hunk, context)
                self.header.hunks.append(h)
                self.fromline += len(self.before) + h.removed
                self.toline += len(self.before) + h.added
                self.before = []
                self.hunk = []
                self.proc = ''
            self.context = context

        def addhunk(self, hunk):
            if self.context:
                self.before = self.context
                self.context = []
            self.hunk = hunk

        def newfile(self, hdr):
            self.addcontext([])
            h = header(hdr)
            self.headers.append(h)
            self.header = h

        def addother(self, line):
            pass # 'other' lines are ignored

        def finished(self):
            self.addcontext([])
            return self.headers

        transitions = {
            'file': {'context': addcontext,
                     'file': newfile,
                     'hunk': addhunk,
                     'range': addrange},
            'context': {'file': newfile,
                        'hunk': addhunk,
                        'range': addrange,
                        'other': addother},
            'hunk': {'context': addcontext,
                     'file': newfile,
                     'range': addrange},
            'range': {'context': addcontext,
                      'hunk': addhunk},
            'other': {'other': addother},
            }

    p = parser()
    fp = cStringIO.StringIO()
    fp.write(''.join(originalchunks))
    fp.seek(0)

    state = 'context'
    for newstate, data in scanpatch(fp):
        try:
            p.transitions[state][newstate](p, data)
        except KeyError:
            raise PatchError('unhandled transition: %s -> %s' %
                                   (state, newstate))
        state = newstate
    del fp
    return p.finished()

def pathtransform(path, strip, prefix):
    '''turn a path from a patch into a path suitable for the repository

    prefix, if not empty, is expected to be normalized with a / at the end.

    Returns (stripped components, path in repository).

    >>> pathtransform('a/b/c', 0, '')
    ('', 'a/b/c')
    >>> pathtransform('   a/b/c   ', 0, '')
    ('', '   a/b/c')
    >>> pathtransform('   a/b/c   ', 2, '')
    ('a/b/', 'c')
    >>> pathtransform('a/b/c', 0, 'd/e/')
    ('', 'd/e/a/b/c')
    >>> pathtransform('   a//b/c   ', 2, 'd/e/')
    ('a//b/', 'd/e/c')
    >>> pathtransform('a/b/c', 3, '')
    Traceback (most recent call last):
    PatchError: unable to strip away 1 of 3 dirs from a/b/c
    '''
        return '', prefix + path.rstrip()
    return path[:i].lstrip(), prefix + path[i:].rstrip()
def makepatchmeta(backend, afile_orig, bfile_orig, hunk, strip, prefix):
    abase, afile = pathtransform(afile_orig, strip, prefix)
    bbase, bfile = pathtransform(bfile_orig, strip, prefix)
            if isbackup:
                fname = afile
            else:
                fname = bfile
            if isbackup:
                fname = afile
            else:
                fname = bfile
def scanpatch(fp):
    """like patch.iterhunks, but yield different events

    - ('file',    [header_lines + fromfile + tofile])
    - ('context', [context_lines])
    - ('hunk',    [hunk_lines])
    - ('range',   (-start,len, +start,len, proc))
    """
    lines_re = re.compile(r'@@ -(\d+),(\d+) \+(\d+),(\d+) @@\s*(.*)')
    lr = linereader(fp)

    def scanwhile(first, p):
        """scan lr while predicate holds"""
        lines = [first]
        while True:
            line = lr.readline()
            if not line:
                break
            if p(line):
                lines.append(line)
            else:
                lr.push(line)
                break
        return lines

    while True:
        line = lr.readline()
        if not line:
            break
        if line.startswith('diff --git a/') or line.startswith('diff -r '):
            def notheader(line):
                s = line.split(None, 1)
                return not s or s[0] not in ('---', 'diff')
            header = scanwhile(line, notheader)
            fromfile = lr.readline()
            if fromfile.startswith('---'):
                tofile = lr.readline()
                header += [fromfile, tofile]
            else:
                lr.push(fromfile)
            yield 'file', header
        elif line[0] == ' ':
            yield 'context', scanwhile(line, lambda l: l[0] in ' \\')
        elif line[0] in '-+':
            yield 'hunk', scanwhile(line, lambda l: l[0] in '-+\\')
        else:
            m = lines_re.match(line)
            if m:
                yield 'range', m.groups()
            else:
                yield 'other', line

def applydiff(ui, fp, backend, store, strip=1, prefix='', eolmode='strict'):
                      prefix=prefix, eolmode=eolmode)
def _applydiff(ui, fp, patcher, backend, store, strip=1, prefix='',
    if prefix:
        prefix = pathutil.canonpath(backend.repo.root, backend.repo.getcwd(),
                                    prefix)
        if prefix != '':
            prefix += '/'
        return pathtransform(p, strip - 1, prefix)[1]
                gp = makepatchmeta(backend, afile, bfile, first_hunk, strip,
                                   prefix)
            except PatchError as inst:
def patchbackend(ui, backend, patchobj, strip, prefix, files=None,
                 eolmode='strict'):
        ret = applydiff(ui, fp, backend, store, strip=strip, prefix=prefix,
def internalpatch(ui, repo, patchobj, strip, prefix='', files=None,
                  eolmode='strict', similarity=0):
    return patchbackend(ui, backend, patchobj, strip, prefix, files, eolmode)
def patchrepo(ui, repo, ctx, store, patchobj, strip, prefix, files=None,
    return patchbackend(ui, backend, patchobj, strip, prefix, files, eolmode)
def patch(ui, repo, patchname, strip=1, prefix='', files=None, eolmode='strict',
    return internalpatch(ui, repo, patchname, strip, prefix, files, eolmode,
                    gp.path = pathtransform(gp.path, strip - 1, '')[1]
                        gp.oldpath = pathtransform(gp.oldpath, strip - 1, '')[1]
                    gp = makepatchmeta(backend, afile, bfile, first_hunk, strip,
                                       '')
def diffallopts(ui, opts=None, untrusted=False, section='diff'):
    '''return diffopts with all features supported and parsed'''
    return difffeatureopts(ui, opts=opts, untrusted=untrusted, section=section,
                           git=True, whitespace=True, formatchanging=True)

diffopts = diffallopts

def difffeatureopts(ui, opts=None, untrusted=False, section='diff', git=False,
                    whitespace=False, formatchanging=False):
    '''return diffopts with only opted-in features parsed

    Features:
    - git: git-style diffs
    - whitespace: whitespace options like ignoreblanklines and ignorews
    - formatchanging: options that will likely break or cause correctness issues
      with most diff parsers
    '''
    def get(key, name=None, getter=ui.configbool, forceplain=None):
        if opts:
            v = opts.get(key)
            if v:
                return v
        if forceplain is not None and ui.plain():
            return forceplain
        return getter(section, name or key, None, untrusted=untrusted)

    # core options, expected to be understood by every diff parser
    buildopts = {
        'nodates': get('nodates'),
        'showfunc': get('show_function', 'showfunc'),
        'context': get('unified', getter=ui.config),
    }

    if git:
        buildopts['git'] = get('git')
    if whitespace:
        buildopts['ignorews'] = get('ignore_all_space', 'ignorews')
        buildopts['ignorewsamount'] = get('ignore_space_change',
                                          'ignorewsamount')
        buildopts['ignoreblanklines'] = get('ignore_blank_lines',
                                            'ignoreblanklines')
    if formatchanging:
        buildopts['text'] = opts and opts.get('text')
        buildopts['nobinary'] = get('nobinary')
        buildopts['noprefix'] = get('noprefix', forceplain=False)

    return mdiff.diffopts(**buildopts)
         losedatafn=None, prefix='', relroot=''):

    relroot, if not empty, must be normalized with a trailing /. Any match
    patterns that fall outside it will be ignored.'''
        order = collections.deque()
    relfiltered = False
    if relroot != '' and match.always():
        # as a special case, create a new matcher with just the relroot
        pats = [relroot]
        match = scmutil.match(ctx2, pats, default='path')
        relfiltered = True

    if repo.ui.debugflag:
        hexfunc = hex
    else:
        hexfunc = short
        copy = copies.pathcopies(ctx1, ctx2, match=match)

    if relroot is not None:
        if not relfiltered:
            # XXX this would ideally be done in the matcher, but that is
            # generally meant to 'or' patterns, not 'and' them. In this case we
            # need to 'and' all the patterns from the matcher with relroot.
            def filterrel(l):
                return [f for f in l if f.startswith(relroot)]
            modified = filterrel(modified)
            added = filterrel(added)
            removed = filterrel(removed)
            relfiltered = True
        # filter out copies where either side isn't inside the relative root
        copy = dict(((dst, src) for (dst, src) in copy.iteritems()
                     if dst.startswith(relroot)
                     and src.startswith(relroot)))
                       copy, getfilectx, opts, losedata, prefix, relroot)
def _filepairs(ctx1, modified, added, removed, copy, opts):
    '''generates tuples (f1, f2, copyop), where f1 is the name of the file
    before and f2 is the the name after. For added files, f1 will be None,
    and for removed files, f2 will be None. copyop may be set to None, 'copy'
    or 'rename' (the latter two only if opts.git is set).'''
    gone = set()

    copyto = dict([(v, k) for k, v in copy.items()])

    addedset, removedset = set(added), set(removed)
    # Fix up  added, since merged-in additions appear as
    # modifications during merges
    for f in modified:
        if f not in ctx1:
            addedset.add(f)

    for f in sorted(modified + added + removed):
        copyop = None
        f1, f2 = f, f
        if f in addedset:
            f1 = None
            if f in copy:
                if opts.git:
                    f1 = copy[f]
                    if f1 in removedset and f1 not in gone:
                        copyop = 'rename'
                        gone.add(f1)
                    else:
                        copyop = 'copy'
        elif f in removedset:
            f2 = None
            if opts.git:
                # have we already reported a copy above?
                if (f in copyto and copyto[f] in addedset
                    and copy[copyto[f]] == f):
                    continue
        yield f1, f2, copyop

            copy, getfilectx, opts, losedatafn, prefix, relroot):
    '''given input data, generate a diff and yield it in blocks
    If generating a diff would lose data like flags or binary data and
    losedatafn is not None, it will be called.
    relroot is removed and prefix is added to every path in the diff output.
    If relroot is not empty, this function expects every path in modified,
    added, removed and copy to start with it.'''
    if opts.noprefix:
        aprefix = bprefix = ''
    else:
        aprefix = 'a/'
        bprefix = 'b/'

    def diffline(f, revs):
        revinfo = ' '.join(["-r %s" % rev for rev in revs])
        return 'diff %s %s' % (revinfo, f)
    date2 = util.datestr(ctx2.date())
    if relroot != '' and (repo.ui.configbool('devel', 'all')
                          or repo.ui.configbool('devel', 'check-relroot')):
        for f in modified + added + removed + copy.keys() + copy.values():
            if f is not None and not f.startswith(relroot):
                raise AssertionError(
                    "file %s doesn't start with relroot %s" % (f, relroot))

    for f1, f2, copyop in _filepairs(
            ctx1, modified, added, removed, copy, opts):
        content1 = None
        content2 = None
        flag1 = None
        flag2 = None
        if f1:
            content1 = getfilectx(f1, ctx1).data()
            if opts.git or losedatafn:
                flag1 = ctx1.flags(f1)
        if f2:
            content2 = getfilectx(f2, ctx2).data()
            if opts.git or losedatafn:
                flag2 = ctx2.flags(f2)
        binary = False
            binary = util.binary(content1) or util.binary(content2)

        if losedatafn and not opts.git:
            if (binary or
                # copy/rename
                f2 in copy or
                # empty file creation
                (not f1 and not content2) or
                # empty file deletion
                (not content1 and not f2) or
                # create with flags
                (not f1 and flag2) or
                # change flags
                (f1 and f2 and flag1 != flag2)):
                losedatafn(f2 or f1)

        path1 = f1 or f2
        path2 = f2 or f1
        path1 = posixpath.join(prefix, path1[len(relroot):])
        path2 = posixpath.join(prefix, path2[len(relroot):])
        header = []
        if opts.git:
            header.append('diff --git %s%s %s%s' %
                          (aprefix, path1, bprefix, path2))
            if not f1: # added
                header.append('new file mode %s' % gitmode[flag2])
            elif not f2: # removed
                header.append('deleted file mode %s' % gitmode[flag1])
            else:  # modified/copied/renamed
                mode1, mode2 = gitmode[flag1], gitmode[flag2]
                if mode1 != mode2:
                    header.append('old mode %s' % mode1)
                    header.append('new mode %s' % mode2)
                if copyop is not None:
                    header.append('%s from %s' % (copyop, path1))
                    header.append('%s to %s' % (copyop, path2))
        elif revs and not repo.ui.quiet:
            header.append(diffline(path1, revs))

        if binary and opts.git and not opts.nobinary:
            text = mdiff.b85diff(content1, content2)
                header.append('index %s..%s' %
                              (gitindex(content1), gitindex(content2)))
        else:
            text = mdiff.unidiff(content1, date1,
                                 content2, date2,
                                 path1, path2, opts=opts)
        if header and (text or len(header) > 1):
            yield '\n'.join(header) + '\n'
        if text:
            yield text