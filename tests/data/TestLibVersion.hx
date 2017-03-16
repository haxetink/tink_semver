package data;

import haxe.unit.TestCase;
import haxelib.data.LibVersion;

using tink.CoreApi;

class TestLibVersion extends TestCase {
	function allow(s:String)
		assertTrue(LibVersion.ofString(s).isSuccess());
		
	function reject(s:String)
		assertFalse(LibVersion.ofString(s).isSuccess());
	
	function test() {
		allow("0.1.2");
		allow("100.50.200");

		allow("0.1.2-alpha");
		allow("0.1.2-alpha");
		allow("0.1.2-beta");
		allow("0.1.2-rc");
		allow("0.1.2-rc.1");
	}
	
	public function testOfStringInvalid() {
		reject(null);
		reject("");
		reject("1");
		reject("1.1");
		reject("1.2.a");
		reject("a.b.c");
		reject("1.2.3-");
		reject("1.2.3-rc.");
		reject("1.2.3--rc.1");
		reject("1.2.3-othertag");
		reject("1.2.3-othertag.1");
	}
}