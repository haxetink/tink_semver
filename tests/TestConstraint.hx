package;

import haxe.unit.TestCase;
import tink.semver.*;

using tink.CoreApi;
using Lambda;

class TestConstraint extends TestCase {

  function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
  
  // function testEmpty() {
  //   trace(Constraint.range(v(2), v(2)));
  // }

  function testMatch() {
    function test(constraint:String, outside:Array<String>, within:Array<String>, ?pos:haxe.PosInfos) {
      
      var c = Constraint.parse(constraint).sure();

      for (v in outside)
        assertFalse(c.matches(Version.parse(v).sure()), pos);

      for (v in within)
        assertTrue(c.matches(Version.parse(v).sure()), pos);

    }

    test('^0.0.3', ['0.0.2', '0.0.4', '0.0.3-alpha.1'], ['0.0.3']);
    test('^0.0.3-alpha', ['0.0.2', '0.0.4'], ['0.0.3', '0.0.3-alpha.0', '0.0.3-alpha.1']);
    test('^0.0.3-alpha.2', ['0.0.2', '0.0.4', '0.0.3-alpha.1'], ['0.0.3', '0.0.3-alpha.2', '0.0.3-alpha.3']);    
  }

  function testSimplify() {

    function test(raw:String, simplified:String, ?pos:haxe.PosInfos) {
      assertEquals(simplified, Constraint.parse(raw).sure().toString(), pos);
    }

    test('>=1.3.5 <2.0.0', '^1.3.5');
    test('>=0.3.5 <0.4.0', '^0.3.5');
    test('^0.3.5', '^0.3.5');
    test('^0.3.5 || =1.0.0', '^0.3.5 || =1.0.0');
    test('^0.3.5 || <2.0.0 >=0.4.0 || =1.0.0', '>=0.3.5 <2.0.0');
    test('^0.3.5 || <2.0.0 >=0.4.0 || =1.0.0 || =2.0.0', '0.3.5 - 2.0.0');
  }

  function allow(s:String) {
    assertTrue(switch Constraint.parse(s) {
      case Failure(f): 
        trace('$s -> $f');
        false;
      case Success(_): true;
    });
  }
    
  function reject(s:String)
    assertFalse(Constraint.parse(s).isSuccess());
  
  function _testValid() 
    [
      '*',
      '1.2.3',
      '1.2.3 - 3.2.1',
      '1.2.3 - 3.2.1 || 3.2.1',
      '1.2.3 - 3.2.1 || <5.2.1 ^1.2.4',
    ].iter(allow);
    
  function _testInvalid()
    [
      'a',
      '1.2.3-3.2.1',
      '-3.2.1',
      '- 3.2.1',
      '3.2.1-',
      '3.2.1-horst',
      '3.2.1 -',
    ].iter(reject);
  
}