# Reglas de R8/ProGuard para los builds de release.

# ML Kit (OCR de comprobantes, F-70): solo se usa el reconocedor latino. El
# plugin referencia los reconocedores opcionales de otros alfabetos, que no
# están incluidos; se ignoran para que R8 no falle.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
