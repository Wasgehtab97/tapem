class Branding {
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;

  Branding({this.logoUrl, this.primaryColor, this.secondaryColor});

  factory Branding.fromMap(Map<String, dynamic> map) => Branding(
    logoUrl: map['logoUrl'] as String?,
    primaryColor: map['primaryColor'] as String?,
    secondaryColor: map['secondaryColor'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (primaryColor != null) 'primaryColor': primaryColor,
    if (secondaryColor != null) 'secondaryColor': secondaryColor,
  };
}
