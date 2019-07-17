import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:firedart/firedart.dart';

import 'config.dart';

main(List<String> arguments) async {
  FirebaseAuth.initialize(apiKey, FileStore());
  Firestore.initialize(projectId);

  var auth = FirebaseAuth.instance;
  if (!auth.isSignedIn) {
    await auth.signIn(email, password);
  }

  CommandRunner("fireutil", "Utility to manage Firestore databases.")
    ..addCommand(GetCommand())
    ..addCommand(WriteCommand(false))
    ..addCommand(WriteCommand(true))
    ..addCommand(ListCommand())
    ..addCommand(AddCommand())
    ..addCommand(DeleteCommand())
    ..run(arguments).catchError((error) {
      if (error is! UsageException) throw error;
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    }).whenComplete(() => exit(0));
}

class GetCommand extends Command {
  final name = "get";
  final description = "Get a record.";
  final invocation = "PATH";

  @override
  Future run() async {
    var args = argResults.arguments;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var path = args[0];
    try {
      var doc = await Firestore.instance.document(path).get();
      print(doc.map);
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class WriteCommand extends Command {
  final name;
  final description;
  final invocation = "PATH KEY:VALUE...";
  final bool update;

  WriteCommand(this.update)
      : name = update ? "update" : "set",
        description = update ? "Update a record." : "Set a record.";

  @override
  Future run() async {
    var args = argResults.arguments;
    if (args.length < 2) {
      printUsage();
      exit(64);
    }

    var path = args[0];
    var map = <String, dynamic>{};
    for (String entry in args.sublist(1)) {
      var e = entry.split(":");
      if (e.length != 2) {
        print("Invalid keyvalue pair format: $entry");
        exit(1);
      }
      map[e[0]] = e[1];
    }
    try {
      var ref = Firestore.instance.document(path);
      if (update) {
        await ref.update(map);
      } else {
        await ref.set(map);
      }
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class DeleteCommand extends Command {
  final name = "delete";
  final description = "Delete a record.";
  final invocation = "PATH";

  @override
  Future run() async {
    var args = argResults.arguments;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var path = args[0];
    try {
      await Firestore.instance.document(path).delete();
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class ListCommand extends Command {
  final name = "list";
  final description = "List a collection.";
  final invocation = "PATH";

  @override
  Future run() async {
    var args = argResults.arguments;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var path = args[0];
    try {
      var docs = await Firestore.instance.collection(path).get();
      print(docs);
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class AddCommand extends Command {
  final name = "add";
  final description = "Create a record with a random id.";
  final invocation = "PATH KEY:VALUE...";

  @override
  Future run() async {
    var args = argResults.arguments;
    if (args.length < 2) {
      printUsage();
      exit(64);
    }

    var path = args[0];
    var map = <String, dynamic>{};
    for (String entry in args.sublist(1)) {
      var e = entry.split(":");
      if (e.length != 2) {
        print("Invalid keyvalue pair format: $entry");
        exit(1);
      }
      map[e[0]] = e[1];
    }
    try {
      var ref = Firestore.instance.collection(path);
      var doc = await ref.add(map);
      print(doc.path);
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}
