package ;

import tink.unit.AssertionBuffer;
import tink.semver.*;
using tink.semver.Bound;
using TestBounds;

@:asserts
class TestBounds {
  public function new() {}
  
  static function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
    
  static function eq(asserts:AssertionBuffer, a:Bound, b:Bound, ?pos:haxe.PosInfos) {
    asserts.assert(Std.string(a) == Std.string(b), pos);
  }

  static var o1 = Exlusive(v(1));
  static var o2 = Exlusive(v(2));
  static var c1 = Inclusive(v(1));
  static var c2 = Inclusive(v(2));
  
  public function upperMin() {
    asserts.eq(o2, o2.min(c2, Upper));
    asserts.eq(o1, o1.min(c2, Upper));
    asserts.eq(c1, o2.min(c1, Upper));
    asserts.eq(o1, o1.min(c1, Upper));
    return asserts.done();
  }
  
  public function upperMax() {
    asserts.eq(c2, o2.max(c2, Upper));
    asserts.eq(c2, o1.max(c2, Upper));
    asserts.eq(o2, o2.max(c1, Upper));
    asserts.eq(c1, o1.max(c1, Upper));
    return asserts.done();
  }
  
  public function lowerMin() {
    asserts.eq(c2, o2.min(c2, Lower));
    asserts.eq(o1, o1.min(c2, Lower));
    asserts.eq(c1, o2.min(c1, Lower));
    asserts.eq(c1, o1.min(c1, Lower));
    return asserts.done();
  }

  public function lowerMax() {
    asserts.eq(o2, o2.max(c2, Lower));
    asserts.eq(c2, o1.max(c2, Lower));
    asserts.eq(o2, o2.max(c1, Lower));
    asserts.eq(o1, o1.max(c1, Lower));
    return asserts.done();
  }
}