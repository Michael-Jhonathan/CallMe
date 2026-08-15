import 'dart:io';

void main() async {
  final server = await HttpServer.bind('127.0.0.1', 8085);
  print('Server listening on port 8085');
  await for (HttpRequest request in server) {
    if (request.method == 'POST') {
      final bytes = await request.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      final file = File('assets/icon.png');
      await file.writeAsBytes(bytes);
      print('Saved icon.png!');
      request.response.write('OK');
      request.response.close();
      exit(0);
    }
  }
}
