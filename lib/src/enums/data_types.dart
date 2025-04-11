/// Enum representing supported primitive data types.
///
/// This enum is commonly used in validation, serialization, or
/// dynamic schema systems to identify and handle data types.
///
/// ### Variants:
/// - `STRING`: Represents text or character sequences.
/// - `NUMBER`: Represents numeric values (integers or doubles).
/// - `BOOLEAN`: Represents true/false values.
enum DataTypes {
  /// Represents a string value, such as "hello".
  STRING,

  /// Represents a numeric value, such as 42 or 3.14.
  NUMBER,

  /// Represents a boolean value, either true or false.
  BOOLEAN,

  /// Represents a object value, sach as {"name" : "Sirius"}
  MAP,

  /// Represents a list value, sach as [2, 3, 4, 6]
  LIST
}
