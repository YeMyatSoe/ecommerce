######################
# Play Core
######################
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

######################
# Stripe Push Provisioning
######################
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

######################
# Flutter Deferred Components
######################
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
