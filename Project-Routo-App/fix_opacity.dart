import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true);

  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        final newContent = content.replaceAll(RegExp(r'\.withOpacity\((.*?)\)'), r'.withValues(alpha: $1)');
        file.writeAsStringSync(newContent);
        print('Updated ${file.path}');
      }
    }
  }
}
