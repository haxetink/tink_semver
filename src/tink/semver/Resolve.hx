package tink.semver;

typedef Resolved<Name> = Promise<Map<Name, Version>>;

class Resolve {
  @:generic static public function dependencies<Name>(deps:Array<Dependency<Name>>, getInfos:Name->Promise<Infos<Name>>):Resolved<Name> {

    function add<T>(a:Map<Name, T>, b:Map<Name, T>)
      return [for (m in [a, b]) for (key in m.keys()) key => m[key]];

    function seek(rest:Array<Name>, constraints:Map<Name, Constraint>, ?pos:haxe.PosInfos):Resolved<Name> {
      if (rest.length == 0)
        return new Map();
        
      var name = rest[0];
      
      var constraint = constraints[name];

      return getInfos(name).next(function (infos) {
        function attempt(pos:Int):Resolved<Name> {
          return 
            if (pos == infos.length) new Error('Failed to resolve $name');
            else {
              
              var v = infos[pos];
              if (!constraint.isSatisfiedBy(v.version))
                attempt(pos + 1);
              else {
                var constraints = add(constraints, [name => Constraint.exact(v.version)]);

                var constraints = add(constraints, [
                  for (c in v.dependencies)
                    c.name => constraints[c.name] && c.constraint
                ]);

                //TODO: above we should just exit if reaching a non-satisfiable constraint

                var rest = rest.slice(1);
                for (d in v.dependencies) 
                  if (rest.indexOf(d.name) == -1)
                    rest.push(d.name);

                return seek(rest, constraints).next(function (ret) {
                  return add(ret, [name => v.version]);
                }).tryRecover(function (e) {
                  return attempt(pos + 1);
                });
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