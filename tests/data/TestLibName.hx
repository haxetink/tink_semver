package data;

import haxe.unit.TestCase;
import haxelib.data.LibName;

using tink.CoreApi;

class TestLibName extends TestCase {
	
	function rand(chars:String, length:Int) {
		var s = new StringBuf();
		for (i in 0...length)
			s.addChar(chars.charCodeAt(Std.random(chars.length)));
		return s.toString();
	}
	
	function allow(s:String)
		assertTrue(LibName.ofString(s).isSuccess());
		
	function reject(s:String)
		assertFalse(LibName.ofString(s).isSuccess());
		
	function test() {
		
		reject('haxe');
		reject('all');
		reject('haxelib.json');
		
		for (i in 0...100) {
			var name = rand(LibName.ALLOWED, 4 + Std.random(10));
			allow(name);
			reject('$name.zip');
			reject('$name.hxml');
			reject('$name%');
			reject('$name$$');
			reject(' $name');
		}
		reject('a');
		reject('aa');
		allow('aaa');
	}
}