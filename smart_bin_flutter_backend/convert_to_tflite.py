import tensorflow as tf

model = tf.keras.models.load_model("models/trash_classifier.h5")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

open("exports/model.tflite","wb").write(tflite_model)

print("TFLite export complete")