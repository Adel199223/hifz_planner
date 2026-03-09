import 'dart:convert';
import 'dart:io';

Never _exitWithError(String message) {
  stderr.writeln(message);
  exitCode = 1;
  throw StateError(message);
}

String _joinPath(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}

String _resolvePathFrom(String baseDir, String candidate) {
  if (candidate.startsWith('/')) {
    return candidate;
  }
  return Directory(baseDir).uri.resolve(candidate).toFilePath();
}

String? _findRepoRootFrom(String startPath) {
  var directory = Directory(startPath);
  while (true) {
    final gitPath = _joinPath(directory.path, '.git');
    if (FileSystemEntity.typeSync(gitPath) != FileSystemEntityType.notFound) {
      return directory.path;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      return null;
    }
    directory = parent;
  }
}

String _findRepoRoot() {
  final candidates = <String?>[
    Platform.environment['PWD'],
    Directory.current.path,
  ];
  for (final candidate in candidates) {
    if (candidate == null || candidate.trim().isEmpty) {
      continue;
    }
    final repoRoot = _findRepoRootFrom(candidate);
    if (repoRoot != null) {
      return repoRoot;
    }
  }
  _exitWithError('Could not locate repository root from current directory.');
}

String _resolveGitDir(String repoRoot) {
  final gitPath = _joinPath(repoRoot, '.git');
  final gitDirectory = Directory(gitPath);
  if (gitDirectory.existsSync()) {
    return gitDirectory.path;
  }

  final gitFile = File(gitPath);
  if (!gitFile.existsSync()) {
    _exitWithError('Missing .git entry under $repoRoot.');
  }

  final content = gitFile.readAsStringSync().trim();
  const prefix = 'gitdir:';
  if (!content.startsWith(prefix)) {
    _exitWithError('Unsupported .git file format at $gitPath.');
  }

  final gitDirValue = content.substring(prefix.length).trim();
  return _resolvePathFrom(repoRoot, gitDirValue);
}

String? _resolveCommonGitDir(String gitDir) {
  final commondirFile = File(_joinPath(gitDir, 'commondir'));
  if (!commondirFile.existsSync()) {
    return null;
  }

  final commondirValue = commondirFile.readAsStringSync().trim();
  if (commondirValue.isEmpty) {
    return null;
  }
  return _resolvePathFrom(gitDir, commondirValue);
}

String? _readGitRefFromDir(String gitDir, String ref) {
  final looseRef = File(_joinPath(gitDir, ref));
  if (looseRef.existsSync()) {
    return looseRef.readAsStringSync().trim();
  }

  final packedRefs = File(_joinPath(gitDir, 'packed-refs'));
  if (packedRefs.existsSync()) {
    for (final line in packedRefs.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('^')) {
        continue;
      }
      final parts = trimmed.split(' ');
      if (parts.length == 2 && parts[1] == ref) {
        return parts[0];
      }
    }
  }

  return null;
}

String _readGitRef(String gitDir, String ref) {
  final localValue = _readGitRefFromDir(gitDir, ref);
  if (localValue != null) {
    return localValue;
  }

  final commonGitDir = _resolveCommonGitDir(gitDir);
  if (commonGitDir != null && commonGitDir != gitDir) {
    final commonValue = _readGitRefFromDir(commonGitDir, ref);
    if (commonValue != null) {
      return commonValue;
    }
  }

  _exitWithError('Could not resolve git ref $ref inside $gitDir.');
}

String _canonicalDisplayPath(String path) {
  const wslLocalhostPrefix = r'\\wsl.localhost\';
  const wslDollarPrefix = r'\\wsl$\';
  if (path.startsWith(wslLocalhostPrefix) || path.startsWith(wslDollarPrefix)) {
    final parts = path.split(r'\').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 3 &&
        (parts[0] == 'wsl.localhost' || parts[0] == 'wsl\$')) {
      return '/${parts.skip(2).join('/')}';
    }
  }
  return path;
}

Map<String, String> _readHeadIdentity(String gitDir) {
  final headFile = File(_joinPath(gitDir, 'HEAD'));
  if (!headFile.existsSync()) {
    _exitWithError('Missing HEAD file inside $gitDir.');
  }

  final headContent = headFile.readAsStringSync().trim();
  if (headContent.startsWith('ref: ')) {
    final ref = headContent.substring(5).trim();
    final branchPrefix = 'refs/heads/';
    final branch =
        ref.startsWith(branchPrefix) ? ref.substring(branchPrefix.length) : ref;
    return <String, String>{
      'branch': branch,
      'head_sha': _readGitRef(gitDir, ref),
    };
  }

  return <String, String>{
    'branch': 'HEAD',
    'head_sha': headContent,
  };
}

void main() {
  final repoRoot = _findRepoRoot();
  final gitDir = _resolveGitDir(repoRoot);
  final identity = _readHeadIdentity(gitDir);
  final displayRepoRoot = _canonicalDisplayPath(repoRoot);
  const workspaceFile = '/home/fa507/dev/hifz_planner-only.code-workspace';

  final packet = <String, String>{
    'worktree_path': displayRepoRoot,
    'branch': identity['branch']!,
    'head_sha': identity['head_sha']!,
    'workspace_file': workspaceFile,
    'workspace_open_command': 'code $workspaceFile',
    'canonical_launch_command': 'cd $displayRepoRoot && flutter run -d windows',
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(packet));
}
