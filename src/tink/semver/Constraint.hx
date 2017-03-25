package tink.semver;

import tink.semver.Version;

abstract Constraint(Null<Array<Range>>) {
  public var isSatisfiable(get, never):Bool;
    inline function get_isSatisfiable()
      return this == null || this.length > 0;

  inline function new(v) {
    this = v;
  }
  
  static public var ANY(default, null):Constraint = null;

  static public function create(ranges:Array<Range>) {
    
    var merged = new Array<Range>();

    for (nu in ranges) {
      var next = [];
      for (old in merged)
        switch old.merge(nu) {
          case None: next.push(old);
          case Some(v): nu = v;
        }

      next.push(nu);
      merged = next;
    
    }

    return new Constraint(merged);
  }
  static public function exact(version:Version) {
    return new Constraint([{ min: Closed(version), max: Closed(version) }]);
  }
  static public function range(min:Version, max:Version) {
    return new Constraint([{ min: Closed(min), max: Open(max) }]);
  }

  inline function iterator()
    return this.iterator();

  public function isSatisfiedBy(v:Version) 
    switch this {
      case null: return true;
      default: 
        for (r in this) 
          if (r.contains(v)) 
            return true; 
        return false;
    }
  @:to public function toString() 
    return switch this {
      case null: '*';
      case []: '<0';
      default:
        [for (r in this) r.toString()].join(' || ');
    } 
  
  @:from static function ofVersion(v:Version):Constraint
    return 
      switch v {
        case { preview: ALPHA | BETA | RC }: exact(v);
        case { major: 0 } : v...v.nextMinor();
        default: v...v.nextMajor();
      }
      
  @:op(a && b) static function and(a:Constraint, b:Constraint):Constraint
    return switch [a, b] {
      case [null, _]: b;
      case [_, null]: a;
      default: 
        var ret = [];

        for (a in a) {
          var res = a;

          for (b in b) 
            switch res.intersect(b) {
              case Some(c): res = c;
              case None: res = null; break;
            }

          if (res != null) ret.push(res);
        }

        create(ret);
    }
}