import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset

def generate_dummy_data():
    # Simulamos un problema de regresión lineal simple: y = 2x + 1
    X = torch.randn(100, 1)
    y = 2 * X + 1 + torch.randn(100, 1) * 0.1
    return DataLoader(TensorDataset(X, y), batch_size=16, shuffle=True)

class LinearRegressionModel(nn.Module):
    def __init__(self):
        super(LinearRegressionModel, self).__init__()
        self.linear = nn.Linear(1, 1)  # Una entrada, una salida

    def forward(self, x):
        return self.linear(x)

def train():
    print("🧠 Inicializando entrenamiento con PyTorch...")
    dataloader = generate_dummy_data()
    model = LinearRegressionModel()
    
    criterion = nn.MSELoss()
    optimizer = optim.SGD(model.parameters(), lr=0.01)
    
    epochs = 50
    for epoch in range(epochs):
        for batch_x, batch_y in dataloader:
            # 1. Forward pass
            predictions = model(batch_x)
            loss = criterion(predictions, batch_y)
            
            # 2. Backward pass y optimización
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            
        if (epoch + 1) % 10 == 0:
            print(f"📈 Epoch [{epoch+1}/{epochs}], Loss: {loss.item():.4f}")
            
    print("✅ Entrenamiento completado con éxito.")
    # Guardamos los pesos del modelo entrenado (Best Practice)
    torch.save(model.state_dict(), "src/model_weights.pth")
    print("💾 Modelo guardado en src/model_weights.pth")

if __name__ == "__main__":
    train()