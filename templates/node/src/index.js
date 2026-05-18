// {{PROJECT_NAME}} — punto de entrada

const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Hello from {{PROJECT_NAME}}" });
});

app.listen(PORT, () => {
  console.log(`{{PROJECT_NAME}} running on port ${PORT}`);
});