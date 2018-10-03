package;

import tink.semver.*;
import tink.unit.AssertionBuffer;

using tink.CoreApi;
using Lambda;
using TestConstraint;

@:asserts
class TestConstraint {
  public function new() {}
  
  function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
  
  // function testEmpty() {
  //   trace(Constraint.range(v(2), v(2)));
  // }

  public function match() {
    function test(constraint:String, outside:Array<String>, within:Array<String>, ?pos:haxe.PosInfos) {
      
      var c = Constraint.parse(constraint).sure();

      for (v in outside)
        asserts.assert(!c.matches(Version.parse(v).sure()), pos);

      for (v in within)
        asserts.assert(c.matches(Version.parse(v).sure()), pos);

    }

    test('^0.0.3', ['0.0.2', '0.0.4', '0.0.3-alpha.1'], ['0.0.3']);
    test('^0.0.3-alpha', ['0.0.2', '0.0.4'], ['0.0.3', '0.0.3-alpha.0', '0.0.3-alpha.1']);
    test('^0.0.3-alpha.2', ['0.0.2', '0.0.4', '0.0.3-alpha.1'], ['0.0.3', '0.0.3-alpha.2', '0.0.3-alpha.3']);    
    return asserts.done();
  }

  public function simplify() {

    function test(raw:String, simplified:String, ?pos:haxe.PosInfos) {
      asserts.assert(simplified == Constraint.parse(raw).sure().toString(), pos);
    }

    test('>=1.3.5 <2.0.0', '^1.3.5');
    test('>=0.3.5 <0.4.0', '^0.3.5');
    test('^0.3.5', '^0.3.5');
    test('^0.3.5 || =1.0.0', '^0.3.5 || =1.0.0');
    test('^0.3.5 || <2.0.0 >=0.4.0 || =1.0.0', '>=0.3.5 <2.0.0');
    test('^0.3.5 || <2.0.0 >=0.4.0 || =1.0.0 || =2.0.0', '0.3.5 - 2.0.0');
    return asserts.done();
  }

  static function allow(asserts:AssertionBuffer, s:String, ?pos:haxe.PosInfos)
    asserts.assert(Constraint.parse(s), pos);
    
  static function reject(asserts:AssertionBuffer, s:String, ?pos:haxe.PosInfos)
    asserts.assert(!Constraint.parse(s).isSuccess(), pos);
  
  public function valid() {
    asserts.allow('*');
    asserts.allow('1.2.3');
    asserts.allow('1.2.3 - 3.2.1');
    asserts.allow('1.2.3 - 3.2.1 || 3.2.1');
    asserts.allow('1.2.3 - 3.2.1 || <5.2.1 ^1.2.4');
    return asserts.done();
  }  
  
  public function invalid() {
    asserts.reject('a');
    asserts.reject('1.2.3-3.2.1');
    asserts.reject('-3.2.1');
    asserts.reject('- 3.2.1');
    asserts.reject('3.2.1-');
    asserts.reject('3.2.1-horst');
    asserts.reject('3.2.1 -');
    return asserts.done();
  
  } 
}