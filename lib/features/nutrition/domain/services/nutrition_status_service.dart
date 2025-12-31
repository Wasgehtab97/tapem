class NutritionStatusService {
  String statusFor({required int totalKcal, required int targetKcal}) {
    if (targetKcal <= 0) return 'under';
    if (totalKcal == targetKcal) return 'on';
    return totalKcal < targetKcal ? 'under' : 'over';
  }
}
