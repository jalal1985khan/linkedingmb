class ApiConfig {
  static const String baseUrl = 'https://api.socialhive.pro';
  static const String googleLoginUrl = '$baseUrl/api/auth/google/login';
  static const String gmbApiLandingUrl = 'https://app.gmbapi.com/';
  static const String gmbApiAccessLink =
      'https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fbusiness.manage&state=eyJ1aWQiOiI3MTlmMTBhNi05ZmNjLTQ1YTktYTNlMC1iYjJiNWRjYTA2YzQiLCJvcmlnaW4iOiJhcHAuZ21iYXBpLmNvbSJ9&response_type=code&client_id=895826110070-g10dnvd1qdp9e4khf8d7j0bqgubi7nkm.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fapp.gmbapi.com%2Fapi%2Fgoogle%2Fauth%2Fonboarding%2Flink%2Fcallback%2F';
}
