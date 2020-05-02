package tink.semver;

import tink.parse.*;

abstract Pos(IntIterator) from IntIterator to IntIterator {

  public var from(get, never):Int;
    inline function get_from() return @:privateAccess this.min;

  public var to(get, never):Int;
    inline function get_to() return @:privateAccess this.max;

}

private class Reporter implements tink.parse.Reporter.ReporterObject<Pos, Error> {

  var source:StringSlice;

  public function new(source)
    this.source = source;

  public function makeError(message: String, pos:Pos) {
    return new Error(
      '$message at ' +
      '"${source[pos]}"(${pos.from}-${pos.to})' +
      ' in "$source"'
    );
  }

  public function makePos(from, to)
    return from ... to;
}

class Parser extends ParserBase<Pos, Error> {

  override function doSkipIgnored()
    doReadWhile(Char.WHITE);

  function num() {
    return switch Std.parseInt(readWhile(Char.DIGIT)) {
      case null: -1;
      case v: v;
    }
  }

  public function new(s)
    super(s, new Reporter(s));

  inline function ident()
    return readWhile(Char.LOWER);

  static var OR(default, never):StringSlice = '||';
  static var DOT(default, never):StringSlice = '.';
  static var HYPHEN(default, never):StringSlice = '-';
  static var COMMA(default, never):StringSlice = ',';

  function lower(f:Version->Bound):Version->Constraint
    return function (v) return { min: f(v), max: Unbounded };

  function upper(f:Version->Bound):Version->Constraint
    return function (v) return { min: Unbounded, max: f(v) };

  function parseSimple(f:Version->Constraint):Constraint {

    var r = f(parseInlineVersion());

    while (!upNext('|'.code) && pos < max) {
      r = r && parseSingle();
    }

    return r;
  }

  public function parseConstraint():Constraint {
    var ret = parseSingle();
    while (allow(OR))
      ret = ret || parseSingle();
    return ret;
  }

  function carret(v:Version)
    return
      v...
        if (v.major == 0)
          if (v.minor == 0) v.nextPatch();
          else v.nextMinor();
        else v.nextMajor();

  function parseSingle():Constraint {
    skipIgnored();
    return
      if (allowHere('*')) null;
      else if (allowHere('>=')) parseSimple(lower(Inclusive));
      else if (allowHere('>')) parseSimple(lower(Exlusive));
      else if (allowHere('<=')) parseSimple(upper(Inclusive));
      else if (allowHere('<')) parseSimple(upper(Exlusive));
      else if (allowHere('=')) Constraint.exact(parseInlineVersion());
      else if (allowHere('^')) parseSimple(carret);
      else {
        var p = parsePartial();
        if (allow(HYPHEN))
          { min: Inclusive(full(p)), max: Inclusive(skipIgnored() + parseInlineVersion()) };
        else
          if (p.patch < 0) {
            var v = full(p, true);
            v ... if (p.minor < 0) v.nextMajor() else v.nextMinor();
          }
          else full(p);
      }
  }

  public function parseVersion() {
    var ret = parseInlineVersion();
    skipIgnored();
    return
      if (pos == max) ret;
      else die('Unexpected string', pos...max);
  }

  function numX()
    return
      if (allowHere('x') || allowHere('X') || allowHere('*')) -1;
      else num();

  function parsePartial():Partial {
    var start = pos;
    function next()
      return
        if (allowHere('.')) num();
        else -1;

    var major = num(),
        minor = next(),
        patch = next(),
        preview = null,
        previewNum = -1;

    if (patch >= 0 && allowHere(HYPHEN)) {
      preview = Preview.ofString(ident()).sure();
      if (allowHere(DOT)) previewNum = num();
    }

    return {
      major: major,
      minor: minor,
      patch: patch,
      preview: preview,
      previewNum: previewNum,
      pos: start...pos,
    }
  }
  function clamp(i:Int)
    return if (i < 0) 0 else i;
  function full(p:Partial, ?clamped:Bool) {

    if (clamped != true && p.patch < 0)
      die('Partial version not allowed', p.pos);

    var ret = new Version(p.major, clamp(p.minor), clamp(p.patch));

    return
      if (p.preview != null) ret.prerelease(p.preview, p.previewNum);
      else ret;
  }

  function parseInlineVersion() {
    return full(parsePartial());
  }

}

typedef Partial = {
  major:Int,
  minor:Int,
  patch:Int,
  preview:Preview,
  previewNum:Int,
  pos:IntIterator,
}