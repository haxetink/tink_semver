# Tinkerbell Semantic Versioning

This library aims to provide an implementation of a superset of SemVer 1 and a subset of SemVer 2. It does follow SemVer 2 by adding support for prerelease notation, however it is restricted to either `alpha`, `beta` or `rc` with an optional prerelease counter. Examples:

```
1.2.3
1.2.3-alpha
1.2.3-beta
1.2.3-rc
1.2.3-rc.3
//invalid:
1.2.3-gamma
1.2.3-rc.3.5
```

The restriction was chosen based on the fact that `alpha`, `beta` and `rc` have a [relatively established upon meaning](https://en.wikipedia.org/wiki/Software_release_life_cycle). Thus `1.2.3-rc.2` is easily understood by anyone, while `1.2.3-banana.boat.party.1337+is.awesome.exp.sha.5114f85` does not share that quality. Moreover, we don't want to be comparing `1.2.3-apples` and `1.2.3-oranges`, particularly not alphabetically, because that makes `1.2.3-BETA` < `1.2.3-alpha` < `1.2.3-beta`.

On top of these version semantics, we also define constraints for them, resulting in this overall API:

```haxe
abstract Version {
  
  var major(get, never):Int;
  var minor(get, never):Int;
  var patch(get, never):Int;
  var preview(get, never):Null<Preview>;
  var previewNum(get, never):Int;

  function new(major:Int, minor:Int, patch:Int):Void;

  function alpha(?num:Int):Version;
  function beta(?num:Int):Version;
  function rc(?num:Int):Version;
  function stable():Version;

  function nextMajor():Version;  
  function nextMinor():Version;  
  function nextPatch():Version;

  @:op(a == b) static private function eq(a:Version, b:Version):Bool;
  @:op(a != b) static private function neq(a:Version, b:Version):Bool;
  @:op(a > b) static private function gt(a:Version, b:Version):Bool;
  @:op(a < b) static private function lt(a:Version, b:Version):Bool;
  @:op(a >= b) static private function gte(a:Version, b:Version):Bool;
  @:op(a <= b) static private function lte(a:Version, b:Version):Bool;
  
  @:op(a...b) static private function range(a:Version, b:Version):Constraint;

  static function parse(s:String):Outcome<Version, Error>;

}

@:enum abstract Preview {
  var ALPHA;
  var BETA;
  var RC;
}

abstract Constraint {

  var isWildcard(get, never):Bool;
  var isSatisfiable(get, never):Bool;
  
  function matches(v:Version):Bool;
  
  @:to function toString():String;
  
  static var WILDCARD(default, null):Constraint;

  static function exact(version:Version):Constraint;
  static function create(ranges:Array<Range>):Constraint;
  static function parse(s:String):Outcome<Constraint, Error>;

  @:from static private function ofVersion(v:Version):Constraint;
  
  @:op(a && b) static private function and(a:Constraint, b:Constraint):Constraint;
  @:op(a || b) static private function or(a:Constraint, b:Constraint):Constraint;

}

typedef Range = {
  var min(default, never):Bound;
  var max(default, never):Bound;
}

enum Bound {
  Unbounded;
  Exlusive(v:Version);
  Inclusive(v:Version);
}
```

With this in place, we can perform most of the SemVer arithmetics.

## Constraint Syntax and Semantics

The SemVer spec makes no actual mention of constraints or their particular syntax, so `tink_semver` provides a subset of node-semver, with a little difference:

- Operators are not permitted on partial version, so while `1.2.x` is valid, `>1.2.x` is not. You will have to go the extra mile and write `>=1.3.0`. As a corollary, the `~` operator is not supported, because it makes no sense without partial versions. This is relatively likely to change in future versions.
- A version without an operator is interpreted as a constraint satisfied by this an all later versions that are compatible according to semver semantics. For an exact match, use `=1.2.3`. When the `=` is omitted, an exact match will thus only be performed in two cases (see spec):

  > [4.](http://semver.org/#spec-item-4) Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable.
  >
  > [9.](http://semver.org/#spec-item-9) [...] A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility requirements as denoted by its associated normal version. 

  It is in fact the implicit cast from `Version` to `Constraint` that implements this behavior.

The latter point intentionally diverges from node-semver in pursuit of two goals:

1. To act according to the semantics of SemVer, making it the easiest thing to say "this particlar version and any version compatible with it", rather than throwing an army of operators at the user and let them figure it out. A node-semver compatibility mode may be included at some point though. 
2. To expose meaningful behavior when dealing with haxelib packages. Because the `haxelib.json` allows only an empty string or a particular version number to be specified for every dependency, this is a viable way to introduce version ranges to haxelib without sacrificing compatibility.

Constraints themselves are first class things in `tink_semver`. They are always simplified to the maximum and when converted back to string use node-semver compatible syntax:

```haxe

//first, let's define a few versions:
var v1_2_3 = new Version(1, 2, 3);
var v1_2_3_alpha_2 = v1_2_3.alpha(2);
var v1_3_0 = v1_2_3.nextMinor();
var v2_0_0 = v1_2_3.nextMajor();

//and interpret them as constraints:
var c1:Constraint = v1_2_3;
var c2:Constraint = v1_2_3_alpha_2;
var c3:Constraint = v1_3_0;
var c4:Constraint = v2_0_0;

trace(c1);//^1.2.3 - use carret for most compact explicit range representation
trace(c2);//=1.2.3-alpha.2 - explicitly use exact matching, because of prerelease
trace(c1 || c3);//^1.2.3 - c3 is entirely comprised by c1
trace(c1 && c3);//^1.3.0 - the intersection is therefore c3 itself
trace(c1 || c4);//>=1.2.3 <3.0.0 - c1 and c4 become one range
trace(c2 || c4);//=1.2.3-alpha.2 || ^2.0.0 - c2 and c4 are disjoint though
trace(c1 && c4);//<0.0.0 - thefore their intersection is unsatisfiable
```