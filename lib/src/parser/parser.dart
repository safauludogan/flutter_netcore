/// An abstract class defining a generic parser interface.
/// 
/// The `Parser` class is parameterized by a type `T`, which represents
abstract class Parser<T> {
  /// the type of the parsed output.
  T parse(dynamic data);
}
