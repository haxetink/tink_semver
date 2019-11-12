package tink.semver;

@:enum abstract Preview(String) {
  
  var ALPHA = 'alpha';
  var BETA = 'beta';
  var RC = 'rc';

  static public function ofString(s:String) 
    return switch (cast s:Preview) {
      case ALPHA: Success(ALPHA);
      case BETA: Success(BETA);
      case RC: Success(RC);
      default: Failure(new Error(UnprocessableEntity, '$s should be alpha | beta | rc'));
    }
}
