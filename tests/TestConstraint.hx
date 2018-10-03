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

  static function allow(asserts:AssertionBuffer, s:String)
    asserts.assert(switch Constraint.parse(s) {
      case Failure(f): 
        trace('$s -> $f');
        false;
      case Success(_): true;
    });
    
  static function reject(asserts:AssertionBuffer, s:String)
    asserts.assert(!Constraint.parse(s).isSuccess());
  
  @:exclude
  public function valid() {
    [
      '*',
      '1.2.3',
      '1.2.3 - 3.2.1',
      '1.2.3 - 3.2.1 || 3.2.1',
      '1.2.3 - 3.2.1 || <5.2.1 ^1.2.4',
    ].iter(asserts.allow);
    return asserts.done();
  }  
  @:exclude
  public function invalid() {
    [
      'a',
      '1.2.3-3.2.1',
      '-3.2.1',
      '- 3.2.1',
      '3.2.1-',
      '3.2.1-horst',
      '3.2.1 -',
    ].iter(asserts.reject);
    return asserts.done();
  
  } 
}