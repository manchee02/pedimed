from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import json

app = Flask(__name__)

# Define the file paths
model_path = r'C:\src\pedimed\lib\algo\svm_model.pkl'
scaler_path = r'C:\src\pedimed\lib\algo\scaler.pkl'
category_labels_path = r'C:\src\pedimed\lib\data\category_label.csv'
feature_names_path = r'C:\src\pedimed\lib\algo\feature_names.json'
unit_label_path = r'C:\src\pedimed\lib\data\unit_label.csv'

# Load the trained SVM model and scaler
model = joblib.load(model_path)
scaler = joblib.load(scaler_path)

# Load the category labels
category_labels = pd.read_csv(category_labels_path)
category_mapping = dict(zip(category_labels['Category_Label'], category_labels['Category']))

# Load feature names from JSON
with open(feature_names_path, 'r') as f:
    feature_names = json.load(f)

# Load unit label mappings
unit_label = pd.read_csv(unit_label_path)
unit_mapping = dict(zip(unit_label['Dosage_Unit'], unit_label['Dosage_Unit_Label']))

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    
    # Map Dosage_Unit to Dosage_Unit_Label in the input data
    if 'Dosage_Unit' in data:
        data['Dosage_Unit_Label'] = unit_mapping[data['Dosage_Unit']]
        del data['Dosage_Unit']

    # Ensure all necessary columns are included in the input data
    sample_df = pd.DataFrame([data])
    sample_df = sample_df.reindex(columns=feature_names, fill_value=0)

    # Scale the input data
    sample_df_scaled = scaler.transform(sample_df)

    # Predict category and confidence
    prediction = model.predict(sample_df_scaled)
    confidence_scores = model.predict_proba(sample_df_scaled)

    # Get confidence for the predicted class
    predicted_class_index = int(prediction[0])
    confidence_for_predicted_class = confidence_scores[0][predicted_class_index] * 100  # Convert to percentage

    # Map the predicted class index to the category name
    predicted_category = category_mapping[predicted_class_index]

    response = {
        'category': predicted_category,
        'confidence': float("{:.2f}".format(confidence_for_predicted_class))  # Simplify to 2 decimal places
    }
    
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
