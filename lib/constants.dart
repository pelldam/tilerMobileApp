const bool isProduction = false;
const bool isDebug = true;
// const String remoteDomain = isDebug ? '10.0.2.2:44322' : 'www.tiler.app';
const String remoteDomain =
    isDebug ? 'tilerfront.conveyor.cloud' : 'www.tiler.app';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int autoScrollBuffer = 50;
