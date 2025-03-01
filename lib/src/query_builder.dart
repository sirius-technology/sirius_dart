class QueryBuilder {
  QueryBuilder(this._table);

  final String _table;
  String _query = "";
  List<String> _selectFields = [];
  final List<String> _whereFields = [];
  final List<dynamic> _whereValues = [];
  String _orderBy = "";
  int? _limit;
  int? _offset;

  QueryBuilder select(List<String> fields) {
    _selectFields = fields;
    return this;
  }

  QueryBuilder where(String field, String value) {
    _whereFields.add(field);
    _whereValues.add(value);
    return this;
  }

  QueryBuilder orderBy(String column, {bool descending = false}) {
    _orderBy = "ORDER BY $column ${descending ? "DESC" : "ASC"}";
    return this;
  }

  QueryBuilder limit(int limit, [int? offset]) {
    _limit = limit;
    _offset = offset;
    return this;
  }

  QueryBuilder findByIdQuery(int id) {
    _whereFields.add("id = ?");
    _whereValues.add(id);
    return this;
  }

  void build() {
    String selectedFields =
        _selectFields.isNotEmpty ? _selectFields.join(", ") : "*";
    String whereFields =
        _whereFields.isNotEmpty ? "WHERE ${_whereFields.join(" AND ")}" : "";
    String limitClause = _limit != null ? "LIMIT $_limit" : "";
    String offsetClause = _offset != null ? "OFFSET $_offset" : "";
    _query =
        "SELECT $selectedFields FROM $_table $whereFields $_orderBy $limitClause $offsetClause;";

    _resetValues();
  }

  List<dynamic> get values => _whereValues;
  String get query => _query;

  void _resetValues() {
    _whereFields.clear();
    _whereValues.clear();
    _orderBy = "";
    _limit = null;
    _offset = null;
  }
}
