import express from "express";

import morgan from "morgan";  // HTTP request logger middleware

import dotenv from "dotenv";


import saleRoutes from "./routes/saleRoutes";
import commerceRoutes from "./routes/commerceRoutes";

dotenv.config();

const port = Number(process.env.PORT ?? 8080);
const app = express();

app.use(morgan("dev")); // Log HTTP requests to the console
app.use(express.json());

app.get("/", (_req, res) => {
    res.send("Hello from API");
});

app.use("/sales", saleRoutes);
app.use("/commerce", commerceRoutes);

app.listen(port, () => {
    console.log("Server running on port http://localhost:" + port);
});

export default app;
