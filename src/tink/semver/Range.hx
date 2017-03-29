package tink.semver;

typedef Range = {
  var min(default, never):Bound;
  var max(default, never):Bound;
}

class RangeTools {
  static public function toString(a:Range) {
    return 
      switch [a.min, a.max] {
        case [Inclusive(a), Inclusive(b)]:
          if (a == b) '=$a' else '$a - $b';
        case [Inclusive(min), Exlusive(max)] if (min.nextMajor() == max && min.major > 0):
          '^$min';
        case [Inclusive(min), Exlusive(max)] if (min.nextMinor() == max && min.major == 0):
          '^$min';
        default:
          (switch a.min {
            case Unbounded: '';
            case Exlusive(v): '>$v';
            case Inclusive(v): '>=$v';
          })
            + ' ' + 
          (switch a.max {
            case Unbounded: '';
            case Exlusive(v): '<$v';
            case Inclusive(v): '<=$v';
          });     
     }
  }
  static public function merge(a:Range, b:Range):Option<Range> 
    return
      switch [a, b] {
        case [{ min: min, max: Exlusive(v1) }, { min: Inclusive(v2), max: max}]
           | [{ min: min, max: Inclusive(v1) }, { min: Exlusive(v2), max: max}]
           | [{ min: Inclusive(v1), max: max}, { min: min, max: Exlusive(v2) }]
           | [{ min: Exlusive(v1), max: max}, { min: min, max: Inclusive(v2) }] if (v1 == v2): Some({ min: min, max: max });
        default:
          if (a.intersect(b) != None) 
            Some({ min: a.min.min(b.min, Lower), max: a.max.max(b.max, Upper) });
          else 
            None;        
      }
    
  static public function contains(r:Range, v:Version) 
    return
      (switch r.min {
        case Unbounded: true;
        case Inclusive(min): min <= v;
        case Exlusive(min): min < v;
      })
        &&
      (switch r.max {
        case Unbounded: true;
        case Inclusive(max): max >= v;
        case Exlusive(max): max > v;
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