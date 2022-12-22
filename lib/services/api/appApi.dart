import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/util.dart';
import '../localAuthentication.dart';

abstract class AppApi {
  Authentication authentication = new Authentication();
  bool isJsonResponseOk(Map jsonResult) {
    bool retValue = (jsonResult.containsKey('Error') &&
            jsonResult['Error'].containsKey('Code')) &&
        jsonResult['Error']['Code'] == '0';

    return retValue;
  }

  bool isContentInResponse(Map jsonResult) {
    bool retValue = jsonResult.containsKey('Content');
    return retValue;
  }

  bool isTileRequestError(Map jsonResult) {
    bool retValue = jsonResult.containsKey('Error') &&
        jsonResult['Error'].containsKey('Code') &&
        jsonResult['Error']['Code'] != '0';
    return retValue;
  }

  Future<Map<String, String>> injectRequestParams(Map jsonMap) async {
    Map<String, String> requestParams = Map.from(jsonMap);
    Position position = Utility.getDefaultPosition();
    bool isLocationVerified = false;
    try {
      Position initialPosition = position;
      isLocationVerified = true;
      position = await Utility.determineDevicePosition().catchError((onError) {
        isLocationVerified = false;
        print('Tiler app: failed to pull device location.');
        print(onError);
        return initialPosition;
      });
    } catch (e) {
      print('Tiler app error in getting location');
      print(e);
    }
    requestParams['TimeZoneOffset'] = Utility.getTimeZoneOffset().toString();
    requestParams['MobileApp'] = true.toString();
    requestParams['UserLongitude'] = position.longitude.toString();
    requestParams['UserLatitude'] = position.latitude.toString();
    requestParams['UserLocationVerified'] = (isLocationVerified).toString();
    return requestParams;
  }

  getHeaders() {
    if (authentication.cachedCredentials != null &&
        !authentication.cachedCredentials!.isExpired()) {
      var cachedCredentials = authentication.cachedCredentials!;
      String token = cachedCredentials.accessToken;
      var header = {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ' + token,
      };

      return header;
    }

    return null;
  }
}
