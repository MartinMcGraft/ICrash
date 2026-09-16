# google_mlkit_text_recognition's base module references optional
# per-script recognizer classes (Chinese/Devanagari/Japanese/Korean) that
# this app never depends on and never calls -- only the legacy lib/teste/
# prototype screens use text recognition at all, and only the default Latin
# recognizer. R8 flags them as "missing" during release minification
# (discovered when this app's first-ever `flutter build apk --release` was
# attempted); these are exactly the lines Android Gradle Plugin's own error
# message recommended (build/app/outputs/mapping/release/missing_rules.txt).
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
