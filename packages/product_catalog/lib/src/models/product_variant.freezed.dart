// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductVariant {

 String get id; String get sku; String? get barcode; Map<String, String> get attributes;// e.g. {'Color': 'Red', 'Size': 'XL'}
 double get price; double? get discountPrice; int get stock; List<String> get images; String? get videoUrl; double get weight; Map<String, double> get dimensions;// length, width, height
 String get status; bool get trackInventory;
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<ProductVariant> get copyWith => _$ProductVariantCopyWithImpl<ProductVariant>(this as ProductVariant, _$identity);

  /// Serializes this ProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&const DeepCollectionEquality().equals(other.attributes, attributes)&&(identical(other.price, price) || other.price == price)&&(identical(other.discountPrice, discountPrice) || other.discountPrice == discountPrice)&&(identical(other.stock, stock) || other.stock == stock)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other.dimensions, dimensions)&&(identical(other.status, status) || other.status == status)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,const DeepCollectionEquality().hash(attributes),price,discountPrice,stock,const DeepCollectionEquality().hash(images),videoUrl,weight,const DeepCollectionEquality().hash(dimensions),status,trackInventory);

@override
String toString() {
  return 'ProductVariant(id: $id, sku: $sku, barcode: $barcode, attributes: $attributes, price: $price, discountPrice: $discountPrice, stock: $stock, images: $images, videoUrl: $videoUrl, weight: $weight, dimensions: $dimensions, status: $status, trackInventory: $trackInventory)';
}


}

/// @nodoc
abstract mixin class $ProductVariantCopyWith<$Res>  {
  factory $ProductVariantCopyWith(ProductVariant value, $Res Function(ProductVariant) _then) = _$ProductVariantCopyWithImpl;
@useResult
$Res call({
 String id, String sku, String? barcode, Map<String, String> attributes, double price, double? discountPrice, int stock, List<String> images, String? videoUrl, double weight, Map<String, double> dimensions, String status, bool trackInventory
});




}
/// @nodoc
class _$ProductVariantCopyWithImpl<$Res>
    implements $ProductVariantCopyWith<$Res> {
  _$ProductVariantCopyWithImpl(this._self, this._then);

  final ProductVariant _self;
  final $Res Function(ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? attributes = null,Object? price = null,Object? discountPrice = freezed,Object? stock = null,Object? images = null,Object? videoUrl = freezed,Object? weight = null,Object? dimensions = null,Object? status = null,Object? trackInventory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,discountPrice: freezed == discountPrice ? _self.discountPrice : discountPrice // ignore: cast_nullable_to_non_nullable
as double?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,dimensions: null == dimensions ? _self.dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as Map<String, double>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductVariant].
extension ProductVariantPatterns on ProductVariant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductVariant value)  $default,){
final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductVariant value)?  $default,){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  Map<String, String> attributes,  double price,  double? discountPrice,  int stock,  List<String> images,  String? videoUrl,  double weight,  Map<String, double> dimensions,  String status,  bool trackInventory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.attributes,_that.price,_that.discountPrice,_that.stock,_that.images,_that.videoUrl,_that.weight,_that.dimensions,_that.status,_that.trackInventory);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sku,  String? barcode,  Map<String, String> attributes,  double price,  double? discountPrice,  int stock,  List<String> images,  String? videoUrl,  double weight,  Map<String, double> dimensions,  String status,  bool trackInventory)  $default,) {final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that.id,_that.sku,_that.barcode,_that.attributes,_that.price,_that.discountPrice,_that.stock,_that.images,_that.videoUrl,_that.weight,_that.dimensions,_that.status,_that.trackInventory);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sku,  String? barcode,  Map<String, String> attributes,  double price,  double? discountPrice,  int stock,  List<String> images,  String? videoUrl,  double weight,  Map<String, double> dimensions,  String status,  bool trackInventory)?  $default,) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.sku,_that.barcode,_that.attributes,_that.price,_that.discountPrice,_that.stock,_that.images,_that.videoUrl,_that.weight,_that.dimensions,_that.status,_that.trackInventory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductVariant implements ProductVariant {
  const _ProductVariant({required this.id, required this.sku, this.barcode, final  Map<String, String> attributes = const {}, required this.price, this.discountPrice, this.stock = 0, final  List<String> images = const [], this.videoUrl, this.weight = 0.0, final  Map<String, double> dimensions = const {}, this.status = 'active', this.trackInventory = true}): _attributes = attributes,_images = images,_dimensions = dimensions;
  factory _ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

@override final  String id;
@override final  String sku;
@override final  String? barcode;
 final  Map<String, String> _attributes;
@override@JsonKey() Map<String, String> get attributes {
  if (_attributes is EqualUnmodifiableMapView) return _attributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attributes);
}

