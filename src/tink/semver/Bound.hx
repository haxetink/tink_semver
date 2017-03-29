package tink.semver;

enum Bound {
  Unbounded;
  Exlusive(limit:Version);
  Inclusive(limit:Version);
}

class BoundTools {

  static public function isLowerThan(a:Bound, b:Bound) 
    return
      switch [a, b] {
        case [Exlusive(a) | Inclusive(a), Exlusive(b)] if (a == b): false;
        case [Exlusive(a) | Inclusive(a), Exlusive(b) | Inclusive(b)] if (a > b): false;
        default: true;
      }

  static public function min(a:Bound, b:Bound, kind:ExtremumKind)
    return switch [a, b] {
      case [Unbounded, v] | [v, Unbounded]: if (kind == Lower) Unbounded else v;
      case [Exlusive(x), Inclusive(y)] if (x == y): if (kind == Lower) b else a;
      case [Inclusive(y), Exlusive(x)] if (x == y): if (kind == Lower) a else b;
      case [Exlusive(x) | Inclusive(x), Exlusive(y) | Inclusive(y)]:
        if (x < y) a;
        else b;
    }      

  static public function max(a:Bound, b:Bound, kind:ExtremumKind)
    return switch [a, b] {
      case [Unbounded, v] | [v, Unbounded]: if (kind == Upper) Unbounded else v;
      case [Exlusive(x), Inclusive(y)] if (x == y): if (kind == Upper) b else a;
      case [Inclusive(y), Exlusive(x)] if (x == y): if (kind == Upper) a else b;
      case [Exlusive(x) | Inclusive(x), Exlusive(y) | Inclusive(y)]:
        if (x > y) a;
        else b;
    }    
}

enum ExtremumKind {
  Upper;
  Lower;
}