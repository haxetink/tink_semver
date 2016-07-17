package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import tink.semver.Resolve;

class RunTests {
	static var cases:Array<TestCase> = [
		new TestConstraint(),
		new TestResolve(),
	];

  static function main() {
    var runner = new TestRunner();
    for (c in cases)
      runner.add(c);
    
    travix.Logger.exit(if (runner.run()) 0 else 500); 
  }
  
}