package tink.semver;

using Std;

abstract Version(Data) from Data {

  public var major(get, never):Int;
    inline function get_major()
      return this.major;

  public var minor(get, never):Int;
    inline function get_minor()
      return this.minor;

  public var patch(get, never):Int;
    inline function get_patch()
      return this.patch;

  public var preview(get, never):Null<Preview>;
    inline function get_preview()
      return this.preview;

  public var previewNum(get, never):Null<Int>;
    inline function get_previewNum()
      return this.previewNum;

  public function new(major:Int, ?minor:Int = 0, ?patch:Int = 0)
    this = new Data(major, minor, patch);

  public inline function prerelease(kind:Preview, ?num:Int):Version
    return new Data(this.major, this.minor, this.patch, kind, num);

  public inline function alpha(?num:Int):Version
    return prerelease(ALPHA, num);

  public inline function beta(?num:Int):Version
    return prerelease(BETA, num);

  public inline function rc(?num:Int):Version
    return prerelease(RC, num);

  public function stable():Version
    return new Data(this.major, this.minor, this.patch);

  public function nextMajor():Version
    return new Data(this.major + 1, 0, 0);

  public function nextMinor():Version
    return new Data(this.major, this.minor + 1, 0);

  public function nextPatch():Version
    return new Data(this.major, this.minor, this.patch + 1);

  public function compare(that:Version):Comparison
    return
      cmp(this.major, that.major)
      > cmp(this.minor, that.minor)
      > cmp(this.patch, that.patch)
      > cmp(idx(this.preview), idx(that.preview))
      > cmp(this.previewNum, that.previewNum);

  inline function cmp(a:Int, b:Int):Comparison
    return a - b;

  function idx(p:Null<Preview>)
    return switch p {
      case null: 100;
      case ALPHA: 1;
      case BETA: 2;
      case RC: 3;
    }

  @:op(a == b) static function eq(a:Version, b:Version)
    return a.compare(b) == IsEqual;

  @:op(a != b) static function neq(a:Version, b:Version)
    return a.compare(b) != IsEqual;

  @:op(a > b) static function gt(a:Version, b:Version)
    return a.compare(b) == IsGreater;

  @:op(a < b) static function lt(a:Version, b:Version)
    return a.compare(b) == IsLess;

  @:op(a >= b) static function gte(a:Version, b:Version)
    return a.compare(b) != IsLess;

  @:op(a <= b) static function lte(a:Version, b:Version)
    return a.compare(b) != IsGreater;

  @:op(a...b) static function range(a:Version, b:Version)
    return
      Constraint.range(a, b);

  static public function parse(s:String):Outcome<Version, Error>
    return
      new Parser(s).parseVersion
        .catchExceptions(reportError);

  static public function reportError(d:Dynamic):Error
    return
      if (Std.is(d, String))
        new Error(UnprocessableEntity, (d : String));
      else
        Error.withData(UnprocessableEntity, Std.string(d), d);

  @:to
  public inline function toString():String
    return this.toString();

  #if tink_stringly
  @:from
  static inline public function fromStringly(v:tink.Stringly)
    return parse(v).sure();

  @:to
  public inline function toStringly():tink.Stringly
    return this.toString();
  #end

  #if tink_json
  @:from
  public static inline function fromRepresentation(rep:tink.json.Representation<String>):Version
    return parse(rep.get()).sure();

  @:to
  public inline function toRepresentation():tink.json.Representation<String>
    return new tink.json.Representation(this.toString());
  #end
}

private class Data {

  public var major(default, null):Int;
  public var minor(default, null):Int;
  public var patch(default, null):Int;

  public var preview(default, null):Null<Preview>;
  public var previewNum(default, null):Int;

  public function new(major, minor, patch, ?preview, ?previewNum = -1) {
    if (major < 0 || minor < 0 || patch < 0) throw 'version components must not be negative';
    this.major = major;
    this.minor = minor;
    this.patch = patch;
    this.preview = preview;
    this.previewNum = previewNum;
  }

  @:keep public function toString() {
    var ret = '$major.$minor.$patch';
    if (preview != null) {
      ret += '-$preview';
      if (previewNum != -1)
        ret += '.$previewNum';
    }
    return ret;
  }
}

@:enum abstract Comparison(Int) to Int {
  var IsGreater = 1;
  var IsEqual = 0;
  var IsLess = -1;

  @:to inline function toBool():Bool
    return this == IsEqual;

  @:from static inline function fromInt(i:Int)
    return fromFloat(i);

  @:from static inline function fromFloat(f:Float)
    return
      if (f > 0) IsGreater;
      else if (f < 0) IsLess;
      else IsEqual;

  @:op(a > b) static function chain(a:Comparison, b:Comparison)
    return
      if (a == IsEqual) b;
      else a;

}