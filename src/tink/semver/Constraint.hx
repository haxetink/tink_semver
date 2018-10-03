package tink.semver;

import tink.semver.Version;

abstract Constraint(Null<Array<Range>>) {

  public var isWildcard(get, never):Bool;
    inline function get_isWildcard()
      return this == null;

  public var isSatisfiable(get, never):Bool;
    inline function get_isSatisfiable()
      return this == null || this.length > 0;

  inline function new(v) 
    this = v;
  
  static public var WILDCARD(default, null):Constraint = null;

  static public function parse(s:String)
    return switch s {
      case '' | null: Success(WILDCARD);
      default: new Parser(s).parseConstraint.catchExceptions();
    }
    
  static public function create(ranges:Array<Range>) {
    
    var merged = new Array<Range>();

    for (r in ranges) 
      switch r.nonEmpty() {
        case Some(nu):
          var next = [];
          for (old in merged)
            switch old.merge(nu) {
              case None: next.push(old);
              case Some(v): nu = v;
            }

          next.push(nu);
          merged = next;
        case None:
      }

    return new Constraint(merged);
  }

  static public function exact(version:Version):Constraint
    return new Constraint([{ min: Inclusive(version), max: Inclusive(version) }]);
  
  static public function range(min:Version, max:Version):Constraint
    return new Constraint({ min: Inclusive(min), max: Exlusive(max) }.nonEmpty().toArray());

  inline function iterator()
    return this.iterator();

  inline function array()
    return this;

  public function matches(v:Version) 
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
      case []: '<0.0.0';
      default:
        [for (r in this) r.toString()].join(' || ');
    } 
  
  @:from static function fromRange(r:Range):Constraint
    return create([r]);

  @:from static function ofVersion(v:Version):Constraint
    return 
      switch v {
        case { preview: ALPHA | BETA | RC } | { major: 0 }: exact(v);
        default: v...v.nextMajor();
      }
      
  @:op(a || b) static function or(a:Constraint, b:Constraint):Constraint
    return switch [a, b] {
      case [null, _] | [_, null]: null;
      default:
        create(a.array().concat(b.array()));
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
    
    #if tink_json
    @:from
    public static function fromRepresentation(rep:tink.json.Representation<Array<Range>>):Constraint
      return create(rep.get());
    @:to
    public function toRepresentation():tink.json.Representation<Array<Range>>
      return new tink.json.Representation(this == null ? [] : this);
    #end
}