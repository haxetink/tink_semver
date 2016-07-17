package tink.semver;

using tink.CoreApi;

import tink.semver.Constraint;

class Resolve {
	function new() {
		
	}
	@:generic static public function dependencies<Name>(deps:Array<Dependency<Name>>, getInfos:Name->Outcome<Infos<Name>, Error>):Outcome<Map<Name, Version>, Error> {
      
		function seek(rest:Array<Name>, constraints:Map<Name, Constraint>):Outcome<Map<Name, Version>, Error> {
			if (rest.length == 0)
				return Success(new Map());
				
			var name = rest[0];
			
			var constraint = constraints[name],
          infos = switch getInfos(name) {
            case Success(v): v;
            case Failure(e): return Failure(e);
          }
			
			for (v in infos) {
				if (constraint.isSatisfiedBy(v.version)) {
					//trace('trying $name@${v.version}');
					
					var copy = [for (key in constraints.keys()) key => constraints[key]];//just a copy
					
					copy[name] = Eq(v.version);
					
					for (d in v.dependencies)
						copy[d.name] = And(copy[d.name], d.constraint);
						
					switch seek(rest.slice(1), copy) {
						case Success(ret):
							ret[name] = v.version;
							
							for (name in ret.keys())
								copy[name] = Eq(ret[name]);
							
							switch seek([for (d in v.dependencies) d.name], copy) {
								case Success(deps):
									for (name in deps.keys())
										ret[name] = deps[name];
										
									return Success(ret);
								default:
							}
							
						default:
					}
					
				}
			}
			
			return Failure(new Error(NotFound, 'Unable to resolve dependencies'));
		}
		return seek(
			[for (d in deps) d.name],
			[for (d in deps) d.name => d.constraint]
		);
	}
}

typedef Dependency<Name> = {
	name:Name,
	?constraint:Constraint,
}

typedef InfosRep<Name> = Array<{
	version: Version,
	dependencies:Array<Dependency<Name>>
}>;

@:forward(length, iterator)
abstract Infos<Name>(InfosRep<Name>) {
  public function new(data:InfosRep<Name>) {
    this = data.copy();
    this.sort(function (v1, v2) return -v1.version.compare(v2.version));
  }
  
  @:arrayAccess public inline function get(index:Int)
    return this[index];
    
  @:from static function ofArray(data)
    return new Infos(data);
}