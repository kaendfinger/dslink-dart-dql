part of dslink.dql.query;

class SinglePathQueryProcessor extends QueryProcessor {
  final QueryContext context;

  String path;

  SinglePathQueryProcessor(this.context);

  @override
  void init(QueryStatement statement) {
    path = statement.argument;
  }

  @override
  QueryStream process(QueryStream stream) {
    Future<QueryUpdate> get() async {
      var node = await context.getRemoteNode(path);
      String displayName = node.configs[r"$name"];
      if (displayName == null) {
        displayName = node.name;
      }

      return new QueryUpdate({
        "path": path
      }, attributes: {
        "node": node,
        ":name": node.name,
        ":displayName": displayName
      });
    }
    return new WrappedQueryStream(stream, new Stream.fromFuture(get()));
  }

  @override
  void calculateColumnSet(Set<String> columns) {
    columns.add("path");
  }

  @override
  String toString() {
    return "Path ${path == null ? 'none' : path}";
  }
}
