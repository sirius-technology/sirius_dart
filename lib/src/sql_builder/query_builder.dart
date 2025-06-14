class QueryBuilder {
  QueryBuilder(this._table);

  final String _table;

  static String placeholder = "?";

  final List<String> _selects = [];
  final List<String> _joins = [];
  final List<String> _wheres = [];
  final List<String> _orWheres = [];
  final List<String> _likes = [];
  final List<String> _orLikes = [];
  final List<String> _groupBys = [];

  String? _having;
  String? _orderBy;
  int? _limit;

  final List<Object?> _values = [];

  QueryBuilder select(List<String> columns) {
    _selects.addAll(columns);
    return this;
  }

  QueryBuilder join(String table, String condition, {String type = 'INNER'}) {
    _joins.add("$type JOIN $table ON $condition");
    return this;
  }

  QueryBuilder where(String column, dynamic value) {
    _wheres.add("$column = $placeholder");
    _values.add(value);
    return this;
  }

  QueryBuilder orWhere(String column, dynamic value) {
    _orWheres.add("$column = $placeholder");
    _values.add(value);
    return this;
  }

  QueryBuilder whereIn(String column, List<dynamic> values) {
    final placeholders = List.filled(values.length, placeholder).join(', ');
    _wheres.add("$column IN ($placeholders)");
    _values.addAll(values);
    return this;
  }

  QueryBuilder whereNotIn(String column, List<dynamic> values) {
    final placeholders = List.filled(values.length, placeholder).join(', ');
    _wheres.add("$column NOT IN ($placeholders)");
    _values.addAll(values);
    return this;
  }

  QueryBuilder like(String column, String pattern) {
    _likes.add("$column LIKE $placeholder");
    _values.add(pattern);
    return this;
  }

  QueryBuilder orLike(String column, String pattern) {
    _orLikes.add("$column LIKE $placeholder");
    _values.add(pattern);
    return this;
  }

  QueryBuilder groupBy(String column) {
    _groupBys.add(column);
    return this;
  }

  QueryBuilder having(String condition) {
    _having = condition;
    return this;
  }

  QueryBuilder orderBy(String column, {bool descending = false}) {
    _orderBy = "$column ${descending ? 'DESC' : 'ASC'}";
    return this;
  }

  QueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  ({String query, List<Object?> values}) get() {
    final selectClause = _selects.isEmpty ? '*' : _selects.join(', ');
    String query = "SELECT $selectClause FROM $_table";

    if (_joins.isNotEmpty) query += ' ${_joins.join(' ')}';

    final conditions = _combineConditions();
    if (conditions.isNotEmpty) query += " WHERE $conditions";

    if (_groupBys.isNotEmpty) query += " GROUP BY ${_groupBys.join(', ')}";
    if (_having != null) query += " HAVING $_having";
    if (_orderBy != null) query += " ORDER BY $_orderBy";
    if (_limit != null) query += " LIMIT $_limit";

    return (query: "$query;", values: _values);
  }

  ({String query, List<Object?> values}) insert(Map<String, dynamic> values) {
    if (values.isEmpty) throw Exception("No insert values provided.");

    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, placeholder).join(', ');
    final query = "INSERT INTO $_table ($columns) VALUES ($placeholders);";

    return (query: query, values: values.values.toList());
  }

  ({String query, List<Object?> values}) update(Map<String, dynamic> values) {
    if (values.isEmpty) throw Exception("No update values provided.");

    final setClause =
        values.entries.map((e) => "${e.key} = $placeholder").join(', ');
    final queryBase = "UPDATE $_table SET $setClause";

    final combinedConditions = _combineConditions();
    final whereClause =
        combinedConditions.isNotEmpty ? " WHERE $combinedConditions" : "";

    final allValues = [...values.values, ..._values];
    return (query: "$queryBase$whereClause;", values: allValues);
  }

  ({String query, List<Object?> values}) delete() {
    final base = "DELETE FROM $_table";
    final conditions = _combineConditions();
    final whereClause = conditions.isNotEmpty ? " WHERE $conditions" : "";
    return (query: "$base$whereClause;", values: _values);
  }

  String _combineConditions() {
    final conditions = <String>[];

    if (_wheres.isNotEmpty) conditions.addAll(_wheres);
    if (_orWheres.isNotEmpty) conditions.add("(${_orWheres.join(" OR ")})");
    if (_likes.isNotEmpty) conditions.addAll(_likes);
    if (_orLikes.isNotEmpty) conditions.add("(${_orLikes.join(" OR ")})");

    return conditions.join(" AND ");
  }
}
