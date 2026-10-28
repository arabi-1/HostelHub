# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing Client
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Core Library Desugaring & Java 8+ APIs
-keep class j$.** { *; }
-dontwarn java.lang.invoke.**

# Flutter deferred components & Play Core warnings
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
