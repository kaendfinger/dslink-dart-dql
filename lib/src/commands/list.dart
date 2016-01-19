part of dslink.dql.query;

class ListNodeQueryProcessor extends QueryProcessor {
  final QueryContext context;

  ListNodeQueryProcessor(this.context);

  PathExpression expression;

  @override
  void init(QueryStatement statement) {
    expression = parseExpressionInput(statement.argument);
  }

  @override
  Stream<QueryUpdate> bind(Stream<QueryUpdate> stream) {
    var subs = <String, StreamSubscription>{};
    var dones = <String, Function>{};
    Set<String> uids = new Set<String>();
    StreamController<QueryUpdate> controller;

    controller = new StreamController<QueryUpdate>(onListen: () {
      void handle(String path) {
        Path p = new Path(path);

        String uid;
        if (subs[path] is! StreamSubscription) {
          var onDone = ([bool isUidSame = false]) {
            if (!isUidSame && uid != null) {
              uids.remove(uid);
            }

            if (subs.containsKey(path)) {
              StreamSubscription sub = subs.remove(path);
              if (sub != null) {
                sub.cancel();
              }

              dones.remove(path);

              QueryUpdate update = new QueryUpdate({
                "path": path
              }, remove: true);
              controller.add(update);
            }
          };

          dones[path] = onDone;

          subs[path] = context.requester.list(path).listen((RequesterListUpdate update) {
            if (p.parentPath.endsWith("/upstream") && update.node.configs[r"$uid"] == null) {
              onDone();
              return;
            }

            for (String change in update.changes) {
              if (change.startsWith(r"$") || change.startsWith("@")) {
                continue;
              }

              if (!update.node.children.containsKey(change)) {
                String cp = path;
                if (!cp.endsWith("/")) {
                  cp += "/";
                }
                cp += change;
                if (dones.containsKey(cp)) {
                  dones[cp]();
                }
              }
            }

            if (update.node.configs[r"$uid"] is String) {
              uid = update.node.configs[r"$uid"];
              if (uids.contains(uid)) {
                onDone(true);
                return;
              }
              uids.add(uid);
            }

            for (RemoteNode child in update.node.children.values) {
              handle(child.remotePath);
            }

            QueryUpdate event = new QueryUpdate({
              "path": path
            }, attributes: {
              "node": update.node
            });

            controller.add(event);
          }, onDone: () {
            if (dones.containsKey(path)) {
              dones[path]();
            }
          });
        }
      }

      handle(expression.topmost);
    }, onCancel: () {
      for (var sub in subs.values) {
        sub.cancel();
      }
      subs.clear();
      uids.clear();
    });

    return controller.stream;
  }
}