import 'dart:convert';
import 'dart:typed_data';

final _webMemoryFileSystem = _WebMemoryFileSystem();

class Directory {
  Directory(String path) : path = _webMemoryFileSystem.normalize(path);

  final String path;

  Future<void> create({bool recursive = false}) async {
    _webMemoryFileSystem.ensureDirectory(path);
  }

  Future<bool> exists() async => _webMemoryFileSystem.directoryExists(path);

  Future<void> delete({bool recursive = false}) async {
    _webMemoryFileSystem.deleteDirectory(path, recursive: recursive);
  }
}

class File {
  File(String path) : path = _webMemoryFileSystem.normalize(path);

  final String path;

  Directory get parent {
    final index = path.lastIndexOf('/');
    if (index <= 0) {
      return Directory('/');
    }
    return Directory(path.substring(0, index));
  }

  Uri get uri => Uri.parse(path.startsWith('/') ? 'memory://$path' : path);

  Future<bool> exists() async => _webMemoryFileSystem.fileExists(path);

  Future<String> readAsString() async {
    final bytes = _webMemoryFileSystem.read(path);
    return utf8.decode(bytes);
  }

  Future<Uint8List> readAsBytes() async {
    return Uint8List.fromList(_webMemoryFileSystem.read(path));
  }

  Future<void> writeAsString(String value, {bool flush = false}) async {
    _webMemoryFileSystem.write(path, utf8.encode(value));
  }

  Future<void> writeAsBytes(List<int> value, {bool flush = false}) async {
    _webMemoryFileSystem.write(path, value);
  }

  Future<void> delete() async {
    _webMemoryFileSystem.delete(path);
  }

  Future<File> rename(String newPath) async {
    final normalized = _webMemoryFileSystem.normalize(newPath);
    _webMemoryFileSystem.rename(path, normalized);
    return File(normalized);
  }
}

class HttpException implements Exception {
  HttpException(this.message, {this.uri});

  final String message;
  final Uri? uri;

  @override
  String toString() {
    if (uri == null) {
      return message;
    }
    return '$message (${uri.toString()})';
  }
}

abstract final class HttpStatus {
  static const int ok = 200;
}

abstract final class Platform {
  static const String pathSeparator = '/';
}

Future<Directory> getApplicationSupportDirectory() async {
  final dir = Directory('/app_support');
  await dir.create(recursive: true);
  return dir;
}

class _WebMemoryFileSystem {
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final Set<String> _directories = <String>{'/', '/app_support'};

  String normalize(String rawPath) {
    final replaced = rawPath.replaceAll('\\', '/').trim();
    if (replaced.isEmpty) {
      return '/';
    }
    final hasScheme = replaced.contains('://');
    final collapsed = replaced.replaceAll(RegExp('/+'), '/');
    if (hasScheme) {
      return collapsed;
    }
    return collapsed.startsWith('/') ? collapsed : '/$collapsed';
  }

  void ensureDirectory(String path) {
    final normalized = normalize(path);
    if (normalized == '/') {
      _directories.add('/');
      return;
    }
    final segments = normalized.split('/');
    var current = '';
    for (final segment in segments) {
      if (segment.isEmpty) {
        continue;
      }
      current += '/$segment';
      _directories.add(current);
    }
  }

  bool directoryExists(String path) => _directories.contains(normalize(path));

  bool fileExists(String path) => _files.containsKey(normalize(path));

  List<int> read(String path) {
    final normalized = normalize(path);
    final bytes = _files[normalized];
    if (bytes == null) {
      throw StateError('No such file: $normalized');
    }
    return bytes;
  }

  void write(String path, List<int> bytes) {
    final normalized = normalize(path);
    ensureDirectory(File(normalized).parent.path);
    _files[normalized] = Uint8List.fromList(bytes);
  }

  void delete(String path) {
    _files.remove(normalize(path));
  }

  void rename(String from, String to) {
    final source = normalize(from);
    final target = normalize(to);
    final bytes = _files.remove(source);
    if (bytes == null) {
      throw StateError('No such file: $source');
    }
    write(target, bytes);
  }

  void deleteDirectory(String path, {required bool recursive}) {
    final normalized = normalize(path);
    if (!recursive) {
      _directories.remove(normalized);
      return;
    }
    final prefix = normalized.endsWith('/') ? normalized : '$normalized/';
    _directories.removeWhere((entry) => entry == normalized || entry.startsWith(prefix));
    _files.removeWhere((entry, _) => entry == normalized || entry.startsWith(prefix));
  }
}
