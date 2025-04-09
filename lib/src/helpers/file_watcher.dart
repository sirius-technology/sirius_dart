import 'dart:async';
import 'dart:io';

StreamSubscription<FileSystemEvent>? _watcherListener;
Process? _process;

/// Watches the current directory for file changes and restarts a Dart process.
///
/// This utility is useful during development to automatically restart a Dart
/// application whenever a file changes. It listens to file system events and,
/// upon detecting any change, kills the previous process (if running) and starts
/// a new Dart process using the given [entryPath].
///
/// Optionally, a [callback] can be provided, which will be executed before
/// starting the new process.
///
/// The watcher listens recursively in the current working directory.
///
/// ### Example:
/// ```dart
/// void main() {
///   fileWatcher('bin/server.dart', callback: () {
///     print('🔄 Detected file change, restarting...');
///   });
/// }
/// ```
///
/// This would monitor the project and restart `bin/server.dart` whenever any
/// file is changed.
///
/// > Note: This is intended for development use only.
///
/// - [entryPath]: The path to the Dart file to run when changes are detected.
/// - [callback]: Optional function to execute before restarting the process.
Future<void> fileWatcher(String entryPath, {Function? callback}) async {
  // Cancel existing watcher if active
  if (_watcherListener != null) {
    await _watcherListener!.cancel();
  }

  // Listen for file changes recursively
  _watcherListener = Directory.current.watch(recursive: true).listen((_) async {
    if (callback != null) {
      await callback();
    }

    // Kill the previous process if it exists
    if (_process != null) {
      _process!.kill();
    }

    // Start a new Dart process
    _process = await Process.start(
      'dart',
      ['run', entryPath],
      // Uncomment to run in shell if needed:
      // runInShell: true,
    );

    // Pipe stdout to console
    _process!.stdout.transform(SystemEncoding().decoder).listen((logs) {
      print(logs);
    });

    // Pipe stderr to console
    _process!.stderr.transform(SystemEncoding().decoder).listen((error) {
      print(error);
    });

    // Optionally handle exit codes (currently ignored)
    _process!.exitCode.then((code) {
      // print('Process exited with code $code');
    });
  });
}
