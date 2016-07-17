package tink.semver;

import tink.semver.Constraint;

using Std;
using tink.CoreApi;

@:forward(toString)
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
	
	public function alpha(?num:Int):Version	
		return new Data(this.major, this.minor, this.patch, ALPHA, num);
		
	public function beta(?num:Int):Version	
		return new Data(this.major, this.minor, this.patch, BETA, num);
		
	public function rc(?num:Int):Version	
		return new Data(this.major, this.minor, this.patch, RC, num);
		
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
			((this.major - that.major) : Comparison) 
			>> ((this.minor - that.minor) : Comparison) 
			>> ((this.patch - that.patch) : Comparison);
	
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
			ConstraintData.And(Gt(a, OrEqual), Lt(b, Strictly));
			
	static public function parse(s:String)
		return 
			(function () return (Data.parse(s) : Version)).catchExceptions(reportError);
	
	static public function reportError(d:Dynamic):Error 
		return 
			if (Std.is(d, String))
				new Error(UnprocessableEntity, (d : String));
			else
				Error.withData(UnprocessableEntity, Std.string(d), d);
}

private class Data {
	static var FORMAT = ~/^([0-9]+)\.([0-9]+)\.([0-9]+)(-(alpha|beta|rc)(\.([0-9]+))?)?$/;
	
	static public function parse(s:String) {
		s = Std.string(s);
		
		if (!FORMAT.match(s))
			throw '$s is not a valid version string';
		
		return new Data(
			FORMAT.matched(1).parseInt(),
			FORMAT.matched(2).parseInt(),
			FORMAT.matched(3).parseInt(),
			switch FORMAT.matched(5) {
				case 'alpha': ALPHA;
				case 'beta': BETA;
				case 'rc': RC;
				case v if (v == null): null;
				case v: throw 'unrecognized preview tag $v';
			},
			switch FORMAT.matched(7) {
				case null: null;
				case v: v.parseInt();
			}
		);
	}
	
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):Int;
	
	public var preview(default, null):Null<Preview>;
	public var previewNum(default, null):Null<Int>;
	
	public function new(major, minor, patch, ?preview, ?previewNum) {
		this.major = major;
		this.minor = minor;
		this.patch = patch;
		this.preview = preview;
		this.previewNum = previewNum;
	}
	
	public function toString() {
		var ret = '$major.$minor.$patch';
		if (preview != null) {
			ret += '-$preview';
			if (previewNum != null)
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
	
	@:op(a >> b) static function chain(a:Comparison, b:Comparison)
		return
			if (a == IsEqual) b;
			else a;
	
}