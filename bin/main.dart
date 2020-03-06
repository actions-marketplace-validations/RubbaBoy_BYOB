import 'dart:convert';
import 'dart:io';

Directory workingDir;

void main(List<String> args) {
  final name = args[0];
  final label = args[1];
  final status = args[2];
  final color = args[3];
  var path = args[4];
  final token = args[5];
  final branch = args[6];

  if (!path.startsWith('/')) {
    path = '/$path';
  }

  final env = Platform.environment;
  final remote =
      'https://${env['GITHUB_ACTOR']}:$token@github.com/${env['GITHUB_REPOSITORY']}.git';

  workingDir = Directory('${Directory.current.absolute.path}/repo');

  cloneRepo(branch, remote);

  final shields = workingDir.listSync().firstWhere(
      (entity) => entity.path.replaceFirst(workingDir.path, '') == path,
      orElse: () => File('${workingDir.path}$path')
        ..parent.createSync()
        ..createSync()) as File;

  final contents = safeDecode(shields.readAsStringSync());

  contents[name] = {'label': label, 'status': status, 'color': color};

  shields.writeAsStringSync(jsonEncode(contents));

  runCommand('git', ['config', '--local', 'user.email', 'byob@yarr.is']);
  runCommand('git', ['config', '--local', 'user.name', 'BYOB']);
  runCommand('git', ['add', '.']);
  runCommand('git', ['commit', '-m', 'Updating tag "$name"']);
  runCommand('git', ['push', remote, branch]);
}

void cloneRepo(String branch, String remote) {
  print(runCommand('git', ['clone', remote, 'repo'], false));

  final branches = runCommand('git', ['branch', '-a']);
  final bran = branches.split('\n').map((line) => line.substring(2)).toList();
  print('bran = $bran');
  if (bran.contains(branch)) {
    print('Branch "$branch" exists! Checking out...');
    print(runCommand('git', ['checkout', branch]));
  } else {
    print('Branch "$branch" not existant! Creating orphan...');
    print(runCommand('git', ['checkout', '--orphan', branch]));
    print(runCommand('git', ['rm', '-rf', '.']));
  }

  print('Done with repo stuff');
}

String runCommand(String cmd, List<String> args,
    [bool includeWorkingDir = true]) {
  final process = includeWorkingDir
      ? Process.runSync(cmd, args, workingDirectory: workingDir.absolute.path)
      : Process.runSync(cmd, args);
  print(process.stderr);
  return process.stdout;
}

dynamic safeDecode(String json) {
  try {
    return jsonDecode(json);
  } catch (_) {
    return {};
  }
}
