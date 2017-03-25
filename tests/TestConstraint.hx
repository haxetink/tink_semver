package;

import haxe.unit.TestCase;
import tink.semver.*;

using tink.CoreApi;
using Lambda;

class TestConstraint extends TestCase {

  function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
  
  function testSimplify() {
    
    // trace(Constraint.create([
    //   Bounded({ min: Open(v(0)), max: Open(v(1)) } ),
    //   Bounded({ min: Open(v(0)), max: Open(v(1)) } ),
    // ]));
    
    // trace(Constraint.create([
    //   Bounded({ min: Closed(v(0)), max: Open(v(1)) } ),
    //   Bounded({ min: Open(v(0)), max: Open(v(1)) } ),
    // ]));

    // trace(Constraint.create([
    //   Bounded({ min: Open(v(0)), max: Closed(v(1)) } ),
    //   Bounded({ min: Open(v(0)), max: Open(v(1)) } ),
    // ]));
    
    // trace(Constraint.create([
    //   Bounded({ min: Closed(v(0)), max: Open(v(1)) } ),
    //   Bounded({ min: Open(v(0)), max: Closed(v(1)) } ),
    // ]));

    // trace(Constraint.create([
    //   Bounded({ min: Open(v(0)), max: Open(v(1)) } ),
    //   Bounded({ min: Closed(v(0)), max: Closed(v(1)) } ),
    // ]));

    trace(Constraint.create([
      { min: Closed(v(0)), max: Open(v(1)) },
      { min: Open(v(1)), max: Open(v(2)) },
    ]));    
  }
  // function allow(s:String) {
  //   assertTrue(switch Constraint.parse(s) {
  //     case Failure(f): 
  //       trace('$s -> $f');
  //       false;
  //     case Success(_): true;
  //   });
  // }
    
  // function reject(s:String)
  //   assertFalse(Constraint.parse(s).isSuccess());
  
  // function v(s:String)
  //   Version.parse(s).sure();
  
  // function testValid() 
  //   [
  //     '',
  //     '*',
  //     null,
  //     '1.2.3',
  //     '1.2.3 - 3.2.1',
  //     '1.2.3 - 3.2.1 || 3.2.1',
  //     '1.2.3 - 3.2.1 || >5.2.1 +1.2.4',
  //   ].iter(allow);
    
  // function testInvalid()
  //   [
  //     'a',
  //     '1.2.3-3.2.1',
  //     '-3.2.1',
  //     '- 3.2.1',
  //     '3.2.1-',
  //     '3.2.1 -',
  //   ].iter(reject);
  
}