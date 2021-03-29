import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:meta/meta.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:webview_flutter/webview_flutter.dart';

final authorizationEndpoint = 'https://login.eveonline.com/v2/oauth/authorize';
final tokenEndpoint = 'https://login.eveonline.com/v2/oauth/token';
final clientId = '3f6333510f7142a2999ede7c4c469b0f';
final secret = 'MwYjfNkToO7KgB5OeB7G4GOGKr4sHRIG393dmtps';
final redirectUrl = 'eveauth.flutter.test://callback';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => authorizeFlutterAppAuth().then((t) {
              var test = t;
            }),
            child: Text("Flutter appauth"),
          ),
          TextButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => LoginPage())),
            child: Text("Flutter oauth2 scratch"),
          ),
          TextButton(
            onPressed: () => authorizeoAuth2().then((t) {
              var test = t;
            }),
            child: Text("Flutter webauth"),
          )
        ],
      ),
    );
  }
}

Future<String> authorizeoAuth2() async {
  var grant = oauth2.AuthorizationCodeGrant(
    clientId,
    Uri.parse(authorizationEndpoint),
    Uri.parse(tokenEndpoint),
    secret: secret,
  );

  var authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectUrl),
      state: "fe9e61ce-2ad3-4af8-8ab9-13c35506cec4");
  await redirect(authorizationUrl);
  var responseUrl = await listen(Uri.parse(redirectUrl));
}

Future<void> redirect(Uri url) async {
  await launch(url.toString());
}

Future<void> listen(Uri url) async {
  print(url);
  if (url.toString().contains("code")) print(true);
}

Future<String> authorizeFlutterAppAuth() async {
  final FlutterAppAuth appAuth = FlutterAppAuth();
  final AuthorizationTokenResponse result =
      await appAuth.authorizeAndExchangeCode(
    AuthorizationTokenRequest(
      "3f6333510f7142a2999ede7c4c469b0f",
      "eveauth.flutter.test://callback",
      clientSecret: "MwYjfNkToO7KgB5OeB7G4GOGKr4sHRIG393dmtps",
      serviceConfiguration: serviceConfiguration(),
    ),
  );
  var test = result.accessToken;
  print("Flutter APP AUTH - ACCESS TOKEN : $test");
}

AuthorizationServiceConfiguration serviceConfiguration() {
  return AuthorizationServiceConfiguration(
      "https://login.eveonline.com/v2/oauth/authorize",
      "https://login.eveonline.com/v2/oauth/token");
}

Future<String> authorizeFlutterWebAuth() async {
  final url = Uri.https('login.eveonline.com', '/v2/oauth/authorize', {
    'response_type': 'code',
    'client_id': clientId,
    'secret': secret,
    'redirect_uri': '$redirectUrl://callback',
    'state': 'fe9e61ce-2ad3-4af8-8ab9-13c35506cec4',
    //https://login.eveonline.com/account/characterselection?state=18643f4a-8693-4b12-8f18-4b91a4f8235c
  });
  final result = await FlutterWebAuth.authenticate(
    url: url.toString(),
    callbackUrlScheme: redirectUrl,
  );

  final code = Uri.parse(result).queryParameters['code'];
  var test = Uri.parse(result);
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  oauth2.AuthorizationCodeGrant grant;
  oauth2.Client _client;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  Uri _uri;

  @override
  void initState() {
    super.initState();
    grant = oauth2.AuthorizationCodeGrant(
        clientId, Uri.parse(authorizationEndpoint), Uri.parse(tokenEndpoint),
        secret: secret);
    _uri = grant.getAuthorizationUrl(Uri.parse(redirectUrl),
        state: "fe9e61ce-2ad3-4af8-8ab9-13c35506cec4");
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webview'),
      ),
      body: Builder(builder: (BuildContext context) {
        return WebView(
          javascriptMode: JavascriptMode.unrestricted,
          initialUrl: _uri.toString(),
          navigationDelegate: (navReq) {
            if (navReq.url.startsWith(redirectUrl)) {
              print(
                  ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${Uri.parse(navReq.url)}");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        );
      }),
    );
  }
}

Uri addQueryParameters(Uri url, Map<String, String> parameters) => url.replace(
    queryParameters: new Map.from(url.queryParameters)..addAll(parameters));
