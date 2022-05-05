self: super:

{
  ankiJapanesePatch = super.pkgs.writeTextFile {
    name = "anki_japanese_addon_dir.patch";
    text = ''
      diff --git a/reading.py b/reading.py
      index 0ff746e..207b459 100755
      --- a/reading.py
      +++ b/reading.py
      @@ -49,8 +49,6 @@ def mungeForPlatform(popen):
           if isWin:
               popen = [os.path.normpath(x) for x in popen]
               popen[0] += ".exe"
      -    elif not isMac:
      -        popen[0] += ".lin"
           return popen
       
       class MecabController(object):
      @@ -60,13 +58,11 @@ class MecabController(object):
       
           def setup(self):
               self.mecabCmd = mungeForPlatform(
      -            [os.path.join(supportDir, "mecab")] + mecabArgs + [
      +            ["${self.pkgs.mecab}/bin/mecab"] + mecabArgs + [
                       '-d', supportDir, '-r', os.path.join(supportDir, "mecabrc"),
                       '-u', os.path.join(supportDir, "user_dic.dic")])
               os.environ['DYLD_LIBRARY_PATH'] = supportDir
               os.environ['LD_LIBRARY_PATH'] = supportDir
      -        if not isWin:
      -            os.chmod(self.mecabCmd[0], 0o755)
       
           def ensureOpen(self):
               if not self.mecab:
      @@ -158,11 +154,9 @@ class KakasiController(object):
       
           def setup(self):
               self.kakasiCmd = mungeForPlatform(
      -            [os.path.join(supportDir, "kakasi")] + kakasiArgs)
      +            ["${self.pkgs.kakasi}/bin/kakasi"] + kakasiArgs)
               os.environ['ITAIJIDICT'] = os.path.join(supportDir, "itaijidict")
               os.environ['KANWADICT'] = os.path.join(supportDir, "kanwadict")
      -        if not isWin:
      -            os.chmod(self.kakasiCmd[0], 0o755)
       
           def ensureOpen(self):
               if not self.kakasi:
      diff --git a/bulkreading.py b/bulkreading.py
      index 76e8af4..16e6866 100755
      --- a/bulkreading.py
      +++ b/bulkreading.py
      @@ -11,6 +11,9 @@ from .reading import mecab, srcFields, dstFields
       from .notetypes import isJapaneseNoteType
       from aqt import mw
      
      +config = mw.addonManager.getConfig(__name__)
      +furiganaFieldSuffix = config['furiganaSuffix']
      +
       # Bulk updates
       ##########################################################################
      
      @@ -20,40 +23,26 @@ def regenerateReadings(nids):
           mw.progress.start()
           for nid in nids:
               note = mw.col.getNote(nid)
      +        fields = mw.col.models.fieldNames(note.model())
               # Amend notetypes.py to add your note types
               _noteName = note.model()['name'].lower()
               if not isJapaneseNoteType(_noteName):
                   continue
      -
      -        src = None
      -        for field in srcFields:
      -            if field in note:
      -                src = field
      -                break
      -        if not src:
      -            # no src field
      -            continue
      -        # dst is the destination field for the Readings
      -        dst = None
      -        for field in dstFields:
      -            if field in note:
      -                dst = field
      -                break
      -        if not dst:
      -            # no dst field
      -            continue
      -        if note[dst]:
      -            # already contains data, skip
      -            continue
      -        srcTxt = mw.col.media.strip(note[src])
      -        if not srcTxt.strip():
      -            continue
      -        try:
      -            note[dst] = mecab.reading(srcTxt)
      -        except Exception as e:
      -            mecab = None
      -            raise
      -        note.flush()
      +        for src in fields:
      +            # dst is the destination field for the Readings
      +            dst = src + furiganaFieldSuffix
      +            if dst not in note:
      +                # no dst field
      +                continue
      +            srcTxt = mw.col.media.strip(note[src])
      +            if not srcTxt.strip():
      +                continue
      +            try:
      +                note[dst] = mecab.reading(srcTxt)
      +            except Exception as e:
      +                mecab = None
      +                raise
      +            note.flush()
           mw.progress.finish()
           mw.reset()
    '';
  };
  ankiJapaneseExampleSentencesPatch = super.pkgs.writeTextFile {
    name = "anki_japanese_example_sentences_addon_dir.patch";
    text = ''
      diff --git a/japanese_examples.py b/japanese_examples.py
      index 00de486..818bc1b 100755
      --- a/japanese_examples.py
      +++ b/japanese_examples.py
      @@ -30,7 +30,7 @@ DST_FIELD_ENG = config["englishDstField"]
       
       dir_path = os.path.dirname(os.path.realpath(__file__))
       fname = os.path.join(dir_path, "japanese_examples.utf")
      -file_pickle = os.path.join(dir_path, "japanese_examples.pickle")
      +file_pickle = os.path.join("/tmp", "japanese_examples.pickle")
       f = open(fname, 'r', encoding='utf8')
       content = f.readlines()
       f.close()
      @@ -122,7 +122,7 @@ def weighted_sample(somelist, n):
       
       def find_examples(expression, maxitems):
           examples = []
      -
      +    expression = re.sub('する$', ''', expression)
           for dictionary in dictionaries:
               if expression in dictionary:
                   index = dictionary[expression]
      @@ -135,8 +135,6 @@ def find_examples(expression, maxitems):
                   maxitems -= len(index)
                   for j in index:
                       example = content[j].split("#ID=")[0][3:]
      -                if dictionary == dictionaries[0]:
      -                    example = example + " {CHECKED}"
                       example = example.replace(expression,'<FONT COLOR="#ff0000">%s</FONT>' %expression)
                       color_example = content[j+1]
                       regexp = r"(?:\(*%s\)*)(?:\([^\s]+?\))*(?:\[\d+\])*\{(.+?)\}" %expression
    '';
  };
}
