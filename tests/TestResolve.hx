package;

import tink.semver.*;
import tink.semver.Resolve;
import tink.unit.AssertionBuffer;

using tink.CoreApi;
using Lambda;
using TestResolve;

@:asserts
class TestResolve {
  public function new() {}
  
  function v(a, ?i = 0, ?p = 0)
    return new Version(a, i, p);
  
  function optimistic(a, i, p) {
    var v = v(a, i, p);
    return v...(v.nextMajor());
  }
    
  public function simple() {
    var m:Map<String, Infos<String>> = [
      'tink_core' => [
        { version: v(1, 0, 0), dependencies: [] },
        { version: v(1, 0, 1), dependencies: [] },
        { version: v(1, 0, 2), dependencies: [] },
        { version: v(1, 0, 3), dependencies: [] },
        { version: v(1, 1, 0), dependencies: [] },
        { version: v(1, 1, 1), dependencies: [] },
        { version: v(1, 1, 2), dependencies: [] },
        { version: v(1, 1, 3), dependencies: [] },
        { version: v(1, 2, 0), dependencies: [] },
        { version: v(1, 2, 1), dependencies: [] },
        { version: v(1, 2, 2), dependencies: [] },
        { version: v(1, 2, 3), dependencies: [] },
        { version: v(1, 2, 4), dependencies: [] },
        { version: v(1, 2, 5), dependencies: [] },
        { version: v(1, 3, 0), dependencies: [] },
      ],
      'tink_macro' => [
        { 
          version: v(1, 0, 0), dependencies: [{ name: 'tink_core', constraint: optimistic(1, 1, 0) }],
        } , {
          version: v(1, 1, 0), dependencies: [{ name: 'tink_core', constraint: v(1, 1, 0)...v(1, 2, 0) }] 
        },      
      ],
      'tink_syntaxhub' => [
        { version: v(1, 0, 0), dependencies: [{ name: 'tink_macro', constraint: null }, { name: 'tink_core', constraint: v(1, 2, 0)...v(1, 3, 0) }] },
      ]
    ];
    
    var queue = [];
    
    function sync<A>(v:A):Future<A> {
      var ret = Future.trigger();
      queue.push(function () ret.trigger(v));
      return ret;
    }
    
		function resolve(name) return sync(switch m[name] {
      case null: Failure(new Error(NotFound, 'No version info available for $name'));
      case v: Success(v);
		});

    Resolve.dependencies([ { name: 'tink_syntaxhub' } ], resolve).handle(function (o) 
      asserts.expect(
        ['tink_syntaxhub' => v(1, 0, 0), 'tink_macro' => v(1, 0, 0), 'tink_core' => v(1, 2, 5)],
        o.sure()
      )
    );
    
    for (q in queue) q();
    
    return asserts.done();
  }
  
  public function weird() {
    var m:Map<String, Infos<String>> = [
      'libA' => [for (i in 90...100) { version: v(i), dependencies: [] }],
      'libB' => [for (i in 5...6) { version: v(i), dependencies: [{ name: 'libA', constraint: v(i * 17)...v(7 + i * 17) }] }], //0...7, 17...24, 34...41, 51...58, 68...75, 85...92
      'libC' => [for (i in 7...8) { version: v(i), dependencies: [{ name: 'libA', constraint: v(i * 13)...v(5 + i * 13) }] }], //0...5, 13...18, 26...31, 39...44, 52...57, 65...70, 78...83, 91...96
      'libD' => [for (c in 7...8) for (b in 5...6) { 
          version: v(b, c), 
          dependencies: [ { 
            name: 'libC', constraint: (v(c):Constraint) 
          }, { 
            name: 'libB', constraint: (v(b):Constraint)
          }] 
      }],
    ];

    var queue = [];
    
    function sync<A>(v:A):Future<A> {
      var ret = Future.trigger();
      queue.push(function () ret.trigger(v));
      return ret;
    }
    
		function resolve(name) return sync(switch m[name] {
      case null: Failure(new Error(NotFound, 'No version info available for $name'));
      case v: Success(v);
		});
		

		Resolve.dependencies([ { name: 'libD' }, { name: 'libA', constraint: null } ], resolve).handle(function (x) {

			asserts.expect([
				'libA' => v(91, 0, 0),
				'libB' => v( 5, 0, 0),
				'libC' => v( 7, 0, 0),
				'libD' => v( 5, 7, 0),
			], x.sure());

		});

		for (q in queue) q();
    
    return asserts.done();
  }
  
  static function expect(asserts:AssertionBuffer, expected:Map<String, Version>, actual:Map<String, Version>) {
    asserts.assert(expected.count() == actual.count());
    for (name in expected.keys()) {
      asserts.assert(expected[name].toString() == actual[name].toString());
    }
  }
}