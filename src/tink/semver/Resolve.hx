package tink.semver;

using tink.CoreApi;

import tink.semver.Version;
import tink.semver.Constraint;

typedef Resolved<Name> = Promise<Map<Name, Version>>;

class Resolve {
  function new() {
    
  }
  @:generic static public function dependencies<Name>(deps:Array<Dependency<Name>>, getInfos:Name->Promise<Infos<Name>>):Resolved<Name> {

    function add<T>(a:Map<Name, T>, b:Map<Name, T>)
      return [for (m in [a, b]) for (key in m.keys()) key => m[key]];

    function seek(rest:Array<Name>, constraints:Map<Name, Constraint>, ?pos:haxe.PosInfos):Resolved<Name> {
      if (rest.length == 0)
        return new Map();
        
      var name = rest[0];
      //trace('${pos.lineNumber} -> $name: $constraints');
      
      var constraint = constraints[name];

      return getInfos(name).next(function (infos) {
        function attempt(pos:Int):Resolved<Name> {
          return 
            if (pos == infos.length) new Error('Failed to resolve $name');
            else {
              trace('$name $pos/${infos.length}');
              var v = infos[pos];
              if (!constraint.isSatisfiedBy(v.version))
                attempt(pos + 1);
              else {
                var constraints = add(constraints, [name => Eq(v.version)]);

                for (c in v.dependencies)
                  constraints[c.name] = constraints[c.name] && c.constraint;
                  
                return seek(rest.slice(1), constraints).next(function (ret) {
                  var ret = add(ret, [name => v.version]);
                  var constraints = add(
                    constraints,
                    [for (name in ret.keys()) name => Eq(ret[name])]
                  );
                  return seek([for (d in v.dependencies) d.name], constraints).next(function (deps) {
                    return add(ret, deps);
                  });                    

                }).tryRecover(function (_) return attempt(pos + 1));
              }
            }
        }
        return attempt(0);
      });
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