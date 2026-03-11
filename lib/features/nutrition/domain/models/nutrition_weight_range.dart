enum NutritionWeightRange { week, month, quarter, year }

extension NutritionWeightRangeX on NutritionWeightRange {
  int get defaultBucketCount {
    switch (this) {
      case NutritionWeightRange.week:
        return 12;
      case NutritionWeightRange.month:
        return 12;
      case NutritionWeightRange.quarter:
        return 8;
      case NutritionWeightRange.year:
        return 5;
    }
  }
}
