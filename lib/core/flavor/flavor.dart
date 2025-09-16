const kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

bool get isDev => kFlavor == 'dev';
bool get isStg => kFlavor == 'staging';
bool get isProd => kFlavor == 'prod';