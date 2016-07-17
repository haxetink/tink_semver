package;

import haxe.unit.TestCase;
import tink.semver.*;
import tink.semver.Resolve;

using tink.CoreApi;
using Lambda;

class TestResolve extends TestCase {
	function v(a, i, p)
		return new Version(a, i, p);
	
	function optimistic(a, i, p) {
		var v = v(a, i, p);
		return v...(v.nextMajor());
	}
		
	function testSimple() {
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
    
    Resolve.dependencies([ { name: 'tink_syntaxhub' } ], function (name) return sync(switch m[name] {
      case null: Failure(new Error(NotFound, 'No version info available for $name'));
      case v: Success(v);
    })).handle(function (o) 
      expect(
        ['tink_syntaxhub' => v(1, 0, 0), 'tink_macro' => v(1, 0, 0), 'tink_core' => v(1, 2, 5)],
        o.sure()
			)
		);
    
    for (q in queue) q();
	}
	
	function expect(expected:Map<String, Version>, actual:Map<String, Version>) {
    trace(actual);
		assertEquals(expected.count(), actual.count());
		for (name in expected.keys()) {
			assertEquals(expected[name].toString(), actual[name].toString());
		}
	}
}