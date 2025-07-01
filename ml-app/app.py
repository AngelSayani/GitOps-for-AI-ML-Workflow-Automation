from flask import Flask, jsonify, request
import numpy as np
from datetime import datetime

app = Flask(__name__)

# Simulated model storage
models = {
    "sentiment-analyzer": {
        "version": "v1.0",
        "accuracy": 0.94,
        "description": "Sentiment analysis model for customer reviews"
    }
}

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json() if request.is_json else {}
    text = data.get('text', 'sample text')
    
    # Simulated prediction
    prediction = np.random.rand()
    sentiment = "positive" if prediction > 0.5 else "negative"
    
    return jsonify({
        'model': 'sentiment-analyzer',
        'version': 'v1.0',
        'prediction': float(prediction),
        'sentiment': sentiment,
        'text': text,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'models_loaded': list(models.keys()),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/metrics', methods=['GET'])
def metrics():
    return jsonify({
        'total_models': len(models),
        'model_details': models,
        'uptime': 'running'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
