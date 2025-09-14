/// Utilities for validating cardio interval durations.
int sumIntervals(Iterable<int> durations) =>
    durations.fold<int>(0, (prev, e) => prev + e);

bool intervalsMatchTotal(Iterable<int> durations, int total) =>
    sumIntervals(durations) == total;
