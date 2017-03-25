package tink.semver;

typedef Range = {
  var min(default, never):Bound;
  var max(default, never):Bound;
}

class RangeTools {
  static public function toString(a:Range) {
    return 
      switch [a.min, a.max] {
        case [Closed(a), Closed(b)] if (a == b): '=$a';
        case [Closed(a), Open(b)]: '$a - $b';//TODO: consider simplifying this to the other shortcuts as applicable
        default:
          (switch a.min {
            case Unbounded: '';
            case Open(v): '>$v';
            case Closed(v): '>=$v';
          })
            + ' ' + 
          (switch a.max {
            case Unbounded: '';
            case Open(v): '<$v';
            case Closed(v): '<=$v';
          });     
     }
  }
  static public function merge(a:Range, b:Range):Option<Range> 
    return
      if (a.intersect(b) != None) 
        Some({ min: a.min.min(b.min, Lower), max: a.max.max(b.max, Upper) });
      else 
        None;
    
  static public function contains(r:Range, v:Version) 
    return
      (switch r.min {
        case Unbounded: true;
        case Closed(min): min <= v;
        case Open(min): min < v;
      })
        &&
      (switch r.max {
        case Unbounded: true;
        case Closed(max): max >= v;
        case Open(max): max > v;
      });  
  
  static public function nonEmpty(r:Range) {
    return 
      if (r.min.isLowerThan(r.max)) Some(r);
      else None;
  }

  static public function intersect(a:Range, b:Range):Option<Range> {
    var min = a.min.max(b.min, Lower),
        max = a.max.min(b.max, Upper);
    
    return nonEmpty({ min: min, max: max });
  }        
}