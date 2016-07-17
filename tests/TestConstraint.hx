package;

import haxe.unit.TestCase;
import tink.semver.*;

using tink.CoreApi;
using Lambda;

class TestConstraint extends TestCase {
	
	function allow(s:String) {
		assertTrue(switch Constraint.parse(s) {
			case Failure(f): 
				trace(f);
				false;
			case Success(_): true;
		});
	}
		
	function reject(s:String)
		assertFalse(Constraint.parse(s).isSuccess());
	
	function v(s:String)
		Version.parse(s).sure();
	
	function testValid(s:String) 
		[
			'',
			'*',
			null,
			'1.2.3',
			'1.2.3 - 3.2.1',
			'1.2.3 - 3.2.1 || 3.2.1',
			'1.2.3 - 3.2.1 || >5.2.1 +1.2.4',
		].iter(allow);
		
	function testInvalid(s:String)
		[
			'a',
			'1.2.3-3.2.1',
			'-3.2.1',
			'- 3.2.1',
			'3.2.1-',
			'3.2.1 -',
		].iter(reject);
	
	
}