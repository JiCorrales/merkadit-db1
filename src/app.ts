import express from "express";

import morgan from "morgan";  // HTTP request logger middleware

import dotenv from "dotenv";


import saleRoutes from "./routes/saleRoutes";
import commerceRoutes from "./routes/commerceRoutes";

dotenv.config();

const port = Number(process.env.PORT ?? 8080);
const app = express();

/* `app.use(morgan("dev"));` is setting up the Morgan middleware in the Express application. Morgan is
a popular HTTP request logger middleware for Node.js that logs information about incoming HTTP
requests to the console. */
app.use(morgan("dev"))

app.use(express.json())


// Basic route for testing server availability
app.get("/", (_req, res) => {
    res.send("Hello from API")
})
// Routes
app.use("/sales", saleRoutes)
app.use("/commerce", commerceRoutes)

app.listen(port, () => {
    console.log("Server running on port http://localhost:" + port)
})

export default app
