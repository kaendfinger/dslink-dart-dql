part of dslink.dql.query;

class SubscribeQueryHolder {
  Map<String, dynamic> values = {};
  Map<String, StreamSubscription> subs = {};
  QueryUpdate lastUpdate;

  void cancel() {
    for (StreamSubscription sub in subs.values) {
      sub.cancel();
    }
    subs.clear();
  }

  QueryUpdate build() {
    QueryUpdate u = lastUpdate;
    if (u == null) {
      u = new QueryUpdate({});
    }

    u.values.addAll(values);

    return u;
  }
}

class SubscribeQueryProcessor extends QueryProcessor {
  final QueryContext context;

  List<String> childs;

  SubscribeQueryProcessor(this.context);

  @override
  void init(QueryStatement statement) {
    childs = statement.argument.split(" ").map((x) => x.trim()).where((String n) {
      return n.isNotEmpty;
    }).toList();

    if (childs.isEmpty) {
      childs = ["value"];
    }
  }

  @override
  Stream<QueryUpdate> bind(Stream<QueryUpdate> stream) {
    Map<String, SubscribeQueryHolder> holders = {};
    StreamController<QueryUpdate> controller;
    StreamSubscription sub;
    controller = new StreamController<QueryUpdate>(onListen: () {
      sub = stream.listen((QueryUpdate update) {
        String path = update.values["path"];
        if (update.remove) {
          if (holders.containsKey(path)) {
            holders.remove(path).cancel();
          }
          controller.add(update);
          return;
        }

        if (!holders.containsKey(path)) {
          QueryUpdate out = update.clone();
          var holder = new SubscribeQueryHolder();
          holder.lastUpdate = update;

          for (String n in childs) {
            String cp = path;
            if (!n.startsWith("/")) {
              cp += "/";
            }
            cp += n;
            out.values[n] = holder.values[n] = null;
            if (n.startsWith("@") || n.startsWith(r"$")) {
              holder.subs[n] = context.requester.list(path).listen((
                RequesterListUpdate update) {
                if (holder.values[n] != update.node.get(n)) {
                  holder.values[n] = update.node.get(n);
                  controller.add(holder.build());
                }
              });
            } else if (n == "value") {
              holder.subs[n] =
                context.requester.subscribe(path, (ValueUpdate update) {
                  holder.values[n] = update.value;
                  controller.add(holder.build());
                });
            } else if (n == "value.timestamp") {
              holder.subs[n] =
                context.requester.subscribe(path, (ValueUpdate update) {
                  holder.values[n] = update.ts;
                  controller.add(holder.build());
                });
            } else {
              holder.subs[n] = context.requester.subscribe(cp, (ValueUpdate update) {
                holder.values[n] = update.value;
                controller.add(holder.build());
              });
            }
          }

          controller.add(update.cloneAndStub(childs));

          holders[path] = holder;
        } else {
          holders[path].lastUpdate = update;
          controller.add(update.cloneAndMerge(holders[path].values));
        }
      });
    }, onCancel: () {
      for (SubscribeQueryHolder holder in holders.values) {
        holder.cancel();
      }

      holders.clear();

      if (sub != null) {
        sub.cancel();
      }
    });

    return controller.stream;
  }
}