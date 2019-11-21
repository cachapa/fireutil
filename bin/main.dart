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
    ..addCommand(StreamCommand())
    ..addCommand(WriteCommand(false))
    ..addCommand(WriteCommand(true))
    ..addCommand(AddCommand())
    ..addCommand(DeleteCommand())
    // ignore: unawaited_futures
    ..run(arguments).catchError((error) {
      if (error is! UsageException) throw error;
      print(error);
      exit(64); // Exit code 64 indicates a usage error.
    }).whenComplete(() => exit(0));
}

class GetCommand extends Command {
  final name = "get";
  final description = "Get a record.";
  final invocation = "[OPTIONS] PATH";

  GetCommand() {
    argParser.addFlag(
      "path",
      abbr: "p",
      negatable: false,
      help: "Print document path",
    );
    argParser.addFlag(
      "data",
      abbr: "d",
      negatable: false,
      help: "Print document data",
    );
  }

  @override
  Future run() async {
    var args = argResults.rest;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var printPath = argResults["path"];
    var printData = argResults["data"];

    var path = args[0];
    try {
      var reference = Firestore.instance.reference(path);
      if (reference is DocumentReference) {
        print(_printDocument(await reference.get(), printPath, printData));
      }
      if (reference is CollectionReference) {
        print((await reference.get())
            .map((document) => _printDocument(document, printPath, printData))
            .toList());
      }
    } catch (e) {
      print(e);
      exit(1);
    }
  }
}

class StreamCommand extends Command {
  final name = "stream";
  final description = "Stream changes to a record.";
  final invocation = "[OPTIONS] PATH";

  StreamCommand() {
    argParser.addFlag(
      "path",
      abbr: "p",
      negatable: false,
      help: "Print document path",
    );
    argParser.addFlag(
      "data",
      abbr: "d",
      negatable: false,
      help: "Print document data",
    );
  }

  @override
  Future run() async {
    var args = argResults.rest;
    if (args.length != 1) {
      printUsage();
      exit(64);
    }

    var printPath = argResults["path"];
    var printData = argResults["data"];

    var path = args[0];
    try {
      var reference = Firestore.instance.reference(path);
      var subscription = reference.runtimeType == DocumentReference
          ? (reference as DocumentReference).stream.listen((document) =>
              print(_printDocument(document, printPath, printData)))
          : (reference as CollectionReference).stream.listen((documents) =>
              print(documents
                  .map((document) =>
                      _printDocument(document, printPath, printData))
                  .toList()));
      // Wait until the stream completes or an interrupt signal is received
      await subscription.asFuture();
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
    var args = argResults.rest;
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
    var args = argResults.rest;
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

class AddCommand extends Command {
  final name = "add";
  final description = "Create a record with a random id.";
  final invocation = "PATH KEY:VALUE...";

  @override
  Future run() async {
    var args = argResults.rest;
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

String _printDocument(Document doc, bool printPath, bool printData) {
  if (printPath == printData) {
    return {"path": doc.path, "data": doc.map}.toString();
  } else if (printPath) {
    return {"path": doc.path}.toString();
  } else {
    return doc.map.toString();
  }
}
