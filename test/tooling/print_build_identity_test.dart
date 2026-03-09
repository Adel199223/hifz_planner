import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('print_build_identity resolves refs in a normal repo git dir', () async {
    final fixture = Directory.systemTemp.createTempSync(
      'print-build-identity-standard-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    final gitDir = Directory(_join(fixture.path, '.git'))..createSync();
    File(_join(gitDir.path, 'HEAD')).writeAsStringSync('ref: refs/heads/main\n');
    final refsDir = Directory(_join(gitDir.path, 'refs/heads'))
      ..createSync(recursive: true);
    File(_join(refsDir.path, 'main')).writeAsStringSync(
      '1111111111111111111111111111111111111111\n',
    );

    final result = await Process.run(
      'dart',
      <String>[_scriptPath()],
      workingDirectory: fixture.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final packet = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(packet['branch'], 'main');
    expect(packet['head_sha'], '1111111111111111111111111111111111111111');
    expect(packet['worktree_path'], fixture.path);
  });

  test('print_build_identity resolves refs from worktree commondir fallback',
      () async {
    final fixture = Directory.systemTemp.createTempSync(
      'print-build-identity-worktree-',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    final commonGitDir = Directory(_join(fixture.path, 'common/.git'))
      ..createSync(recursive: true);
    final worktreeGitDir = Directory(
      _join(commonGitDir.path, 'worktrees/feature_worktree'),
    )..createSync(recursive: true);

    File(_join(fixture.path, '.git')).writeAsStringSync(
      'gitdir: ${worktreeGitDir.path}\n',
    );
    File(
      _join(worktreeGitDir.path, 'HEAD'),
    ).writeAsStringSync('ref: refs/heads/feat/test-branch\n');
    File(_join(worktreeGitDir.path, 'commondir')).writeAsStringSync('../..\n');

    final refsDir = Directory(_join(commonGitDir.path, 'refs/heads/feat'))
      ..createSync(recursive: true);
    File(_join(refsDir.path, 'test-branch')).writeAsStringSync(
      '2222222222222222222222222222222222222222\n',
    );

    final result = await Process.run(
      'dart',
      <String>[_scriptPath()],
      workingDirectory: fixture.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final packet = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(packet['branch'], 'feat/test-branch');
    expect(packet['head_sha'], '2222222222222222222222222222222222222222');
    expect(packet['worktree_path'], fixture.path);
  });
}

String _scriptPath() {
  return _join(Directory.current.path, 'tooling/print_build_identity.dart');
}

String _join(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
