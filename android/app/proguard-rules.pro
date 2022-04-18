# Express Android SDK needs to use reflection to find some classes
# So we need to turn off the confusion for some classes
# To prevent the ZEGO SDK public class names from being obfuscated

-keep class **.zego.**  { *; }
