/// Enum representing different date and time formatting styles.
///
/// This enum can be used to specify the desired format when handling
/// or displaying `DateTime` values.
///
/// ### Formats:
/// - `DATE` - Outputs only the date in `YYYY-MM-DD` format.
/// - `TIME` - Outputs only the time in `HH:MM:SS` format.
/// - `DATETIME` - Outputs full date and time in `YYYY-MM-DD HH:MM:SS` format.
///
/// You can pair this enum with your own date formatting utility for
/// consistent and readable output.
enum DateTimeFormat {
  /// Format only the date portion in `YYYY-MM-DD` format.
  DATE,

  /// Format only the time portion in `HH:MM:SS` format.
  TIME,

  /// Format full date and time in `YYYY-MM-DD HH:MM:SS` format.
  DATETIME,
}
