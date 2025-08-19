# --- Flutter Core ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- Firebase & Google Play Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.gms.internal.**

# --- Firestore / Protobuf ---
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# --- Firebase Storage: Tika tauchte in deinem Crash-Stack auf ---
-keep class org.apache.tika.** { *; }
-dontwarn org.apache.tika.**

# --- AndroidX Window (optional) ---
-keep class androidx.window.** { *; }
-dontwarn androidx.window.**
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**

# --- Play Core (Deferred Components / SplitInstall) ---
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn com.google.android.play.core.**

# --- Networking/JSON (häufig transitiv) ---
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# --- Glide (falls durch Plugins eingebracht) ---
-keep class com.bumptech.glide.** { *; }
-keep class com.bumptech.glide.GeneratedAppGlideModuleImpl { *; }
-keep class com.bumptech.glide.load.resource.bitmap.ImageHeaderParser { *; }
-dontwarn com.bumptech.glide.**

# --- Enums (Absicherung gegen R8-Reflexionsprobleme; fix für deinen Crash) ---
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Annotationen/Signaturen ---
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# --- Sonstiges ---
-keep class sun.misc.Unsafe { *; }
