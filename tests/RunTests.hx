package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class RunTests {
	static var cases:Array<TestCase> = [
		// new TestConstraint(),
		new TestResolve(),
    new TestBounds(),
	];

  static function main() {

    var runner = new TestRunner();
    for (c in cases)
      runner.add(c);
    
    travix.Logger.exit(if (runner.run()) 0 else 500); 
  }
  
}