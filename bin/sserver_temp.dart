import 'dart:io';

Future main(List<String> arguments) async {
  final context = SecurityContext();
  final chainFile =
      Platform.script.resolve('.cert/cert_chain.pem').toFilePath();
  final keyFile =
      Platform.script.resolve('.cert/rumaxwell_me.pem').toFilePath();
  print(chainFile);
  print(keyFile);
  context
    ..useCertificateChain(chainFile)
    ..usePrivateKey(keyFile, password: 'Pi=Ru*pk8o2+Ti');

  HttpServer.bindSecure(InternetAddress.anyIPv4, 12029, context).then((server) {
    print('Success: HTTPS server listening at 12029');
    server.listen((HttpRequest request) {
      request.response
        ..write('Hello, world!')
        ..close();
    });
  });
}
