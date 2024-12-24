from flask import Flask, request, jsonify
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import img_to_array, load_img
import numpy as np
import io

app = Flask(__name__)

# Load the trained model
MODEL_PATH = 'resnet50_skin_disease_model.keras'
try:
    model = load_model(MODEL_PATH)
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")

# Load class indices
CLASS_INDICES_PATH = 'class_indices.npy'
try:
    class_indices = np.load(CLASS_INDICES_PATH, allow_pickle=True).item()
    index_to_class = {v: k.strip() for k, v in class_indices.items()}  # Map indices to class names
    print("Class indices loaded successfully!")
except Exception as e:
    print(f"Error loading class indices: {e}")
    class_indices = {}
    index_to_class = {}

# Define first aid instructions with matching labels
first_aid_instructions = {
    "FU-ringworm": ["Clean the Area", "Apply Antifungal Cream", "Keep It Dry", "Avoid Scratching", "Maintain Hygiene"],
    "BA-cellulitis": ["Clean the Area", "Apply Antibiotic Ointment", "Elevate the Affected Limb", "Seek Medical Attention"],
    "BA-impetigo": ["Clean the sores", "Apply Antibiotic Ointment", "Cover the sores", "Avoid scratching", "Wash hands frequently"],
    "FU-athlete-foot": ["Keep feet clean and dry", "Apply antifungal cream", "Wear breathable socks", "Change shoes regularly"],
    "FU-nail-fungus": ["Trim nails", "Apply antifungal cream", "Keep feet dry", "Wear breathable shoes"],
    "PA-cutaneous-larva-migrans": ["Apply anti-parasitic cream", "Avoid scratching", "Seek medical attention"],
    "VI-chickenpox": ["Keep skin clean", "Apply calamine lotion", "Trim nails", "Use acetaminophen", "Avoid close contact"],
    "VI-shingles": ["Apply cool compress", "Use pain relief medications", "Wear loose clothing"]
}

@app.route('/predict', methods=['POST'])
def predict_image():
    """
    Endpoint to predict the skin disease based on an uploaded image.
    """
    try:
        # Check if an image file is included in the request
        if 'image' not in request.files:
            return jsonify({"error": "No image file uploaded."}), 400

        # Retrieve and process the uploaded image
        file = request.files['image']
        img = load_img(io.BytesIO(file.read()), target_size=(224, 224))  # Convert FileStorage to BytesIO
        img_array = img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0) / 255.0  # Normalize the image

        # Perform prediction
        predictions = model.predict(img_array)
        predicted_class_index = np.argmax(predictions)

        # Retrieve predicted class and associated first aid instructions
        predicted_class = index_to_class.get(predicted_class_index, "Unknown Disease").strip()
        instructions = first_aid_instructions.get(predicted_class, ["No instructions available."])

        return jsonify({
            "disease": predicted_class,
            "instructions": instructions
        })

    except Exception as e:
        # Handle exceptions gracefully
        print(f"Error during prediction: {e}")
        return jsonify({"error": "An error occurred during prediction.", "details": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
