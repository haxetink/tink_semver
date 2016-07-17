package tink.semver;

@:enum abstract Preview(String) {
	var ALPHA = 'alpha';
	var BETA = 'beta';
	var RC = 'rc';
}
