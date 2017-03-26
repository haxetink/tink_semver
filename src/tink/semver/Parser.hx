package tink.semver;

import tink.parse.*;

abstract Pos(IntIterator) from IntIterator to IntIterator {
    
  public var from(get, never):Int;
    inline function get_from() return @:privateAccess this.min;
  
  public var to(get, never):Int;
    inline function get_to() return @:privateAccess this.max;
  
}

class Parser extends ParserBase<Pos, Error> {

  override function doSkipIgnored() 
    doReadWhile(Char.WHITE); 

  inline function num() 
    return Std.parseInt(readWhile(Char.DIGIT));

  inline function ident() 
    return readWhile(Char.LOWER);

  static var OR(default, never):StringSlice = '||';
  static var DOT(default, never):StringSlice = '.';
  static var DASH(default, never):StringSlice = '-';
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
      else if (allowHere('>=')) parseSimple(lower(Closed));
      else if (allowHere('>')) parseSimple(lower(Open));
      else if (allowHere('<=')) parseSimple(upper(Closed));
      else if (allowHere('<')) parseSimple(upper(Open));
      else if (allowHere('=')) Constraint.exact(parseInlineVersion());
      else if (allowHere('^')) parseSimple(carret);
      else {
        var v = parseInlineVersion();
        if (allow(DASH)) 
          Constraint.range(v, skipIgnored() + parseInlineVersion());
        else
          v;
      }
  }

  public function parseVersion() {
    var ret = parseInlineVersion();
    skipIgnored();
    return
      if (pos == max) ret;
      else die('Unexpected string', pos...max);
  }

  function parseInlineVersion() {
    var ret = new Version(num(), expectHere(DOT) + num(), expectHere(DOT) + num());
    return
      if (allowHere(DASH)) ret.prerelease(
        Preview.ofString(ident()).sure(),
        if (allowHere(DOT)) num() else -1
      );
      else ret;
  }

  override function makeError(message: String, pos:Pos) {
    return new Error(
      '$message at ' +
      '"${source[pos]}"(${pos.from}-${pos.to})' +
      ' in "$source"'
    );
  }
  
  override function doMakePos(from, to)
    return from ... to;
}