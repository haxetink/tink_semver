package tink.semver;

import tink.semver.Version;

abstract Constraint(Null<Array<ConstraintKind>>) {
  public var isSatisfiable(get, never):Bool;
    inline function get_isSatisfiable()
      return this == null || this.length > 0;

  inline function new(v) {
    this = v;
  }
  
  static public var ANY(default, null):Constraint = null;

  static public function create(parts:Array<ConstraintKind>) {
    return new Constraint(parts);
    //TODO: this implementation actually misses many cases - it should merge any ranges that overlap
    var ranges = new Array<Range>(),
        exact = [];

    for (p in parts)
      switch p {
        case Bounded(nu): 
          var next = [];
          for (old in ranges)
            switch old.merge(nu) {
              case None: next.push(old);
              case Some(v): nu = v;
            }

          next.push(nu);
          ranges = next;
        
        case Eq(v): exact.push(v);
      }

    var ranges = ranges.map(Bounded);
    var c = new Constraint(ranges);

    return new Constraint(ranges.concat([for (v in exact)
      if (c.isSatisfiedBy(v)) continue
      else Eq(v)
    ]));
  }
  static public function exact(version:Version) {
    // return new Constraint([Eq(version)]);
    return new Constraint([Bounded({ min: Closed(version), max: Closed(version) })]);
  }
  static public function range(min:Version, max:Version) {
    return new Constraint([Bounded({ min: Closed(min), max: Open(max) })]);
  }

  inline function iterator()
    return this.iterator();

  static function mergeSingle(a:ConstraintKind, b:ConstraintKind) {
    return switch [a, b] {
      case [Eq(a), Eq(b)]: 
        if (a == b) Some(Eq(a));
        else None;
      case [Eq(v), Bounded(r)] | [Bounded(r), Eq(v)]:
        if (r.contains(v))
          Some(Eq(v));
        else
          None;
      case [Bounded(a), Bounded(b)]:
        a.intersect(b).map(Bounded);
    }
  }

  public function isSatisfiedBy(v:Version) 
    switch this {
      case null: return true;
      default: 
        for (c in this) switch c {
          case Eq(expected):
            if (expected == v) return true;

          case Bounded(r):
            if (r.contains(v)) 
              return true; 
        }
        return false;
    }
  @:to public function toString() 
    return switch this {
      case null: '*';
      case []: '<0';
      default:
        [for (c in this) switch c {
          case Eq(v): '=$v';
          case Bounded(r): r.toString();
        }].join(' || ');
    } 
      
  static public function parse(s:String)
    return 
      switch s {
        case null, '', '*': Success(null);
        default: //TODO: this parser is *very* crude
          try 
            Success(create(s.split('||').map(parseSingle)))
          catch (e:Error)
            Failure(e);
      }
  
  static function parseSingle(s:String) {
    
    function die(reason:String, ?pos:haxe.PosInfos):Dynamic
      return throw new Error(422, reason, pos);
    
    return switch tokenize(s) {
      case [TOther(s)]: die('not implemented');
      case [v]: die('unexpected $v');
      default: die('not implemented');
    }
  }

  static function tokenize(s:String):Array<Token> {
    return [];
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
            switch mergeSingle(res, b) {
              case Some(c): res = c;
              case None: res = null; break;
            }

          if (res != null) ret.push(res);
        }

        create(ret);
    }
}

enum Token {
  TGt;
  TGte;
  TLt;
  TLte;
  TEq;
  TDash;
  TOther(s:String);
}

enum ConstraintKind {
  Eq(ver : Version);
  Bounded(r:Range);
}