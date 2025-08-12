# Training Day Rollover

This document outlines the concept of a training day rollover. Workouts that
start before the configured rollover hour belong to the previous day. The
current implementation defaults to **03:00** local time.

Each session stores the client's time zone (`tz`) so that server side processes
can aggregate statistics correctly.
