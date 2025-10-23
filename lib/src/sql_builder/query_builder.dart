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

  QueryBuilder whereRaw(String rawCondition) {
    _wheres.add(rawCondition);
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

  ({String query, List<Object?> values}) getFirst() {
    _limit = 1; // Always override the limit
    final result = getAll();
    return (query: result.query, values: result.values);
  }

  ({String query, List<Object?> values}) getLast(
      {String orderByColumn = 'id'}) {
    // Force order by `orderByColumn DESC` if not already defined
    if (_orderBy == null) {
      orderBy(orderByColumn, descending: true);
    } else {
      // Reverse existing order direction
      final parts = _orderBy!.split(' ');
      if (parts.length == 2) {
        final col = parts[0];
        final dir = parts[1].toUpperCase() == 'DESC' ? 'ASC' : 'DESC';
        _orderBy = "$col $dir";
      }
    }

    _limit = 1; // Always override the limit
    final result = getAll();
    return (query: result.query, values: result.values);
  }

  ({String query, List<Object?> values}) getAll() {
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

    final columns = <String>[];
    final placeholders = <String>[];
    final queryValues = <Object?>[];

    values.forEach((key, value) {
      columns.add(key);
      if (value is RawSql) {
        placeholders.add(value.toString());
        queryValues.addAll(value.bindings);
      } else {
        placeholders.add(placeholder);
        queryValues.add(value);
      }
    });

    final query =
        "INSERT INTO $_table (${columns.join(', ')}) VALUES (${placeholders.join(', ')});";

    return (query: query, values: queryValues);
  }

  ({String query, List<Object?> values}) insertBatch(
      List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) throw Exception("No rows provided for batch insert.");

    // Ensure all rows have the same columns
    final columns = rows.first.keys.toList();
    for (final row in rows) {
      if (!row.keys.toSet().containsAll(columns)) {
        throw Exception(
            "All rows must have the same columns for batch insert.");
      }
    }

    final placeholdersList = <String>[];
    final allValues = <Object?>[];

    for (final row in rows) {
      final rowPlaceholders = <String>[];

      for (final col in columns) {
        final value = row[col];
        if (value is RawSql) {
          rowPlaceholders.add(value.toString());
          allValues.addAll(value.bindings);
        } else {
          rowPlaceholders.add(placeholder);
          allValues.add(value);
        }
      }

      placeholdersList.add("(${rowPlaceholders.join(', ')})");
    }

    final query =
        "INSERT INTO $_table (${columns.join(', ')}) VALUES ${placeholdersList.join(', ')};";

    return (query: query, values: allValues);
  }

  ({String query, List<Object?> values}) update(Map<String, dynamic> values) {
    if (values.isEmpty) throw Exception("No update values provided.");

    final setParts = <String>[];
    final queryValues = <Object?>[];

    values.forEach((key, value) {
      if (value is RawSql) {
        setParts.add("$key = ${value.toString()}");
        queryValues.addAll(value.bindings);
      } else {
        setParts.add("$key = $placeholder");
        queryValues.add(value);
      }
    });

    final setClause = setParts.join(', ');
    final queryBase = "UPDATE $_table SET $setClause";

    final combinedConditions = _combineConditions();
    final whereClause =
        combinedConditions.isNotEmpty ? " WHERE $combinedConditions" : "";

    final allValues = [...queryValues, ..._values];
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

extension QueryBuilderCount on QueryBuilder {
  /// Return COUNT(*) of the query
  ({String query, List<Object?> values}) count({String column = '*'}) {
    final selectClause = "COUNT($column) AS total";
    String queryStr = "SELECT $selectClause FROM $_table";

    if (_joins.isNotEmpty) queryStr += ' ${_joins.join(' ')}';

    final conditions = _combineConditions();
    if (conditions.isNotEmpty) queryStr += " WHERE $conditions";

    if (_groupBys.isNotEmpty) queryStr += " GROUP BY ${_groupBys.join(', ')}";
    if (_having != null) queryStr += " HAVING $_having";

    // No orderBy or limit needed for count
    return (query: "$queryStr;", values: _values);
  }
}

class RawSql {
  final String value;
  final List<Object?> bindings;

  const RawSql(this.value, [this.bindings = const []]);

  @override
  String toString() => value;
}
