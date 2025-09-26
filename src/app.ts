import express from "express";
import morgan from "morgan";

const port = 8080;
const app = express();
app.use(morgan("dev"));
app.use(express.json());

app.get("/", (_req, res) => {
    res.send("Hello from API");
});

app.listen(port, () => {
    console.log(`Server running on port http://localhost:${port}`);
} );

export default app;
