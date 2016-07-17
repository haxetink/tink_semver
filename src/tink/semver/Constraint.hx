package tink.semver;

import tink.semver.Version;

using tink.CoreApi;
using StringTools;

abstract Constraint(Null<ConstraintData>) from ConstraintData {

	public function isSatisfiedBy(v:Version) 
		return
			switch this {
				case null: true;
				case Eq(to): v == to;
				case Gt(than, Strictly): v > than;
				case Lt(than, Strictly): v < than;
				case Gt(than, OrEqual): v >= than;
				case Lt(than, OrEqual): v <= than;
				case And(a, b): 
					a.isSatisfiedBy(v) && b.isSatisfiedBy(v);
				case Or(a, b): 
					a.isSatisfiedBy(v) || b.isSatisfiedBy(v);
				case None: false;
				case Custom(f): f(v);
			}
	
	@:to public function toString() 
		return switch this {
			case null: '*';
			case Eq(to): '=$to';
			case Gt(than, Strictly): '>$than';
			case Lt(than, Strictly): '<$than';
			case Gt(than, OrEqual): '>=$than';
			case Lt(than, OrEqual): '<=$than';
			case And(a, b): 
				'($a && $b)';
			case Or(a, b): 
				'($a || $b)';
			case None: '<0.0.0';
			case Custom(f): '#custom';
			
		}
			
	static public function parse(s:String)
		return 
			switch s {
				case null, '', '*': Success(null);
				default:
					(function () return join(Or, s.split('||').map(parseSet)))
						.catchExceptions(Version.reportError);
			}
	
	static function join(f:Constraint->Constraint->Constraint, parts:Array<Constraint>) {
		var ret = parts[0];
		for (p in parts.slice(1))
			ret = f(ret, p);
		return ret;
	}
	
	static function tokenize(s:String):Array<String> {
		var ret = [];
		var buf = new StringBuf();
		function flush()
			switch buf.toString() {
				case '':
				case v: 
					ret.push(v);
					buf = new StringBuf();
			}
			
		for (i in 0...s.length)
			if (s.isSpace(i))
				flush();
			else
				buf.addChar(s.fastCodeAt(i));
		flush();		
		return ret;
	}
	
	static function parseSet(s:String):Constraint {
		var parts = tokenize(s),
				i = 0;
		
		var ret = [
			while (i < parts.length) 
				switch [parts[i], parts[++i]] {
					case ['-', v]:
						throw 'invalid "- $v"';
					case [from, '-']:
						var to = parts[++i];
						if (to == null)
							throw 'unterminated hyphen range "$from -"';
						And(
							Gt(Version.parse(from).sure(), OrEqual),
							Lt(Version.parse(to).sure(), OrEqual)
						);
					case [v, _]:
						parsePart(v);
				}
		];
		
		return join(And, ret);
	}
	
	static function parsePart(s:String):Constraint {
		
		for (op in ops)
			if (s.startsWith(op.op)) 
				return op.make(Version.parse(s.substr(op.op.length).trim()).sure());
				
		return Eq(Version.parse(s).sure());
	}
	
	static var ops = {
		var ret = [];
		function add(op:String, f:Version->ConstraintData) 
			ret.push({ op: op, make: f});
		add('=', Eq);
		add('>=', Gt.bind(_, OrEqual));
		add('<=', Lt.bind(_, OrEqual));
		add('>', Gt.bind(_, Strictly));
		add('<', Lt.bind(_, Strictly));
		add('+', function (v) return And(Gt(v, OrEqual), Lt(v.nextMajor(), Strictly)));
		ret;
	}
  
  @:from static function ofVersion(v:Version):Constraint
    return 
      switch v {
        case { preview: ALPHA | BETA | RC }: Eq(v);
        case { major: 0 } : v...v.nextMinor();
        default: v...v.nextMajor();
      }
}

enum ConstraintData {
  Eq(ver : Version);
  
	Gt(ver : Version, s:Strictness);
  Lt(ver : Version, s:Strictness);
	
  And(a : Constraint, b : Constraint);
  Or(a : Constraint, b : Constraint);
	
	None;
	
	Custom(f:Version->Bool);
}

enum Strictness {
	Strictly;
	OrEqual;
}