package tink.semver;

enum Bound {
  Unbounded;
  Open(limit:Version);
  Closed(limit:Version);
}

class BoundTools {

  static public function isLowerThan(a:Bound, b:Bound) 
    return
      switch [a, b] {
        case [Open(a), Open(b) | Closed(b)] if (a == b): false;
        case [Open(a) | Closed(a), Open(b) | Closed(b)] if (a > b): false;
        default: true;
      }

  static public function min(a:Bound, b:Bound, kind:ExtremumKind)
    return switch [a, b] {
      case [Unbounded, v] | [v, Unbounded]: if (kind == Lower) Unbounded else v;
      case [Open(x), Closed(y)] if (x == y): if (kind == Lower) b else a;
      case [Closed(y), Open(x)] if (x == y): if (kind == Lower) a else b;
      case [Open(x) | Closed(x), Open(y) | Closed(y)]:
        if (x < y) a;
        else b;
    }      

  static public function max(a:Bound, b:Bound, kind:ExtremumKind)
    return switch [a, b] {
      case [Unbounded, v] | [v, Unbounded]: if (kind == Upper) Unbounded else v;
      case [Open(x), Closed(y)] if (x == y): if (kind == Upper) b else a;
      case [Closed(y), Open(x)] if (x == y): if (kind == Upper) a else b;
      case [Open(x) | Closed(x), Open(y) | Closed(y)]:
        if (x > y) a;
        else b;
    }    
}

enum ExtremumKind {
  Upper;
  Lower;
}