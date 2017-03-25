package ;

import tink.semver.*;
using tink.semver.Bound;

class TestBounds extends haxe.unit.TestCase {
  static function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
    
  function eq(a:Bound, b:Bound, ?pos:haxe.PosInfos) {
    assertEquals(Std.string(a), Std.string(b), pos);
  }

  static var o1 = Open(v(1));
  static var o2 = Open(v(2));
  static var c1 = Closed(v(1));
  static var c2 = Closed(v(2));
  
  function testUpperMin() {
    eq(o2, o2.min(c2, Upper));
    eq(o1, o1.min(c2, Upper));
    eq(c1, o2.min(c1, Upper));
    eq(o1, o1.min(c1, Upper));
  }
  
  function testUpperMax() {
    eq(c2, o2.max(c2, Upper));
    eq(c2, o1.max(c2, Upper));
    eq(o2, o2.max(c1, Upper));
    eq(c1, o1.max(c1, Upper));
  }
  
  function testLowerMin() {
    eq(c2, o2.min(c2, Lower));
    eq(o1, o1.min(c2, Lower));
    eq(c1, o2.min(c1, Lower));
    eq(c1, o1.min(c1, Lower));
  }

  function testLowerMax() {
    eq(o2, o2.max(c2, Lower));
    eq(c2, o1.max(c2, Lower));
    eq(o2, o2.max(c1, Lower));
    eq(o1, o1.max(c1, Lower));
  }
}