// e.g. {'Color': 'Red', 'Size': 'XL'}
@override final  double price;
@override final  double? discountPrice;
@override@JsonKey() final  int stock;
 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String? videoUrl;
@override@JsonKey() final  double weight;
 final  Map<String, double> _dimensions;
@override@JsonKey() Map<String, double> get dimensions {
  if (_dimensions is EqualUnmodifiableMapView) return _dimensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dimensions);
}

// length, width, height
@override@JsonKey() final  String status;
@override@JsonKey() final  bool trackInventory;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductVariantCopyWith<_ProductVariant> get copyWith => __$ProductVariantCopyWithImpl<_ProductVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&const DeepCollectionEquality().equals(other._attributes, _attributes)&&(identical(other.price, price) || other.price == price)&&(identical(other.discountPrice, discountPrice) || other.discountPrice == discountPrice)&&(identical(other.stock, stock) || other.stock == stock)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.weight, weight) || other.weight == weight)&&const DeepCollectionEquality().equals(other._dimensions, _dimensions)&&(identical(other.status, status) || other.status == status)&&(identical(other.trackInventory, trackInventory) || other.trackInventory == trackInventory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sku,barcode,const DeepCollectionEquality().hash(_attributes),price,discountPrice,stock,const DeepCollectionEquality().hash(_images),videoUrl,weight,const DeepCollectionEquality().hash(_dimensions),status,trackInventory);

@override
String toString() {
  return 'ProductVariant(id: $id, sku: $sku, barcode: $barcode, attributes: $attributes, price: $price, discountPrice: $discountPrice, stock: $stock, images: $images, videoUrl: $videoUrl, weight: $weight, dimensions: $dimensions, status: $status, trackInventory: $trackInventory)';
}


}

/// @nodoc
abstract mixin class _$ProductVariantCopyWith<$Res> implements $ProductVariantCopyWith<$Res> {
  factory _$ProductVariantCopyWith(_ProductVariant value, $Res Function(_ProductVariant) _then) = __$ProductVariantCopyWithImpl;
@override @useResult
$Res call({
 String id, String sku, String? barcode, Map<String, String> attributes, double price, double? discountPrice, int stock, List<String> images, String? videoUrl, double weight, Map<String, double> dimensions, String status, bool trackInventory
});




}
/// @nodoc
class __$ProductVariantCopyWithImpl<$Res>
    implements _$ProductVariantCopyWith<$Res> {
  __$ProductVariantCopyWithImpl(this._self, this._then);

  final _ProductVariant _self;
  final $Res Function(_ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sku = null,Object? barcode = freezed,Object? attributes = null,Object? price = null,Object? discountPrice = freezed,Object? stock = null,Object? images = null,Object? videoUrl = freezed,Object? weight = null,Object? dimensions = null,Object? status = null,Object? trackInventory = null,}) {
  return _then(_ProductVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,attributes: null == attributes ? _self._attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,discountPrice: freezed == discountPrice ? _self.discountPrice : discountPrice // ignore: cast_nullable_to_non_nullable
as double?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,dimensions: null == dimensions ? _self._dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as Map<String, double>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,trackInventory: null == trackInventory ? _self.trackInventory : trackInventory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
