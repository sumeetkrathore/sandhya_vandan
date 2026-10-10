# ProGuard rules for Gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.** { *; }
-keep public class * implements java.lang.reflect.Type

# Prevent R8 from stripping generic signatures
-keepattributes Signature,InnerClasses,EnclosingMethod

# Preserve Play Core models for in_app_update and in_app_review Gson deserialization
# (R8 strips these models, causing TypeToken.getSuperclassTypeParameter to throw RuntimeException)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.common.annotation.NoNullnessRewrite

# Keep flutter_local_notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep AudioService classes
-keep class com.ryanheise.audioservice.** { *; }

# Keep Firebase Messaging classes
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
