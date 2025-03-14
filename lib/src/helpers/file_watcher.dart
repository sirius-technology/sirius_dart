import 'dart:async';
import 'dart:io';

StreamSubscription<FileSystemEvent>? _watcherListener;
Process? _process;

Future<void> fileWatcher(String entryPath, {Function? callback}) async {
  if (_watcherListener != null) {
    await _watcherListener!.cancel();
  }

  _watcherListener = Directory.current.watch(recursive: true).listen((_) async {
    if (callback != null) {
      await callback();
    }

    // Kill previous process if running
    if (_process != null) {
      _process!.kill();
    }

    // Start a new process and keep it running
    _process = await Process.start(
      'dart',
      ['run', entryPath],
      // runInShell: true,
    );

    // Capture standard output
    _process!.stdout.transform(SystemEncoding().decoder).listen((logs) {
      print(logs);
    });

    // Capture standard error
    _process!.stderr.transform(SystemEncoding().decoder).listen((error) {
      print(error);
    });

    // Handle process exit
    _process!.exitCode.then((code) {
      // print('Process exited with code $code');
    });
  });
}
