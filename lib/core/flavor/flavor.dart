const kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

bool get isDev => kFlavor == 'dev';
bool get isUat => kFlavor == 'uat';
bool get isProd => kFlavor == 'prod';