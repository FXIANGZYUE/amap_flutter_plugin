class WebLocationHelper {
  Future<Map<String, dynamic>> getCurrentPosition() async {
    return {'errorCode': -1, 'errorInfo': 'Web geolocation not supported'};
  }

  int watchPosition(void Function(Map<String, dynamic>) callback) => -1;

  void clearWatch(int watchId) {}
}
