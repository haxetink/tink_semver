package tink.semver;

using tink.CoreApi;

import tink.semver.Constraint;

class Resolve {
	function new() {
		
	}
	@:generic static public function dependencies<Name>(deps:Array<Dependency<Name>>, getInfos:Name->Surprise<Infos<Name>, Error>):Surprise<Map<Name, Version>, Error> {
      
		function seek(rest:Array<Name>, constraints:Map<Name, Constraint>, ?pos:haxe.PosInfos):Surprise<Map<Name, Version>, Error> {
			if (rest.length == 0)
				return Future.sync(Success(new Map()));
				
			var name = rest[0];
			//trace('${pos.lineNumber} -> $name: $constraints');
      return getInfos(name) >> function (infos:Infos<Name>):Surprise<Map<Name, Version>, Error> {
        var constraint = constraints[name];
        
        return Future.async(function (cb) {
          trace(name + ' -> ' + infos.length +' with '+rest);
          trace(constraint);
          var pos = 0;
          var cb = function (x) {
            trace('done $name $pos/${infos.length} '+Std.string(x));
            cb(x);
          }
          
          function next() {
            if (pos < infos.length) {
              var v = infos[pos++];
              if (!constraint.isSatisfiedBy(v.version)) {
                trace('skip ${v.version}');
                next();
              }
              else {
                trace('trying $name@${v.version} ($pos/${infos.length})');
                
                var copy = [for (key in constraints.keys()) key => constraints[key]];//just a copy
                
                copy[name] = Eq(v.version);
                
                for (c in v.dependencies)
                  copy[c.name] = copy[c.name] && c.constraint;
                  
                seek(rest.slice(1), copy).handle(function (o) switch o {
                  case Success(ret):
                    ret[name] = v.version;
                    
                    for (name in ret.keys())
                      copy[name] = Eq(ret[name]);
                    
                    seek([for (d in v.dependencies) d.name], copy).handle(function (o) switch o {
                      case Success(deps):
                        
                        for (name in deps.keys())
                          ret[name] = deps[name];
                        
                        cb(Success(ret));  
                      default:
                        next();
                    });
                      
                  default:
                    next();
                });
              }
            }
            else cb(Failure(new Error(NotFound, 'Unable to resolve dependencies for $name')));
          }
          
          next();
        });
      }

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