class Branding {
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? gradientStart;
  final String? gradientEnd;

  Branding({
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.gradientStart,
    this.gradientEnd,
  });

  factory Branding.fromMap(Map<String, dynamic> map) => Branding(
        logoUrl: map['logoUrl'] as String?,
        primaryColor:
            (map['primary'] ?? map['primaryColor']) as String?,
        secondaryColor:
            (map['secondary'] ?? map['secondaryColor']) as String?,
        gradientStart: map['gradientStart'] as String?,
        gradientEnd: map['gradientEnd'] as String?,
      );

  Map<String, dynamic> toMap() => {
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (primaryColor != null) 'primaryColor': primaryColor,
    if (secondaryColor != null) 'secondaryColor': secondaryColor,
    if (gradientStart != null) 'gradientStart': gradientStart,
    if (gradientEnd != null) 'gradientEnd': gradientEnd,
  };
}
