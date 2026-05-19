import os
import torch
from src.train import LinearRegressionModel

def run_inference():
    print("🔮 Inicializando Motor de Inferencia GenPy AI...")
    
    # 1. Instanciar la arquitectura de la red neuronal
    model = LinearRegressionModel()
    weights_path = "src/model_weights.pth"
    
    # 2. Verificar defensivamente si el modelo ya fue entrenado
    if not os.path.exists(weights_path):
        print("⚠️  No se encontraron pesos pre-entrenados en 'src/model_weights.pth'.")
        print("🚀 Ejecutando el ciclo de entrenamiento previo automáticamente...")
        from src.train import train
        train()
    
    # 3. Cargar los pesos entrenados en el modelo
    model.load_state_dict(torch.load(weights_path))
    model.eval()  # Cambiar el modelo a modo de evaluación (Best Practice)
    
    print("✅ Pesos del modelo cargados correctamente.")
    print("📝 Realizando prueba de predicción matemática para la ecuación y = 2x + 1")
    
    # 4. Simular una entrada de datos (Ejemplo: x = 5.0)
    test_input = float(input("🔢 Ingresa un valor numérico para X: "))
    input_tensor = torch.tensor([[test_input]], dtype=torch.float32)
    
    # Desactivar el cálculo de gradientes para ahorrar memoria RAM durante la predicción
    with torch.no_grad():
        prediction = model(input_tensor)
    
    predicted_value = prediction.item()
    expected_value = 2 * test_input + 1
    
    print(f"\n🎯 VALOR PREDICHO POR LA IA (y): {predicted_value:.4f}")
    print(f"📊 VALOR REAL TEÓRICO (2x + 1):  {expected_value:.4f}")
    print(f"📉 Margen de error absoluto:       {abs(predicted_value - expected_value):.4f}")

if __name__ == "__main__":
    run_inference()